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
entry_status() {
  printf "\e[10G"
  if [[ $1 == *" "* ]]; then
    local sbjct=${1%% *}
    local prdct=${1#* }
    printf "%s \e[1;37m%s\e[0m\n" "${sbjct}" "${prdct}"
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
    local sbjct=${1%% *}
    local prdct=${1#* }
    printf "%s \e[1;37m%s\e[0m\n" "${sbjct}" "${prdct}"
  else
    printf "%s\n" "$1"
  fi
}



# Persistent bottom status line
status_init() {
  tput civis
  trap status_cleanup EXIT
  STATUS_LINES=$(tput lines)
  STATUS_COLS=$(tput cols)
  printf '\e[1;%dr' "$((STATUS_LINES-1))"  # scroll region: all but last line
  status_update "Ready"
}

status_update() {
  local msg="$1"
  tput sc
  tput cup $((STATUS_LINES-1)) 0
  tput el
  printf "[%s] %s" "$(date +%H:%M:%S)" "${msg:0:STATUS_COLS}"
  tput rc
}

spinner_start() {
  _sp_msg="$1"; _sp_i=0; _sp_chars='|/-\' ; _sp_run=1
  (
    while [ "$_sp_run" -eq 1 ]; do
      _sp_i=$(( (_sp_i + 1) % 4 ))
      status_update "$_sp_msg ${_sp_chars:_sp_i:1}"
      sleep 0.1
    done
  ) & _sp_pid=$!
}

spinner_stop() {
  _sp_run=0
  kill "$_sp_pid" 2>/dev/null
  wait "$_sp_pid" 2>/dev/null
  status_update "$1"
}

run() {
  local msg="$1"; shift
  spinner_start "$msg"
  "$@"; local rc=$?
  if [ $rc -eq 0 ]; then
    spinner_stop "$msg - OK"
  else
    spinner_stop "$msg - FAILED ($rc)"
    return $rc
  fi
}

status_cleanup() {
  tput sc
  printf '\e[r'    # reset scroll region
  tput cnorm
  tput rc
}



# Clear the terminal screen
run "Clearing Terminal Screen"
clear
#exit_status "Cleared Terminal Screen"

# Allow members of group wheel sudo access without a password
run "Allowing Sudo Access Without Password"
printf "%s\n%s" "${user_passwd}" | sudo --stdin sed --in-place 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
#exit_status "Allowed Sudo Access Without Password"

#######################################
# Installation
#######################################

# Yay
run "Installing Yay Dependencies"
sudo pacman -S --noconfirm --needed git base-devel
#exit_status "Installed Yay Dependencies"
run "Cloning Yay Repository"
git clone https://aur.archlinux.org/yay.git
#exit_status "Cloned Yay Repository"
run "Installing Yay"
cd yay
makepkg -si --noconfirm
#exit_status "Installed Yay"
run "Generating Development Package Database"
yay --yay --gendb
#exit_status "Generated Development Package Database"
run "Updating Development Package"
yay -Syu --devel --answerupgrade None --noconfirm
#exit_status "Updated Development Package"
run "Enabling Development Package Updates"
yay --yay --devel --save
#exit_status "Enabled Development Package Updates"

# Hyprland
run "Installing Hyprland Dependencies"
yay -S --answerclean All --answerdiff None --noconfirm ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils
#exit_status "Installed Hyprland Dependencies"
run "Cloning Hyprland Repository"
git clone --recursive https://github.com/hyprwm/Hyprland
#exit_status "Cloned Hyprland Repository"
run "Compiling Hyprland"
cd Hyprland
make all
#exit_status "Compiled Hyprland"
run "Installing Hyprland"
sudo make install
#exit_status "Installed Hyprland"
run "Configuring Hyprland"
cp --recursive /home/"${username}"/renge/hypr /home/"${username}"/.config
#exit_status "Configured Hyprland"

# Foot
run "Installing Foot"
sudo pacman -S --noconfirm --needed foot foot-terminfo libnotify xdg-utils
#exit_status "Installed Foot"
run "Configuring Foot"
cp --recursive /home/"${username}"/renge/foot /home/"${username}"/.config
#exit_status "Configured Foot"

# Greetd
run "Installing Greetd"
sudo pacman -S --noconfirm --needed greetd greetd-tuigreet
#exit_status "Installed Greetd"
run "Configuring Greetd"
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet --cmd Hyprland --remember"|g' /etc/greetd/config.toml
#exit_status "Configured Greetd"
run "Enabling Greetd"
sudo systemctl enable greetd.service
#exit_status "Enabled Greetd"

# Waybar
run "Installing Waybar"
sudo pacman -S --noconfirm --needed waybar
#exit_status "Installed Waybar"
run "Configuring Waybar"
cp --recursive /home/"${username}"/renge/waybar /home/"${username}"/.config
#exit_status "Configured Waybar"

# SWWW
run "Installing SWWW"
yay -S --answerclean All --answerdiff None --noconfirm swww
#exit_status "Installed SWWW"
run "Configuring SWWW"
mkdir /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/renge/wallpapers/desktop.png /home/"${username}"/Pictures/Wallpapers
#exit_status "Configured SWWW"

# Rofi
run "Installing Rofi"
sudo pacman -S --noconfirm --needed rofi-wayland
#exit_status "Installed Rofi"
run "Configuring Rofi"
cp --recursive /home/"${username}"/renge/rofi /home/"${username}"/.config
#exit_status "Configured Rofi"

# Vesktop
run "Installing Vesktop"
yay -S --answerclean All --answerdiff None --noconfirm vesktop
#exit_status "Installed Vesktop"

# Dolphin
run "Installing Dolphin"
sudo pacman -S --noconfirm --needed dolphin audiocd-kio baloo dolphin-plugins kio-admin kio-gdrive kompare ffmpegthumbs icoutils kdegraphics-thumbnailers kdesdk-thumbnailers kimageformats libheif libappimage qt6-imageformats taglib
#exit_status "Installed Dolphin"
run "Installing Dolphin Dependencies"
yay -S --answerclean All --answerdiff None --noconfirm kde-thumbnailer-apk raw-thumbnailer resvg
#exit_status "Installed Dolphin Dependencies"

# Hyprshot
run "Installing Hyprshot"
yay -S --answerclean All --answerdiff None --noconfirm hyprshot-git
#exit_status "Installed Hyprshot"

# Fish
run "Installing Fish"
sudo pacman -S --noconfirm --needed fish
#exit_status "Installed Fish"
run "Configuring Fish"
cp --recursive /home/"${username}"/renge/fish /home/"${username}"/.config
#exit_status "Configured Fish"

# Starship
run "Installing Starship"
sudo pacman -S --noconfirm --needed starship
#exit_status "Installed Starship"
run "Configuring Starship"
cp --recursive /home/"${username}"/renge/starship/starship.toml /home/"${username}"/.config
#exit_status "Configured Starship"

# Fastfetch
run "Installing Fastfetch"
sudo pacman -S --noconfirm --needed fastfetch
#exit_status "Installed Fastfetch"
run "Configuring Fastfetch"
cp --recursive /home/"${username}"/renge/fastfetch /home/"${username}"/.config
#exit_status "Configured Fastfetch"

# Spotify
run "Installing Spotify"
yay -S --answerclean All --answerdiff None --noconfirm spotify
#exit_status "Installed Spotify"
run "Installing Spotify Dependencies"
sudo pacman -S --noconfirm --needed ffmpeg4.4 libnotify zenity
#exit_status "Installed Spotify Dependencies"
run "Configuring Spotify"
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
#exit_status "Configured Spotify"

# SpotX
run "Applying SpotX"
bash <(curl -sSL https://spotx-official.github.io/run.sh)
#exit_status "Applied SpotX"

# VSCodium
# run "Installing VSCodium"
# yay -S --answerclean All --answerdiff None --noconfirm vscodium-bin
# #exit_status "Installed VSCodium"

# Zen Browser
run "Installing Zen Browser"
yay -S --answerclean All --answerdiff None --noconfirm zen-browser-bin
#exit_status "Installed Zen Browser"

# Steam
run "Installing Steam"
sudo pacman -S --noconfirm --needed steam
#exit_status "Installed Steam"

#######################################
# Post-Installation
#######################################

# Clean
run "Removing Files From Cache And Unused Repositories"
yay -Scc --noconfirm
#exit_status "Removed Files From Cache And Unused Repositories"

# Allow members of group wheel sudo access with a password
run "Allowing Sudo Access With Password"
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
#exit_status "Allowed Sudo Access Without Password"

# Launch Hyprland
run "Launching Hyprland"
Hyprland
#exit_status "Launched Hyprland"

# swww img /home/"${username}"/Pictures/Wallpapers/desktop.png
