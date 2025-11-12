#!/bin/bash

# Shiku's Post Arch Linux Installation Script

# This script automates the post-installation process of Arch Linux.

# This script assumes you have already booted
# and logged in into the new system with the user account.

# This script assumes a working internet connection is available.

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

#######################################
# Preparation
#######################################

# Configuration
username="Shiku"
user_passwd="narufu"

# Clear the terminal screen
clear

# Connect to the internet
if ! ping -c 1 archlinux.org; then
  printf "%s\n" "Failed to connect to the internet"
  rm --force --recursive /home/"${username}"/renge
  exit
fi

# Allow members of group wheel sudo access without a password
printf "%s\n%s" "${user_passwd}" "${user_passwd}" | sudo --stdin sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Create default directories
xdg-user-dirs-update

#######################################
# Installation
#######################################

# Yay
if ! sudo pacman -S --noconfirm --needed git base-devel; then
  printf "%s\n" "Failed to install Yay dependencies"
  rm --force --recursive /home/"${username}"/renge
  exit
fi
if ! git clone https://aur.archlinux.org/yay.git; then
  if ! git clone --branch yay --single-branch https://github.com/archlinux/aur.git yay; then
    printf "%s\n" "Failed to clone Yay repository"
    rm --force --recursive /home/"${username}"/renge
    rm --force --recursive /home/"${username}"/yay
    exit
  fi
fi
cd yay || exit
makepkg -si --noconfirm
yay --yay --gendb
yay -Syu --devel --answerupgrade None --noconfirm
yay --yay --devel --save

# Hyprland
# grep --extended-regexp --only-matching '^[^(#|[:space:])]*' /home/"${username}"/renge/pkgs/hyprland-pkglist.txt | sort --output=/home/"${username}"/renge/pkgs/hyprland-pkglist.txt --unique
# if ! yay -S --answerclean All --answerdiff None --noconfirm - < /home/"${username}"/renge/pkgs/hyprland-pkglist.txt; then
#   hyprland_pkglist="hyprland-pkglist.txt"
#   mkdir --parents /home/"${username}"/AUR
#   cd AUR || exit
#   while IFS= read -r hyprland_pkgs; do
#     if ! git clone --branch "${hyprland_pkgs}" --single-branch https://github.com/archlinux/aur.git "${hyprland_pkgs}"; then
#       break
#       printf "%s\n" "Failed to install (Hyprland) packages"
#       rm --force --recursive /home/"${username}"/renge
#       rm --force --recursive /home/"${username}"/yay
#       rm --force --recursive /home/"${username}"/AUR
#       exit
#     fi
#     cd "$hyprland_pkgs"
#     makepkg -si --noconfirm
#   done < /home/"${username}"/renge/pkgs/"${hyprland_pkglist}"
# fi
# if ! git clone --recursive https://github.com/hyprwm/Hyprland; then
#   printf "%s\n" "Failed to clone Hyprland repository"
#   rm --force --recursive /home/"${username}"/renge
#   rm --force --recursive /home/"${username}"/yay
#   rm --force --recursive /home/"${username}"/AUR
#   exit
# fi
# cd Hyprland || exit
# make all && sudo make install
# cp --recursive /home/"${username}"/renge/hypr /home/"${username}"/.config

# Pacman Packages
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' /home/"${username}"/renge/pkgs/post-pacman-pkglist.txt | sort --output=/home/"${username}"/renge/pkgs/post-pacman-pkglist.txt --unique
if ! sudo pacman -S --noconfirm --needed - < /home/"${username}"/renge/pkgs/post-pacman-pkglist.txt; then
  printf "%s\n" "Failed to install packages"
  rm --force --recursive /home/"${username}"/renge
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/AUR
  exit
fi

# Yay Packages
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' /home/"${username}"/renge/pkgs/post-yay-pkglist.txt | sort --output=/home/"${username}"/renge/pkgs/post-yay-pkglist.txt --unique
if ! yay -S --answerclean All --answerdiff None --noconfirm - < /home/"${username}"/renge/pkgs/post-yay-pkglist.txt; then
  printf "%s\n" "Failed to install (AUR) packages"
  rm --force --recursive /home/"${username}"/renge
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/AUR
  exit
