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
mkdir /home/"${username}"/.config/hypr
cat > /home/"${username}"/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Config File

# Monitors
monitor = , 1920x1080@180, 0x0, 1
#monitor = , preferred, auto, auto

# Programs
$terminal = foot
$fileManager = dolphin
$menu = rofi -show drun -show-icons

# Autostart
exec-once = waybar
exec-once = swww-daemon

# Environment Variables
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = SWWW_TRANSITION,wipe
env = SWWW_TRANSITION_FPS,180
env = SWWW_TRANSITION_STEP,1

# Look And Feel
general {
  border_size = 0
  gaps_in = 3.5
  gaps_out = 7
  layout = dwindle
  resize_on_border = false
  allow_tearing = false
}
decoration {
  rounding = 7
  rounding_power = 2
  active_opacity = 1.0
  inactive_opacity = 1.0
  dim_inactive = true
  dim_strength = 0.2
  dim_around = 0.4
  blur {
    enabled = true
    size = 3
    passes = 1
    vibrancy = 0.1696
  }
  shadow {
    enabled = false
    range = 4
    render_power = 3
    color = rgba(1a1a1aee)
  }
}
animations {
  enabled = true
  bezier = specialWorkSwitch, 0.05, 0.7, 0.1, 1
  bezier = emphasizedAccel, 0.3, 0, 0.8, 0.15
  bezier = emphasizedDecel, 0.05, 0.7, 0.1, 1
  bezier = standard, 0.2, 0, 0, 1
  animation = windowsIn, 1, 5, emphasizedDecel, slide
  animation = windowsOut, 1, 3, emphasizedAccel, slide
  animation = windowsMove, 1, 6, standard
  animation = layersIn, 1, 5, emphasizedDecel, slide
  animation = layersOut, 1, 4, emphasizedAccel, slide
  animation = fade, 1, 6, standard
  animation = fadeDim, 1, 6, standard
  animation = fadeLayers, 1, 5, standard
  animation = border, 1, 6, standard
  animation = workspaces, 1, 5, standard
  animation = specialWorkspace, 1, 4, specialWorkSwitch, slidefadevert 15%
}
dwindle {
  pseudotile = true
  preserve_split = true
}
master {
  new_status = master
}
misc {
  disable_hyprland_logo = true
  disable_splash_rendering = true
  force_default_wallpaper = -1
  background_color = 0x000000
}

# Input
input {
  kb_layout = us
  kb_variant =
  kb_model =
  kb_options =
  kb_rules =
  sensitivity = 0
  follow_mouse = 1
}

# Keybindings
$mainMod = SUPER
bind = $mainMod, return, exec, $terminal
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, V, togglefloating,
bind = $mainMod, space, exec, $menu
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+
bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-
bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindel = ,XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+
bindel = ,XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPause, exec, playerctl play-pause
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioPrev, exec, playerctl previous

# Windows And Workspaces
windowrule = suppressevent maximize, class:.*
windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0
EOF
#exit_status "Configured Hyprland"
#entry_status "Installing SWWW"
yay -S swww --answerclean All --answerdiff None --noconfirm
#exit_status "Installed SWWW"
#entry_status "Configuring SWWW"
mkdir /home/"${username}"/Pictures/Wallpapers
#exit_status "Configured SWWW"

# Foot
#entry_status "Installing Foot"
sudo pacman -S foot foot-terminfo libnotify xdg-utils --noconfirm
#exit_status "Installed Foot"

