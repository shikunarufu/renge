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

# Foot
sudo pacman -S --noconfirm --needed foot foot-terminfo libnotify xdg-utils
cp --recursive /home/"${username}"/renge/foot /home/"${username}"/.config

# Greetd
sudo pacman -S --noconfirm --needed greetd greetd-tuigreet
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet --cmd Hyprland --remember"|g' /etc/greetd/config.toml
sudo systemctl enable greetd.service

# Waybar
sudo pacman -S --noconfirm --needed waybar
cp --recursive /home/"${username}"/renge/waybar /home/"${username}"/.config

# SWWW
yay -S --answerclean All --answerdiff None --noconfirm swww
mkdir /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/renge/wallpapers/desktop.png /home/"${username}"/Pictures/Wallpapers

# Rofi
sudo pacman -S --noconfirm --needed rofi-wayland
cp --recursive /home/"${username}"/renge/rofi /home/"${username}"/.config

# Vesktop
yay -S --answerclean All --answerdiff None --noconfirm vesktop

# Dolphin
sudo pacman -S --noconfirm --needed dolphin audiocd-kio baloo dolphin-plugins kio-admin kio-gdrive kompare ffmpegthumbs icoutils kdegraphics-thumbnailers kdesdk-thumbnailers kimageformats libheif libappimage qt6-imageformats taglib
yay -S --answerclean All --answerdiff None --noconfirm kde-thumbnailer-apk raw-thumbnailer resvg

# Hyprshot
yay -S --answerclean All --answerdiff None --noconfirm hyprshot-git

# Fish
sudo pacman -S --noconfirm --needed fish
cp --recursive /home/"${username}"/renge/fish /home/"${username}"/.config

# Starship
sudo pacman -S --noconfirm --needed starship
cp --recursive /home/"${username}"/renge/starship/starship.toml /home/"${username}"/.config

# Fastfetch
sudo pacman -S --noconfirm --needed fastfetch
cp --recursive /home/"${username}"/renge/fastfetch /home/"${username}"/.config

# Spotify
yay -S --answerclean All --answerdiff None --noconfirm spotify
sudo pacman -S --noconfirm --needed ffmpeg4.4 libnotify zenity
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R

# SpotX
bash <(curl -sSL https://spotx-official.github.io/run.sh)

# VSCodium
# yay -S --answerclean All --answerdiff None --noconfirm vscodium-bin

# Zen Browser
yay -S --answerclean All --answerdiff None --noconfirm zen-browser-bin

# Steam
sudo pacman -S --noconfirm --needed steam

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
