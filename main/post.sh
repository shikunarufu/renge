#!/bin/bash
#
# Shiku's Post Arch Linux Installation Script

# This script automates the post-installation process of Arch Linux.

# This script assumes you have already booted
# and logged in into the new system with the user account.

# This script assumes a working internet connection is available.

# Uncomment the line below to show command outputs.
# set -x

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
  echo "Failed to connect to the internet"
fi

# Allow members of group wheel sudo access without a password
printf "%s\n%s" "${user_passwd}" | sudo --stdin sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

#######################################
# Installation
#######################################

# Yay
sudo pacman -S --noconfirm --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
yay --yay --gendb
yay -Syu --devel --answerupgrade None --noconfirm
yay --yay --devel --save

# Hyprland
yay -S --answerclean All --answerdiff None --noconfirm ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils
git clone --recursive https://github.com/hyprwm/Hyprland
cd Hyprland
make all && sudo make install
cp --recursive /home/"${username}"/renge/hypr /home/"${username}"/.config

# Installation
curl --silent --location https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/main/pkgs/post-pacman-pkglist.txt >> post-pacman-pkglist.txt
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' post-pacman-pkglist.txt | sort --output=post-pacman-pkglist.txt --unique
sudo pacman -S --noconfirm --needed - < post-pacman-pkglist.txt
rm post-pacman-pkglist.txt

curl --silent --location https://raw.githubusercontent.com/shikunarufu/renge/refs/heads/main/main/pkgs/post-yay-pkglist.txt >> post-yay-pkglist.txt
grep --extended-regexp --only-matching '^[^(#|[:space:])]*' post-yay-pkglist.txt | sort --output=post-yay-pkglist.txt --unique
yay -S --answerclean All --answerdiff None --noconfirm - < post-yay-pkglist.txt
rm post-yay-pkglist.txt

# Foot
cp --recursive /home/"${username}"/renge/foot /home/"${username}"/.config

# Greetd
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet --cmd Hyprland --remember"|g' /etc/greetd/config.toml
sudo systemctl enable greetd.service

# Waybar
cp --recursive /home/"${username}"/renge/waybar /home/"${username}"/.config

# SWWW
mkdir /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/renge/wallpapers/desktop.png /home/"${username}"/Pictures/Wallpapers

# Rofi
cp --recursive /home/"${username}"/renge/rofi /home/"${username}"/.config

# Fish
cp --recursive /home/"${username}"/renge/fish /home/"${username}"/.config

# Dunst
cp --recursive /home/"${username}"/renge/dunst /home/"${username}"/.config

# Hyprshot
mkdir /home/"${username}"/Pictures/Screenshots

# Starship
cp --recursive /home/"${username}"/renge/starship/starship.toml /home/"${username}"/.config

# Fastfetch
cp --recursive /home/"${username}"/renge/fastfetch /home/"${username}"/.config

# SpotX
bash <(curl -sSL https://spotx-official.github.io/run.sh)

#######################################
# Post-Installation
#######################################

# Clean
yay -Scc --noconfirm

# Allow members of group wheel sudo access with a password
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Launch Hyprland
Hyprland

# swww img /home/"${username}"/Pictures/Wallpapers/desktop.png
