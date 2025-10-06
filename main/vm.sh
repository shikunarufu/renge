#!/bin/bash
#
# Shiku's Virtualization Installation Script

# This script automates the installation process of Virtualization.

# This script assumes you have already booted
# and logged in into the new system with the user account.

# This script assumes a working internet connection is available.

# Uncomment the line below to show command outputs.
# set -x

#######################################
# Preparation
#######################################

# Check virtualization support
virt="$(lscpu | grep --extended-regexp 'Virtualization')"
if [[ "${virt}" == "Virtualization:                          AMD-V" ]]; then
  printf "%s\n" "System is booted with Virtualization enabled"
elif [[ "${virt}" == "Virtualization:                          VT-x" ]]; then
  printf "%s\n" "System is booted with Virtualization enabled"
else
  printf "%s\n" "System may be booted with Virtualization disabled"
  printf "%s\n" "Refer to your BIOS's manual"
  exit
fi

# Check if kernel includes KVM modules
zgrep CONFIG_KVM /proc/config.gz

# Verify the boot mode
boot="$(cat /sys/firmware/efi/fw_platform_size)"
if [[ "${boot}" == "64" ]]; then
  printf "%s\n" "System is booted in UEFI mode and has a 64-bit x64 UEFI"
elif [[ "${boot}" == "32" ]]; then
  printf "%s\n" "System is booted in UEFI mode and has a 32-bit IA32 UEFI"
else
  printf "%s\n" "System may be booted in BIOS (or CSM) mode"
  printf "%s\n" "Refer to your motherboard's manual"
  exit
fi

# Verify SVM mode
svm="$(lscpu | grep --extended-regexp --word-regexp --only-matching 'svm')"
if [[ "${svm}" == "svm" ]]; then
  printf "%s\n" "System is booted with SVM mode enabled"
else
  printf "%s\n" "System may be booted with SVM mode disabled"
  printf "%s\n" "Refer to your BIOS's manual"
  exit
fi

# Verify NX mode
nx="$(sudo dmesg | grep --extended-regexp 'Execute Disable')"
if [[ "${nx}" == "[    0.000000] NX (Execute Disable) protection: active" ]]; then
  printf "%s\n" "System is booted with NX mode enabled"
else
  printf "%s\n" "System may be booted with NX mode disabled"
  printf "%s\n" "Refer to your BIOS's manual"
  exit
fi

# Verify IOMMU
iommu="$(sudo dmesg | grep --extended-regexp 'IOMMU' | grep --extended-regexp --max-count 1 'IOMMU')"
if [[ "${iommu}" == "[    0.000000] DMAR: IOMMU enabled" ]]; then
  printf "%s\n" "System is booted with IOMMU enabled"
elif [[ "${iommu}" == "[    0.000000] Warning: PCIe ACS overrides enabled; This may allow non-IOMMU protected peer-to-peer DMA" ]]; then
  printf "%s\n" "System is booted with IOMMU enabled and has ACS override patch"
else
  printf "%s\n" "System may be booted with IOMMU disabled"
  printf "%s\n" "Refer to your BIOS's manual"
  exit
fi

# Editing GRUB with ACS override patch
# sudo sed --in-place "s/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet video=efifb:off pcie_acs_override=downstream,multifunction\"/g" /etc/default/grub
# sudo grub-mkconfig -o /boot/grub/grub.cfg
# reboot

# IOMMU Groups
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
  echo "IOMMU Group ${g##*/}:"
  for d in $g/devices/*; do
    echo -e "\t$(lspci -nns ${d##*/})"
  done;
done;

# Installation of virtualization packages
yes y | sudo pacman -S --needed qemu-full libvirt virt-install virt-manager virt-viewer edk2-ovmf swtpm qemu-img guestfs-tools libosinfo vde2 ebtables iptables-nft nftables dnsmasq bridge-utils
yay -S --answerclean All --answerdiff None --noconfirm tuned

# Configuration of libvirt
sudo sed --in-place 's/#unix_sock_group = \"libvirt\"/unix_sock_group = \"libvirt\"/g' /etc/libvirt/libvirtd.conf
sudo sed --in-place 's/#unix_sock_rw_perms = \"0770\"/unix_sock_rw_perms = \"0770\"/g' /etc/libvirt/libvirtd.conf
sudo sed --in-place 's/#log_filters=\"1:qemu 1:libvirt 4:object 4:json 4:event 1:util\"/log_filters=\"3:qemu 1:libvirt\"/g' /etc/libvirt/libvirtd.conf
sudo sed --in-place 's|#log_outputs=\"3:syslog:libvirtd\"|log_outputs=\"2:file:/var/log/libvirt/libvirtd.log\"|g' /etc/libvirt/libvirtd.conf
sudo usermod --append --groups kvm,libvirt "${username}"
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo sed --in-place "s/#user = \"libvirt-qemu\"/user = \"$username\"/g" /etc/libvirt/qemu.conf
sudo sed --in-place "s/#group = \"libvirt-qemu\"/group = \"$username\"/g" /etc/libvirt/qemu.conf
sudo systemctl restart libvirtd
# sudo virsh net-autostart default

#######################################
# Virtual Machine Setup
#######################################

# Overview
# Chipset: Q35
# Firmware: UEFI x86_64: /usr/share/edk2/x64/OVMF_CODE.4m.fd

# CPU
# Sockets: 1
# Cores: 6
# Threads: 2

# Memory
# Allocation: 13312 MB

# VirtIO Disk
# Cache mode: writeback

# PCI
# 28:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 44 [Radeon RX 9060 XT] [1002:7590] (rev c0)
# 28:00.1 Audio device [0403]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 48 HDMI/DP Audio Controller [1002:ab40]
# 03:00.0 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] 400 Series Chipset USB 3.1 xHCI Compliant Host Controller [1022:43d5] (rev 01)
# 2a:00.3 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Matisse USB 3.0 Host Controller [1022:149c]
# 2a:00.4 Audio device [0403]: Advanced Micro Devices, Inc. [AMD] Starship/Matisse HD Audio Controller [1022:1487]
# 22:00.0 Ethernet controller [0200]: Realtek Semiconductor Co., Ltd. RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet Controller [10ec:8168] (rev 15)
# 2a:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Starship/Matisse Reserved SPP [1022:1485]

# Script
git clone https://gitlab.com/akshaycodes/vfio-script.git
cd vfio-script
sudo bash vfio_script_install.sh

# XML File
# ...
# <features>
#   ...
#   <hyperv>
#     ...
#     <vendor_id state='on' value='AMD'/>
#   </hyperv>
#   ...
#   <kvm>
#     <hidden state='on'/>
#   </kvm>
# </features>
# <cpu>
#   ...
#   <feature policy='require' name='topoext'/>
# </cpu>
# ...
