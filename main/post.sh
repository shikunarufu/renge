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
username="username"
user_passwd="user_passwd"

# Aesthetics
info_status() {
  printf "\e[10G"
  local text="$1"
  printf "%s\n" "$1"
}

# Function to display the status message
update_status() {
  # Move the cursor to the last line and clear it
  tput cup $(($(tput lines) - 1)) 0
  tput el
  echo -n "$1"
}

# Clear the terminal screen
update_status "Clearing Terminal Screen"
clear

# Allow members of group wheel sudo access without a password
update_status "Allowing Sudo Access Without Password"
printf "%s\n%s" "${user_passwd}" | sudo --stdin sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

#######################################
# Installation
#######################################

# Yay
update_status "Installing Yay Dependencies"
sudo pacman -S --noconfirm --needed git base-devel
update_status "Cloning Yay Repository"
git clone https://aur.archlinux.org/yay.git
update_status "Installing Yay"
cd yay
makepkg -si --noconfirm
update_status "Generating Development Package Database"
yay --yay --gendb
update_status "Updating Development Package"
yay -Syu --devel --answerupgrade None --noconfirm
update_status "Enabling Development Package Updates"
yay --yay --devel --save

# Hyprland
update_status "Installing Hyprland Dependencies"
yay -S --answerclean All --answerdiff None --noconfirm ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils
update_status "Cloning Hyprland Repository"
git clone --recursive https://github.com/hyprwm/Hyprland
update_status "Compiling Hyprland"
cd Hyprland
make all
update_status "Installing Hyprland"
sudo make install
update_status "Configuring Hyprland"
cp --recursive /home/"${username}"/renge/hypr /home/"${username}"/.config

# Foot
update_status "Installing Foot"
sudo pacman -S --noconfirm --needed foot foot-terminfo libnotify xdg-utils
update_status "Configuring Foot"
cp --recursive /home/"${username}"/renge/foot /home/"${username}"/.config

# Greetd
update_status "Installing Greetd"
sudo pacman -S --noconfirm --needed greetd greetd-tuigreet
update_status "Configuring Greetd"
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet --cmd Hyprland --remember"|g' /etc/greetd/config.toml
update_status "Enabling Greetd"
sudo systemctl enable greetd.service

# Waybar
update_status "Installing Waybar"
sudo pacman -S --noconfirm --needed waybar
update_status "Configuring Waybar"
cp --recursive /home/"${username}"/renge/waybar /home/"${username}"/.config

# SWWW
update_status "Installing SWWW"
yay -S --answerclean All --answerdiff None --noconfirm swww
update_status "Configuring SWWW"
mkdir /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/renge/wallpapers/desktop.png /home/"${username}"/Pictures/Wallpapers

# Rofi
update_status "Installing Rofi"
sudo pacman -S --noconfirm --needed rofi-wayland
update_status "Configuring Rofi"
cp --recursive /home/"${username}"/renge/rofi /home/"${username}"/.config

# Vesktop
update_status "Installing Vesktop"
yay -S --answerclean All --answerdiff None --noconfirm vesktop

# Dolphin
update_status "Installing Dolphin"
sudo pacman -S --noconfirm --needed dolphin audiocd-kio baloo dolphin-plugins kio-admin kio-gdrive kompare ffmpegthumbs icoutils kdegraphics-thumbnailers kdesdk-thumbnailers kimageformats libheif libappimage qt6-imageformats taglib
update_status "Installing Dolphin Dependencies"
yay -S --answerclean All --answerdiff None --noconfirm kde-thumbnailer-apk raw-thumbnailer resvg

# Hyprshot
update_status "Installing Hyprshot"
yay -S --answerclean All --answerdiff None --noconfirm hyprshot-git

# Fish
update_status "Installing Fish"
sudo pacman -S --noconfirm --needed fish
update_status "Configuring Fish"
cp --recursive /home/"${username}"/renge/fish /home/"${username}"/.config

# Starship
update_status "Installing Starship"
sudo pacman -S --noconfirm --needed starship
update_status "Configuring Starship"
cp --recursive /home/"${username}"/renge/starship/starship.toml /home/"${username}"/.config

# Fastfetch
update_status "Installing Fastfetch"
sudo pacman -S --noconfirm --needed fastfetch
update_status "Configuring Fastfetch"
cp --recursive /home/"${username}"/renge/fastfetch /home/"${username}"/.config

# Spotify
update_status "Installing Spotify"
yay -S --answerclean All --answerdiff None --noconfirm spotify
update_status "Installing Spotify Dependencies"
sudo pacman -S --noconfirm --needed ffmpeg4.4 libnotify zenity
update_status "Configuring Spotify"
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R

# SpotX
update_status "Applying SpotX"
bash <(curl -sSL https://spotx-official.github.io/run.sh)

# VSCodium
# update_status "Installing VSCodium"
# yay -S --answerclean All --answerdiff None --noconfirm vscodium-bin

# Zen Browser
update_status "Installing Zen Browser"
yay -S --answerclean All --answerdiff None --noconfirm zen-browser-bin

# Steam
update_status "Installing Steam"
sudo pacman -S --noconfirm --needed steam

#######################################
# Post-Installation
#######################################

# Clean
update_status "Removing Files From Cache And Unused Repositories"
yay -Scc --noconfirm

# Allow members of group wheel sudo access with a password
update_status "Allowing Sudo Access With Password"
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Launch Hyprland
update_status "Launching Hyprland"
Hyprland

# swww img /home/"${username}"/Pictures/Wallpapers/desktop.png
