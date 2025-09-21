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

# yes y | sudo pacman -S virt-manager qemu-full vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf
# sudo sed --in-place 's/#unix_sock_group = \"libvirt\"/unix_sock_group = \"libvirt\"/g' /etc/libvirt/libvirtd.conf
# sudo sed --in-place 's/#unix_sock_rw_perms = \"0770\"/unix_sock_rw_perms = \"0770\"/g' /etc/libvirt/libvirtd.conf
# sudo sed --in-place 's/#log_filters=\"1:qemu 1:libvirt 4:object 4:json 4:event 1:util\"/log_filters=\"3:qemu 1:libvirt\"/g' /etc/libvirt/libvirtd.conf
# sudo sed --in-place 's/#log_outputs=\"3:syslog:libvirtd\"/log_outputs=\"2:file:/var/log/libvirt/libvirtd.log\"/g' /etc/libvirt/libvirtd.conf
# sudo usermod --append --groups kvm,libvirt "${username}"
# sudo systemctl enable libvirtd
# sudo systemctl start libvirtd
# sudo sed --in-place "s/#user = \"libvirt-qemu\"/user = \"$username\"/g" /etc/libvirt/qemu.conf
# sudo sed --in-place "s/#group = \"libvirt-qemu\"/group = \"$username\"/g" /etc/libvirt/qemu.conf
# sudo systemctl restart libvirtd
# sudo virsh net-autostart default
