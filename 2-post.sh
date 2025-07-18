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
user_passwd="narufu"
username="Shiku"

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

#######################################
# Installation
#######################################

# Yay
#entry_status "Installing Yay"
printf "%s\n%s" "${user_passwd}" | sudo --stdin pacman -S --noconfirm --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
printf "%s\n%s" "${user_passwd}" | sudo --stdin makepkg -si
#exit_status "Installed Yay"
#entry_status "Generating Development Package Database"
yay --yay --gendb --noconfirm
#exit_status "Generated Development Package Database"
#entry_status "Updating Development Package"
yay -Syu --devel --noconfirm
#exit_status "Updated Development Package"
#entry_status "Enabling Development Package Updates"
yay --yay --devel --save --noconfirm
#exit_status "Enabled Development Package Updates"

# Hyprland
#entry_status "Installing Hyprland Dependencies"
yay -S --noconfirm ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils
#exit_status "Installed Hyprland Dependencies"
#entry_status "Installing Hyprland"
git clone --recursive https://github.com/hyprwm/Hyprland
cd Hyprland
make all && printf "%s\n%s" "${user_passwd}" | sudo --stdin make install
#exit_status "Installed Hyprland"

# Display manager
Install greetd
Install greetd-tuigreet
#systemctl enable greetd.service

# TODO
# bypass sudo on script
# bypass confirm on makepkg
# bypass confirm yay
# packages to cleanbuild? all
# diffs to show? none
