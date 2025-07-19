#!/bin/bash
#
# Shiku's Post Arch Linux Installation Script

# This script automates the post-installation process of Arch Linux.

# This script assumes you have already booted
# and logged in into the new system with the user account.

# This script assumes a working internet connection is available.

# Uncomment the line below to show command outputs.
set -x

#######################################
# Preparation
#######################################

# Configuration
username="Shiku"
user_passwd="narufu"

# Aesthetics
entry_status() {
  printf "\e[10G"
  if [[ $1 == *" "* ]]; then
    local subject=${1%% *}
    local predicate=${1#* }
    printf "%s \e[1;37m%s\e[0m\n" "${subject}" "${predicate}"
  else
    printf "%s\n" "$1"
  fi
}
info_status() {
  printf "\e[10G"
  local text="$1"
  printf "%s\n" "$1"
}
exit_status() {
  printf "["
  printf "\e[0;32m"
  printf "  OK  "
  printf "\e[0m"
  printf "]"
  printf "\e[10G"
  if [[ $1 == *" "* ]]; then
    local subject=${1%% *}
    local predicate=${1#* }
    printf "%s \e[1;37m%s\e[0m\n" "${subject}" "${predicate}"
  else
    printf "%s\n" "$1"
  fi
}

# Clear the terminal screen
#entry_status "Clearing Terminal Screen"
clear
#exit_status "Cleared Terminal Screen"

# Allow members of group wheel sudo access without a password
#entry_status "Allowing Sudo Access Without Password"
printf "%s\n%s" "${user_passwd}" | sudo --stdin sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
#exit_status "Allowed Sudo Access Without Password"

#######################################
# Installation
#######################################

# Yay
#entry_status "Installing Yay"
sudo pacman -S --noconfirm --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
#exit_status "Installed Yay"
#entry_status "Generating Development Package Database"
yay --yay --gendb
#exit_status "Generated Development Package Database"
#entry_status "Updating Development Package"
yay -Syu --devel --answerupgrade None --noconfirm
#exit_status "Updated Development Package"
#entry_status "Enabling Development Package Updates"
yay --yay --devel --save
#exit_status "Enabled Development Package Updates"

# Hyprland
#entry_status "Installing Hyprland Dependencies"
yay -S ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils --answerclean All --answerdiff None --noconfirm
#exit_status "Installed Hyprland Dependencies"
#entry_status "Installing Hyprland"
git clone --recursive https://github.com/hyprwm/Hyprland
cd Hyprland
make all && sudo make install
#exit_status "Installed Hyprland"
#entry_status "Configuring Hyprland"
sudo mkdir /home/"${username}"/.config/hypr
sudo bash -c "cat > /home/${username}/.config/hypr/hyprland.conf" << EOF
################
### MONITORS ###
################
monitor = , 1920x1080@180, 0x0, 1

###################
### MY PROGRAMS ###
###################
$terminal = foot
$fileManager = dolphin
$menu = wofi --show drun

###################
### KEYBINDINGS ###
###################
bind = $mainMod, Q, exec, $terminal
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, R, exec, $menu
EOF
#exit_status "Configured Hyprland"

# Foot
#entry_status "Installing Foot"
sudo pacman -S --noconfirm foot foot-terminfo libnotify xdg-utils
#exit_status "Installed Foot"
#entry_status "Configuring Foot"
sudo mkdir /home/"${username}"/.config/foot
sudo bash -c "cat > /home/${username}/.config/foot/foot.ini" << EOF
-*- conf -*-

shell=fish
title=foot
font=JetBrains Mono Nerd Font:size=12
letter-spacing=0
dpi-aware=no
gamma-correct-blending=no
pad=25x25
bold-text-in-bright=no

[scrollback]
lines=10000

[cursor]
style=beam
beam-thickness=1.5

[colors]
alpha=0.78

[key-bindings]
scrollback-up-page=Page_Up
scrollback-down-page=Page_Down
search-start=Control+Shift+f

[search-bindings]
cancel=Escape
find-prev=Shift+F3
find-next=F3 Control+G
EOF
#exit_status "Configured Foot"

# Quickshell
#entry_status "Installing Quickshell"
yay -S quickshell-git --answerclean All --answerdiff None --noconfirm
#exit_status "Installed Quickshell"

# Display manager
Install greetd
Install greetd-tuigreet
#systemctl enable greetd.service

#######################################
# Post-Installation
#######################################

# Allow members of group wheel sudo access with a password
#entry_status "Allowing Sudo Access With Password"
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
#exit_status "Allowed Sudo Access Without Password"

# Launch Hyprland
#entry_status "Launching Hyprland"
Hyprland
#exit_status "Launched Hyprland"
