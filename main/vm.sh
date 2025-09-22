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

# Verify the boot mode
bootmode="$(cat /sys/firmware/efi/fw_platform_size)"
if [[ "${bootmode}" == "64" ]]; then
  echo "System is booted in UEFI mode and has a 64-bit x64 UEFI"
elif [[ "${bootmode}" == "32" ]]; then
  echo "System is booted in UEFI mode and has a 32-bit IA32 UEFI"
else
  echo "System may be booted in BIOS (or CSM) mode"
  echo "Refer to your motherboard's manual"
  exit
fi

# Verify SVM mode
grep --extended-regexp --only-matching 'svm' /proc/cpuinfo

# Verify NX mode
sudo dmesg | grep 'Execute Disable'

# Verify IOMMU
ls /sys/class/iommu/

# Editing GRUB with ACS override patch
sudo sed --in-place "s/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet video=efifb:off pcie_acs_override=downstream,multifunction\"/g" /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
reboot

# IOMMU Groups
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
  echo "IOMMU Group ${g##*/}:"
  for d in $g/devices/*; do
    echo -e "\t$(lspci -nns ${d##*/})"
  done;
done;

# Installation of virtualization packages
yes y | sudo pacman -S virt-manager qemu-full vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf

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

# GPU
# 28:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 44 [Radeon RX 9060 XT] [1002:7590] (rev c0)
# 28:00.1 Audio device [0403]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 48 HDMI/DP Audio Controller [1002:ab40]

# USB Controller
# 03:00.0 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] 400 Series Chipset USB 3.1 xHCI Compliant Host Controller [1022:43d5] (rev 01)
# 2a:00.3 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Matisse USB 3.0 Host Controller [1022:149c]

# Audio Device
# 2a:00.4 Audio device [0403]: Advanced Micro Devices, Inc. [AMD] Starship/Matisse HD Audio Controller [1022:1487]

# Ethernet Controller
# 22:00.0 Ethernet controller [0200]: Realtek Semiconductor Co., Ltd. RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet Controller [10ec:8168] (rev 15)

# Other PCI Host Device
# 2a:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Starship/Matisse Reserved SPP [1022:1485]
# 2a:00.1 Encryption controller [1080]: Advanced Micro Devices, Inc. [AMD] Starship/Matisse Cryptographic Coprocessor PSPCPP [1022:1486]

# Script
git clone https://gitlab.com/akshaycodes/vfio-script.git && cd vfio-script && sudo bash vfio_script_install.sh

# XML File
<feature policy='require' name='topoext'/>