fi

# LazyVim
mkdir --parents /home/"${username}"/.config/nvim
git clone https://github.com/LazyVim/starter /home/"${username}"/.config/nvim
rm --force --recursive /home/"${username}"/.config/nvim/.git

# Bin
mkdir --parents /home/"${username}"/.local/share/renge
cp --recursive /home/"${username}"/renge/bin /home/"${username}"/.local/share/renge

# Foot
cp --recursive /home/"${username}"/renge/foot /home/"${username}"/.config

# Fish
cp --recursive /home/"${username}"/renge/fish /home/"${username}"/.config

# Starship
cp --recursive /home/"${username}"/renge/starship/starship.toml /home/"${username}"/.config

# Universal Wayland Session Manager
cp --recursive /home/"${username}"/renge/uwsm /home/"${username}"/.config
cp --recursive /home/"${username}"/renge/environment.d /home/"${username}"/.config

# Greetd
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet exec uwsm start hyprland.desktop --remember"|g' /etc/greetd/config.toml
sudo systemctl enable greetd.service

# Mako
cp --recursive /home/"${username}"/renge/mako /home/"${username}"/.config

# Waybar
cp --recursive /home/"${username}"/renge/waybar /home/"${username}"/.config

# SWWW
mkdir --parents /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/renge/pictures/wallpapers/desktop.png /home/"${username}"/Pictures/Wallpapers
# swww img /home/"${username}"/Pictures/Wallpapers/desktop.png

# Rofi
cp --recursive /home/"${username}"/renge/rofi /home/"${username}"/.config

# Dolphin
xdg-mime default org.kde.dolphin.desktop inode/directory

# SwayOSD
cp --recursive /home/"${username}"/renge/swayosd /home/"${username}"/.config

# Imv
cp --recursive /home/"${username}"/renge/imv /home/"${username}"/.config

# Hyprshot
mkdir --parents /home/"${username}"/Pictures/Screenshots

# BTOP++
cp --recursive /home/"${username}"/renge/btop /home/"${username}"/.config

# Fastfetch
mkdir --parents /home/"${username}"/Pictures/Logo
cp /home/"${username}"/renge/pictures/logo/shiku.sixel /home/"${username}"/Pictures/Logo
cp --recursive /home/"${username}"/renge/fastfetch /home/"${username}"/.config

