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
entry_status "Clearing Terminal Screen"
clear
exit_status "Cleared Terminal Screen"

# Allow members of group wheel sudo access without a password
entry_status "Allowing Sudo Access Without Password"
printf "%s\n%s" "${user_passwd}" | sudo --stdin sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers > /dev/null 2>&1
exit_status "Allowed Sudo Access Without Password"

#######################################
# Installation
#######################################

# Yay
entry_status "Installing Yay Dependencies"
sudo pacman -S --noconfirm --needed git base-devel > /dev/null 2>&1
exit_status "Installed Yay Dependencies"
entry_status "Cloning Yay Repository"
git clone https://aur.archlinux.org/yay.git > /dev/null 2>&1
exit_status "Cloned Yay Repository"
entry_status "Installing Yay"
cd yay
makepkg -si --noconfirm > /dev/null 2>&1
exit_status "Installed Yay"
entry_status "Generating Development Package Database"
yay --yay --gendb > /dev/null 2>&1
exit_status "Generated Development Package Database"
entry_status "Updating Development Package"
yay -Syu --devel --answerupgrade None --noconfirm > /dev/null 2>&1
exit_status "Updated Development Package"
entry_status "Enabling Development Package Updates"
yay --yay --devel --save
exit_status "Enabled Development Package Updates"

# Hyprland
entry_status "Installing Hyprland Dependencies"
yay -S --answerclean All --answerdiff None --noconfirm ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils > /dev/null 2>&1
exit_status "Installed Hyprland Dependencies"
entry_status "Cloning Hyprland Repository"
git clone --recursive https://github.com/hyprwm/Hyprland > /dev/null 2>&1
exit_status "Cloned Hyprland Repository"
entry_status "Compiling Hyprland"
cd Hyprland
make all > /dev/null 2>&1
exit_status "Compiled Hyprland"
entry_status "Installing Hyprland"
sudo make install > /dev/null 2>&1
exit_status "Installed Hyprland"
entry_status "Configuring Hyprland"
cp --recursive /home/"${username}"/ALIS/hypr /home/"${username}"/.config
exit_status "Configured Hyprland"

# SWWW
entry_status "Installing SWWW"
yay -S --answerclean All --answerdiff None --noconfirm swww > /dev/null 2>&1
exit_status "Installed SWWW"
entry_status "Configuring SWWW"
mkdir /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/ALIS/Desktop.png /home/"${username}"/Pictures/Wallpapers
exit_status "Configured SWWW"

# Foot
entry_status "Installing Foot"
sudo pacman -S --noconfirm --needed foot foot-terminfo libnotify xdg-utils > /dev/null 2>&1
exit_status "Installed Foot"
entry_status "Configuring Foot"
cp --recursive /home/"${username}"/ALIS/foot /home/"${username}"/.config
exit_status "Configured Foot"

# Waybar
entry_status "Installing Waybar"
sudo pacman -S --noconfirm --needed waybar > /dev/null 2>&1
exit_status "Installed Waybar"
entry_status "Configuring Waybar"
cp --recursive /home/"${username}"/ALIS/waybar /home/"${username}"/.config
exit_status "Configured Waybar"

# Rofi
entry_status "Installing Rofi"
sudo pacman -S --noconfirm --needed rofi-wayland > /dev/null 2>&1
exit_status "Installed Rofi"
entry_status "Configuring Rofi"
cp --recursive /home/"${username}"/ALIS/rofi /home/"${username}"/.config
exit_status "Configured Rofi"

# Dolphin
entry_status "Installing Dolphin"
sudo pacman -S --noconfirm --needed dolphin audiocd-kio baloo dolphin-plugins kio-admin kio-gdrive kompare ffmpegthumbs icoutils kdegraphics-thumbnailers kdesdk-thumbnailers kimageformats libheif libappimage qt6-imageformats taglib > /dev/null 2>&1
exit_status "Installed Dolphin"
entry_status "Installing Dolphin Dependencies"
yay -S --answerclean All --answerdiff None --noconfirm kde-thumbnailer-apk raw-thumbnailer resvg > /dev/null 2>&1
exit_status "Installed Dolphin Dependencies"

# Fish
entry_status "Installing Fish"
sudo pacman -S --noconfirm --needed fish > /dev/null 2>&1
exit_status "Installed Fish"
entry_status "Configuring Fish"
cp --recursive /home/"${username}"/ALIS/fish /home/"${username}"/.config
exit_status "Configured Fish"

# Starship
entry_status "Installing Starship"
sudo pacman -S --noconfirm --needed starship > /dev/null 2>&1
exit_status "Installed Starship"
entry_status "Configuring Starship"
cp --recursive /home/"${username}"/ALIS/starship.toml /home/"${username}"/.config
exit_status "Configured Starship"

# Fastfetch
entry_status "Installing Fastfetch"
sudo pacman -S --noconfirm --needed fastfetch > /dev/null 2>&1
exit_status "Installed Fastfetch"
entry_status "Configuring Fastfetch"
cp --recursive /home/"${username}"/ALIS/fastfetch /home/"${username}"/.config
exit_status "Configured Fastfetch"

# Display manager
entry_status "Installing Greetd"
sudo pacman -S --noconfirm --needed greetd greetd-tuigreet > /dev/null 2>&1
exit_status "Installed Greetd"
entry_status "Configuring Greetd"
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet --cmd Hyprland --remember"|g' /etc/greetd/config.toml
exit_status "Configured Greetd"
entry_status "Enabling Greetd"
sudo systemctl enable greetd.service > /dev/null 2>&1
exit_status "Enabled Greetd"

# Spotify
entry_status "Installing Spotify"
yay -S --answerclean All --answerdiff None --noconfirm spotify > /dev/null 2>&1
exit_status "Installed Spotify"
entry_status "Installing Spotify Dependencies"
sudo pacman -S --noconfirm --needed ffmpeg4.4 libnotify zenity > /dev/null 2>&1
exit_status "Installed Spotify Dependencies"
entry_status "Configuring Spotify"
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
exit_status "Configured Spotify"

# SpotX
entry_status "Applying SpotX"
bash <(curl -sSL https://spotx-official.github.io/run.sh) > /dev/null 2>&1
exit_status "Applied SpotX"

# VSCodium
# entry_status "Installing VSCodium"
# yay -S --answerclean All --answerdiff None --noconfirm vscodium-bin > /dev/null 2>&1
# exit_status "Installed VSCodium"

# Zen Browser
entry_status "Installing Zen Browser"
yay -S --answerclean All --answerdiff None --noconfirm zen-browser-bin > /dev/null 2>&1
exit_status "Installed Zen Browser"

# Vesktop
entry_status "Installing Vesktop"
yay -S --answerclean All --answerdiff None --noconfirm vesktop > /dev/null 2>&1
exit_status "Installed Vesktop"

# Steam
entry_status "Installing Steam"
sudo pacman -S --noconfirm --needed steam > /dev/null 2>&1
exit_status "Installed Steam"

#######################################
# Post-Installation
#######################################

# Clean
entry_status "Removing Files From Cache And Unused Repositories"
yay -Scc --noconfirm
exit_status "Removed Files From Cache And Unused Repositories"

# Allow members of group wheel sudo access with a password
entry_status "Allowing Sudo Access With Password"
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
exit_status "Allowed Sudo Access Without Password"

# Launch Hyprland
entry_status "Launching Hyprland"
Hyprland > /dev/null 2>&1
exit_status "Launched Hyprland"

# swww img /home/"${username}"/Pictures/Wallpapers/Desktop.png