# Waybar
#entry_status "Installing Waybar"
sudo pacman -S waybar --noconfirm
yay -S material-symbols-git --answerclean All --answerdiff None --noconfirm
#exit_status "Installed Waybar"
mkdir /home/"${username}"/.config/waybar
cat > /home/"${username}"/.config/waybar/config.jsonc << 'EOF'
// Waybar Configuration File
{
  // Bar Configuration
  "layer": "bottom",
  "position": "top",
  "height": 28,
  "modules-left": [
    "clock",
    "clock#date",
    "custom/weather"
  ],
  "modules-center": [
    "hyprland/workspaces"
  ],
  "modules-right": [
    "custom/media",
    "pulseaudio",
    "network",
    "group/group-power"
  ],
  "margin-top": 7,
  "margin-left": 7,
  "margin-right": 7,
  "spacing": 7,
  // Module Configuration
  "clock": {
    "interval": "60",
    "format": " {:%H:%M}",
    "tooltip": true,
    "tooltip-format": "{:%I:%M %p}"
  },
  "clock#date": {
    "interval": "60",
    "format": " {:%a %b %d}",
    "tooltip": true,
    "tooltip-format": "{:%A, %d %B %Y}"
  },
  "custom/arch": {
    "format": "󰣇",
    "tooltip": false
  },
  "custom/lock": {
    "format": "",
    "on-click": "exit",
    "tooltip": true,
    "tooltip-format": "Lock"
  },
  "custom/restart": {
    "format": "",
    "on-click": "reboot",
    "tooltip": true,
    "tooltip-format": "Restart"
  },
  "custom/shutdown": {
    "format": "",
    "on-click": "shutdown now",
    "tooltip": true,
    "tooltip-format": "Shut Down"
  },
  "custom/sleep": {
    "format": "󰤄",
    "on-click": "exit",
    "tooltip": true,
    "tooltip-format": "Sleep"
  },
  "custom/weather": {
    "exec": "${HOME}/.config/waybar/scripts/get_weather.sh Dasmariñas",
    "return-type": "json",
    "format": "{}",
    "tooltip": true,
    "interval": 3600
  },
  "group/group-power": {
    "orientation": "horizontal",
    "modules": [
      "custom/arch",
      "custom/lock",
      "custom/sleep",
      "custom/restart",
      "custom/shutdown"
    ],
    "drawer": {
      "transition-duration": 250,
      "transition-left-to-right": true,
      "transition-timing-function": "ease-in-out"
    }
  },
  "hyprland/workspaces": {
    "active-only": false,
    "hide-active": false,
    "all-outputs": false,
    "format": "{icon}",
    "format-icons": {
      "active": "",
      "default": "",
      "urgent": ""
    }
  },
  "network": {
    "interval": "60",
    "family": "ipv4_6",
    "format-ethernet": "󰛳",
    "format-linked": "󰛵",
    "format-disconnected": "󰲛",
    "tooltip": true,
    "tooltip-format-ethernet": "Network Connected",
    "tooltip-format-disconnected": "Network Disconnected"
  },
  "pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": "",
    "format-icons": {
      "default": ["", "", ""]
    },
    "scroll-step": 1,
    "tooltip": false
  }
},
EOF
cat > /home/"${username}"/.config/waybar/style.css << 'EOF'
* {
  border: none;
  border-radius: 7px;
  font-family: "JetBrainsMono Nerd Font Propo";
  font-size: 13px;
  font-weight: bold;
  min-height: 0;
  padding: 0;
}
window#waybar {
  background: transparent;
  color: transparent;
}
#workspaces {
  background: #14191C;
  color: #CFDFE2;
}
#workspaces button {
  padding: 0px 7.5px 0px 7.5px;
  background: #14191C;
  color: #CFDFE2;
}
#workspaces button:hover {
  background: #14191C;
  color: #D2AF95;
  box-shadow: inherit;
  text-shadow: inherit;
}
#workspaces button.active {
  background: #14191C;
  color: #CFDFE2;
}
#workspaces button.urgent {
  background: #CFDFE2;
  color: #14191C;
}
#clock,
#custom-arch,
#custom-lock,
#custom-restart,
#custom-shutdown,
#custom-sleep,
#custom-weather,
#group-power,
#network,
#pulseaudio {
  padding: 0px 7.5px 0px 7.5px;
  background: #14191C;
  color: #CFDFE2;
}
#custom-weather {
  padding: 4px 7.5px 0px 7.5px;
}
#group-power {
  padding: 0px 3.75px 0px 3.75px;
  background: #14191C;
  color: #CFDFE2;
}
tooltip {
  background: #14191C;
}
tooltip label {
  color: #CFDFE2;
}
EOF
mkdir /home/"${username}"/.config/waybar/scripts
cat > /home/"${username}"/.config/waybar/scripts/get_weather.sh << 'EOF'
#!/usr/bin/env bash
for i in {1..5}; do
  text=$(curl -s "https://wttr.in/$1?format=%c+%t\n")
  if [[ $? == 0 ]]; then
    text=$(echo "$text" | sed -E "s/\s+/ /g")
    tooltip=$(curl -s "https://wttr.in/$1?format=%C,+Feels+Like+%f\n")
    if [[ $? == 0 ]]; then
      tooltip=$(echo "$tooltip" | sed -E "s/\s+/ /g")
      echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
      exit
    fi
  fi
  sleep 2
done
echo "{\"text\":\"error\", \"tooltip\":\"error\"}"
EOF
chmod +x /home/"${username}"/.config/waybar/scripts/get_weather.sh

# Rofi
#entry_status "Installing Rofi"
sudo pacman -S rofi-wayland --noconfirm
#exit_status "Installed Rofi"

# Dolphin
#entry_status "Installing Dolphin"
sudo pacman -S dolphin audiocd-kio baloo dolphin-plugins kio-admin kio-gdrive kompare konsole ffmpegthumbs icoutils kdegraphics-thumbnailers kdesdk-thumbnailers kimageformats libheif libappimage qt6-imageformats taglib --noconfirm
#exit_status "Installed Dolphin"
#entry_status "Installing Dolphin Dependencies"
yay -S kde-thumbnailer-apk raw-thumbnailer resvg --answerclean All --answerdiff None --noconfirm
#exit_status "Installed Dolphin Dependencies"

# Fish
#entry_status "Installing Fish"
sudo pacman -S fish --noconfirm
#exit_status "Installed Fish"

# Display manager
#entry_status "Installing Greetd"
sudo pacman -S greetd greetd-tuigreet --noconfirm
#exit_status "Installed Greetd"
#entry_status "Configuring Greetd"
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet --cmd Hyprland"|g' /etc/greetd/config.toml
#exit_status "Configured Greetd"
#entry_status "Enabling Greetd"
sudo systemctl enable greetd.service
#exit_status "Enabled Greetd"

# Zen Browser
yay -S zen-browser-bin --answerclean All --answerdiff None --noconfirm

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