# SpotX
bash <(curl -sSL https://spotx-official.github.io/run.sh)

# Steam
printf "%s\n" "vm.max_map_count = 2147483642" | sudo tee --append /etc/sysctl.d/80-gamecompatibility.conf

# Fcitx5
cp --recursive /home/"${username}"/renge/fcitx5 /home/"${username}"/.config

# Theming
mkdir --parents /home/"${username}"/.config/Kvantum
tar --extract --directory ~/.config/Kvantum --file /home/"${username}"/renge/kvantum/whitesur.tar.xz
mkdir --parents /home/"${username}"/.icons
tar --extract --directory ~/.icons --file /home/"${username}"/renge/hyprcursor/sweet-cursors.tar.xz

# Plymouth
sudo sed --in-place "s/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck plymouth)/g" /etc/mkinitcpio.conf
sudo mkinitcpio -P
sudo plymouth-set-default-theme -R seal_3

# Linux GPU Control Application
if ! sudo systemctl enable --now lactd; then
  printf "%s\n" "Failed to enable lactd"
  rm --force --recursive /home/"${username}"/renge
  rm --force --recursive /home/"${username}"/yay
  rm --force --recursive /home/"${username}"/AUR
  exit
fi

# Desktop Entries
mkdir --parents /home/"${username}"/.local/share/applications
cp --recursive /usr/share/applications/ardour8.desktop ~/.local/share/applications/ardour8.desktop
cp --recursive /usr/share/applications/assistant.desktop ~/.local/share/applications/assistant.desktop
cp --recursive /usr/share/applications/avahi-discover.desktop ~/.local/share/applications/avahi-discover.desktop
cp --recursive /usr/share/applications/bssh.desktop ~/.local/share/applications/bssh.desktop
cp --recursive /usr/share/applications/btop.desktop ~/.local/share/applications/btop.desktop
cp --recursive /usr/share/applications/bvnc.desktop ~/.local/share/applications/bvnc.desktop
cp --recursive /usr/share/applications/calf.desktop ~/.local/share/applications/calf.desktop
cp --recursive /usr/share/applications/cmake-gui.desktop ~/.local/share/applications/cmake-gui.desktop
cp --recursive /usr/share/applications/codium.desktop ~/.local/share/applications/codium.desktop
cp --recursive /usr/share/applications/designer.desktop ~/.local/share/applications/designer.desktop
cp --recursive /usr/share/applications/fcitx5-configtool.desktop ~/.local/share/applications/fcitx5-configtool.desktop
cp --recursive /usr/share/applications/foot-server.desktop ~/.local/share/applications/foot-server.desktop
cp --recursive /usr/share/applications/footclient.desktop ~/.local/share/applications/footclient.desktop
cp --recursive /usr/share/applications/kbd-layout-viewer5.desktop ~/.local/share/applications/kbd-layout-viewer5.desktop
cp --recursive /usr/share/applications/linguist.desktop ~/.local/share/applications/linguist.desktop
cp --recursive /usr/share/applications/lstopo.desktop ~/.local/share/applications/lstopo.desktop
cp --recursive /usr/share/applications/org.fcitx.fcitx5-migrator.desktop ~/.local/share/applications/org.fcitx.fcitx5-migrator.desktop
cp --recursive /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.local/share/applications/org.fcitx.Fcitx5.desktop
cp --recursive /usr/share/applications/org.kde.filelight.desktop ~/.local/share/applications/org.kde.filelight.desktop
cp --recursive /usr/share/applications/org.kde.kdf.desktop ~/.local/share/applications/org.kde.kdf.desktop
cp --recursive /usr/share/applications/org.kde.kompare.desktop ~/.local/share/applications/org.kde.kompare.desktop
cp --recursive /usr/share/applications/org.kde.konsole.desktop ~/.local/share/applications/org.kde.konsole.desktop
cp --recursive /usr/share/applications/org.kde.kwikdisk.desktop ~/.local/share/applications/org.kde.kwikdisk.desktop
cp --recursive /usr/share/applications/phoronix-test-suite.desktop ~/.local/share/applications/phoronix-test-suite.desktop
cp --recursive /usr/share/applications/qdbusviewer.desktop ~/.local/share/applications/qdbusviewer.desktop
cp --recursive /usr/share/applications/qv4l2.desktop ~/.local/share/applications/qv4l2.desktop
cp --recursive /usr/share/applications/qvidcap.desktop ~/.local/share/applications/qvidcap.desktop
cp --recursive /usr/share/applications/rofi.desktop ~/.local/share/applications/rofi.desktop
cp --recursive /usr/share/applications/rofi-theme-selector.desktop ~/.local/share/applications/rofi-theme-selector.desktop
cp --recursive /usr/share/applications/uuctl.desktop ~/.local/share/applications/uuctl.desktop
cp --recursive /usr/share/applications/xgps.desktop ~/.local/share/applications/xgps.desktop
cp --recursive /usr/share/applications/xgpsspeed.desktop ~/.local/share/applications/xgpsspeed.desktop
sudo rm --force --recursive /usr/share/applications/ardour8.desktop
sudo rm --force --recursive /usr/share/applications/assistant.desktop
sudo rm --force --recursive /usr/share/applications/avahi-discover.desktop
sudo rm --force --recursive /usr/share/applications/bssh.desktop
sudo rm --force --recursive /usr/share/applications/btop.desktop
sudo rm --force --recursive /usr/share/applications/bvnc.desktop
sudo rm --force --recursive /usr/share/applications/calf.desktop
sudo rm --force --recursive /usr/share/applications/cmake-gui.desktop
sudo rm --force --recursive /usr/share/applications/codium.desktop
sudo rm --force --recursive /usr/share/applications/designer.desktop
sudo rm --force --recursive /usr/share/applications/fcitx5-configtool.desktop
sudo rm --force --recursive /usr/share/applications/foot-server.desktop
sudo rm --force --recursive /usr/share/applications/footclient.desktop
sudo rm --force --recursive /usr/share/applications/kbd-layout-viewer5.desktop
sudo rm --force --recursive /usr/share/applications/linguist.desktop
sudo rm --force --recursive /usr/share/applications/lstopo.desktop
sudo rm --force --recursive /usr/share/applications/org.fcitx.fcitx5-migrator.desktop
sudo rm --force --recursive /usr/share/applications/org.fcitx.Fcitx5.desktop
sudo rm --force --recursive /usr/share/applications/org.kde.filelight.desktop
sudo rm --force --recursive /usr/share/applications/org.kde.kdf.desktop
sudo rm --force --recursive /usr/share/applications/org.kde.kompare.desktop
sudo rm --force --recursive /usr/share/applications/org.kde.konsole.desktop
sudo rm --force --recursive /usr/share/applications/org.kde.kwikdisk.desktop
sudo rm --force --recursive /usr/share/applications/phoronix-test-suite.desktop
sudo rm --force --recursive /usr/share/applications/qdbusviewer.desktop
sudo rm --force --recursive /usr/share/applications/qv4l2.desktop
sudo rm --force --recursive /usr/share/applications/qvidcap.desktop
sudo rm --force --recursive /usr/share/applications/rofi.desktop
sudo rm --force --recursive /usr/share/applications/rofi-theme-selector.desktop
sudo rm --force --recursive /usr/share/applications/uuctl.desktop
sudo rm --force --recursive /usr/share/applications/xgps.desktop
sudo rm --force --recursive /usr/share/applications/xgpsspeed.desktop
sudo ln --symbolic /dev/null /usr/share/applications/ardour8.desktop
sudo ln --symbolic /dev/null /usr/share/applications/assistant.desktop
sudo ln --symbolic /dev/null /usr/share/applications/avahi-discover.desktop
sudo ln --symbolic /dev/null /usr/share/applications/bssh.desktop
sudo ln --symbolic /dev/null /usr/share/applications/btop.desktop
sudo ln --symbolic /dev/null /usr/share/applications/bvnc.desktop
sudo ln --symbolic /dev/null /usr/share/applications/calf.desktop
sudo ln --symbolic /dev/null /usr/share/applications/cmake-gui.desktop
sudo ln --symbolic /dev/null /usr/share/applications/codium.desktop
sudo ln --symbolic /dev/null /usr/share/applications/designer.desktop
sudo ln --symbolic /dev/null /usr/share/applications/fcitx5-configtool.desktop
sudo ln --symbolic /dev/null /usr/share/applications/foot-server.desktop
sudo ln --symbolic /dev/null /usr/share/applications/footclient.desktop
sudo ln --symbolic /dev/null /usr/share/applications/kbd-layout-viewer5.desktop
sudo ln --symbolic /dev/null /usr/share/applications/linguist.desktop
sudo ln --symbolic /dev/null /usr/share/applications/lstopo.desktop
sudo ln --symbolic /dev/null /usr/share/applications/org.fcitx.fcitx5-migrator.desktop
sudo ln --symbolic /dev/null /usr/share/applications/org.fcitx.Fcitx5.desktop
sudo ln --symbolic /dev/null /usr/share/applications/org.kde.filelight.desktop
sudo ln --symbolic /dev/null /usr/share/applications/org.kde.kdf.desktop
sudo ln --symbolic /dev/null /usr/share/applications/org.kde.kompare.desktop
sudo ln --symbolic /dev/null /usr/share/applications/org.kde.konsole.desktop
sudo ln --symbolic /dev/null /usr/share/applications/org.kde.kwikdisk.desktop
sudo ln --symbolic /dev/null /usr/share/applications/phoronix-test-suite.desktop
sudo ln --symbolic /dev/null /usr/share/applications/qdbusviewer.desktop
sudo ln --symbolic /dev/null /usr/share/applications/qv4l2.desktop
sudo ln --symbolic /dev/null /usr/share/applications/qvidcap.desktop
sudo ln --symbolic /dev/null /usr/share/applications/rofi.desktop
sudo ln --symbolic /dev/null /usr/share/applications/rofi-theme-selector.desktop
sudo ln --symbolic /dev/null /usr/share/applications/uuctl.desktop
sudo ln --symbolic /dev/null /usr/share/applications/xgps.desktop
sudo ln --symbolic /dev/null /usr/share/applications/xgpsspeed.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/ardour8.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/assistant.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/avahi-discover.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/bssh.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/btop.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/bvnc.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/calf.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/cmake-gui.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/codium.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/designer.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/fcitx5-configtool.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/foot-server.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/footclient.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/kbd-layout-viewer5.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/linguist.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/lstopo.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/org.fcitx.fcitx5-migrator.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/org.fcitx.Fcitx5.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/org.kde.filelight.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/org.kde.kdf.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/org.kde.kompare.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/org.kde.konsole.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/org.kde.kwikdisk.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/phoronix-test-suite.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/qdbusviewer.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/qv4l2.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/qvidcap.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/rofi.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/rofi-theme-selector.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/uuctl.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/xgps.desktop
printf "%s\n" "NoDisplay=true" >> ~/.local/share/applications/xgpsspeed.desktop

#######################################
# Virtualization
#######################################

# Verify the boot mode
# boot="$(cat /sys/firmware/efi/fw_platform_size)"
# if [[ "${boot}" == "64" ]]; then
#   printf "%s\n" "System is booted in UEFI mode and has a 64-bit x64 UEFI"
# elif [[ "${boot}" == "32" ]]; then
#   printf "%s\n" "System is booted in UEFI mode and has a 32-bit IA32 UEFI"
# else
#   printf "%s\n" "System may be booted in BIOS (or CSM) mode"
#   printf "%s\n" "Refer to your motherboard's manual"
#   exit
# fi

# Verify IOMMU
# iommu="$(sudo dmesg | grep --extended-regexp 'IOMMU' | grep --extended-regexp --max-count 1 'IOMMU')"
# if [[ "${iommu}" == "[    0.000000] DMAR: IOMMU enabled" ]]; then
#   printf "%s\n" "System is booted with IOMMU enabled"
# elif [[ "${iommu}" == "[    0.000000] Warning: PCIe ACS overrides enabled; This may allow non-IOMMU protected peer-to-peer DMA" ]]; then
#   printf "%s\n" "System is booted with IOMMU enabled and has ACS override patch"
# else
#   printf "%s\n" "System may be booted with IOMMU disabled"
#   printf "%s\n" "Refer to your BIOS's manual"
#   exit
# fi

# Verify NX mode
# nx="$(sudo dmesg | grep --extended-regexp 'Execute Disable')"
# if [[ "${nx}" == "[    0.000000] NX (Execute Disable) protection: active" ]]; then
#   printf "%s\n" "System is booted with NX mode enabled"
# else
#   printf "%s\n" "System may be booted with NX mode disabled"
#   printf "%s\n" "Refer to your BIOS's manual"
#   exit
# fi

# Verify SVM mode
# vendor="$(lscpu | grep --extended-regexp --only-matching 'AuthenticAMD')"
# if [[ "${vendor}" == "AuthenticAMD" ]]; then
#   svm="$(lscpu | grep --extended-regexp --word-regexp --only-matching 'svm')"
#   if [[ "${svm}" == "svm" ]]; then
#     printf "%s\n" "System is booted with SVM mode enabled"
#   else
#     printf "%s\n" "System may be booted with SVM mode disabled"
#     printf "%s\n" "Refer to your BIOS's manual"
#     exit
#   fi
# fi

# Install virtualization packages
yes y | sudo pacman -S --needed virt-manager qemu-full vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf || [ $? -eq 141 ]

# Configure libvirt
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
sudo virsh net-autostart default
mkdir --parents /home/"${username}"/Virtualization

#######################################
# Post-Installation
#######################################

# Clean
yay -Scc --noconfirm

# Allow members of group wheel sudo access with a password
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Reboot
sec=15
while [[ ${sec} -gt 1 ]]; do
  printf "\033[2K"
  printf "\033[9C%s\r" "Restarting in $sec seconds"
  sleep 1
  ((sec--))
done
printf "\033[2K"
printf "\033[9C%s\r" "Restarting in 1 second"
sleep 1
reboot
