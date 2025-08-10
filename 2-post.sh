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
yay -S ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender libxcursor pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git aquamarine-git re2 hyprland-qtutils --answerclean All --answerdiff None --noconfirm > /dev/null 2>&1
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
mkdir /home/"${username}"/.config/hypr
cat > /home/"${username}"/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Config File

# Monitors
monitor = , 1920x1080@180, 0x0, 1
#monitor = , preferred, auto, auto

# Programs
$terminal = foot
$fileManager = dolphin
$menu = rofi -show drun

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
  gaps_in = 3
  gaps_out = 6
  layout = dwindle
  resize_on_border = false
  allow_tearing = false
}
decoration {
  rounding = 6
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
exit_status "Configured Hyprland"
entry_status "Installing SWWW"
yay -S swww --answerclean All --answerdiff None --noconfirm > /dev/null 2>&1
exit_status "Installed SWWW"
entry_status "Configuring SWWW"
mkdir /home/"${username}"/Pictures/Wallpapers
cp /home/"${username}"/ALIS/Desktop.png /home/"${username}"/Pictures/Wallpapers
exit_status "Configured SWWW"

# Foot
entry_status "Installing Foot"
sudo pacman -S foot foot-terminfo libnotify xdg-utils --noconfirm > /dev/null 2>&1
exit_status "Installed Foot"
entry_status "Configuring Foot"
mkdir /home/"${username}"/.config/foot
cat > /home/"${username}"/.config/foot/foot.ini << 'EOF'
# -*- conf -*-

shell=fish
title=foot
font=GeistMono Nerd Font:size=10
letter-spacing=0
dpi-aware=no
gamma-correct-blending=no
pad=25x25
bold-text-in-bright=no

[scrollback]
lines=10000

[cursor]
style=beam
blink=yes
blink-rate=500
beam-thickness=1.5
# underline-thickness=<font underline thickness>

[mouse]
hide-when-typing=yes

[colors]
alpha=0.8

[key-bindings]
scrollback-up-page=Page_Up
scrollback-down-page=Page_Down
# search-start=Control+Shift+r

[search-bindings]
cancel=Escape
# find-prev=Control+r
# find-next=Control+s
EOF
exit_status "Configured Foot"

# Waybar
entry_status "Installing Waybar"
sudo pacman -S waybar --noconfirm > /dev/null 2>&1
exit_status "Installed Waybar"
entry_status "Configuring Waybar"
mkdir /home/"${username}"/.config/waybar
cat > /home/"${username}"/.config/waybar/config.jsonc << 'EOF'
// Waybar Configuration File
{
  // Bar Configuration
  "layer": "bottom",
  "position": "top",
  "height": 24,
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
  "margin-top": 6,
  "margin-left": 6,
  "margin-right": 6,
  "spacing": 6,
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
    "tooltip": true,
    "tooltip-format": "Arch Linux"
  },
  "custom/lock": {
    "format": "",
    "on-click": "hyprctl dispatch exec exit",
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
    "on-click": "systemctl hybrid-sleep",
    "tooltip": true,
    "tooltip-format": "Sleep"
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
  border-radius: 6px;
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
  padding: 0px 5.5px 0px 5.5px;
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
#group-power,
#network,
#pulseaudio {
  padding: 0px 7px 0px 7px;
  background: #14191C;
  color: #CFDFE2;
}
#custom-arch,
#custom-lock,
#custom-restart,
#custom-shutdown,
#custom-sleep {
  padding: 0px 5.5px 0px 5.5px;
  background: #14191C;
  color: #CFDFE2;
}
#group-power {
  padding: 0px 2.75px 0px 2.75px;
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
exit_status "Configured Waybar"

# Rofi
entry_status "Installing Rofi"
sudo pacman -S rofi-wayland --noconfirm > /dev/null 2>&1
exit_status "Installed Rofi"
entry_status "Configuring Rofi"
mkdir /home/"${username}"/.config/rofi
cat > /home/"${username}"/.config/rofi/config.rasi << 'EOF'
configuration {
	modi: "drun";
  show-icons: true;
	drun-display-format: "{name}";
}
@theme "default"
* {
  font: "JetBrainsMono Nerd Font Propo 10";
  background: #14191C;
  background-alt: #14191C;
  foreground: #CFDFE2;
  foreground-alt: #14191C;
  selected: #CFDFE2;
  active: #909090;
  urgent: #707070;
}
window {
  transparency: "real";
  location: center;
  anchor: center;
  fullscreen: false;
  width: 960px;
  x-offset: 0px;
  y-offset: 0px;
  border: 0px;
  enabled: true;
  border-radius: 6px;
  cursor: "default";
  padding: 0px;
  background-color: @background;
}
mainbox {
  enabled: true;
  spacing: 0px;
  background-color: transparent;
  orientation: horizontal;
  children: [ "imagebox", "listbox" ];
}
imagebox {
  padding: 12px;
  background-color: transparent;
  background-image: url("~/Pictures/Wallpapers/Desktop.png", height);
  orientation: vertical;
  children: [ "inputbar", "dummy" ];
}
listbox {
  spacing: 12px;
  padding: 12px;
  background-color: transparent;
  orientation: vertical;
  children: [ "message", "listview" ];
}
dummy {
  background-color: transparent;
}
inputbar {
  enabled: true;
  spacing: 0px;
  padding: 12px;
  border-radius: 6px;
  background-color: @background-alt;
  text-color: @foreground;
  children: [ "textbox-prompt-colon", "entry" ];
}
textbox-prompt-colon {
  enabled: true;
  expand: false;
  str: " ";
  background-color: inherit;
  text-color: inherit;
}
entry {
  enabled: true;
  background-color: inherit;
  text-color: inherit;
  cursor: text;
  placeholder: "Search";
  placeholder-color: inherit;
}
listview {
  enabled: true;
  columns: 1;
  lines: 8;
  cycle: true;
  dynamic: true;
  scrollbar: false;
  layout: vertical;
  reverse: false;
  fixed-height: true;
  fixed-columns: true;
  border: 0px;
  spacing: 12px;
  padding: 0px;
  background-color: transparent;
  text-color: @foreground;
  cursor: "default";
}
element {
  enabled: true;
  spacing: 12px;
  padding: 5px;
  border-radius: 6px;
  background-color: transparent;
  text-color: @foreground;
  cursor: pointer;
}
element normal.normal {
  background-color: inherit;
  text-color: inherit;
}
element normal.urgent {
  background-color: @urgent;
  text-color: @foreground;
}
element normal.active {
  background-color: @active;
  text-color: @foreground;
}
element selected.normal {
  background-color: @selected;
  text-color: @foreground-alt;
}
element selected.urgent {
  background-color: @urgent;
  text-color: @foreground-alt;
}
element selected.active {
  background-color: @urgent;
  text-color: @foreground-alt;
}
element.alternate.normal {
  background-color: inherit;
  text-color: inherit;
}
element.alternate.urgent {
  background-color: @urgent;
  text-color: @foreground;
}
element.alternate.active {
  background-color: @active;
  text-color: @foreground;
}
element-icon {
  background-color: transparent;
  text-color: inherit;
  size: 32px;
  cursor: inherit;
}
element-text {
  background-color: transparent;
  text-color: inherit;
  cursor: inherit;
  vertical-align: 0.5;
  horizontal-align: 0.0;
}
EOF
exit_status "Configured Rofi"

# Dolphin
entry_status "Installing Dolphin"
sudo pacman -S dolphin audiocd-kio baloo dolphin-plugins kio-admin kio-gdrive kompare ffmpegthumbs icoutils kdegraphics-thumbnailers kdesdk-thumbnailers kimageformats libheif libappimage qt6-imageformats taglib --noconfirm > /dev/null 2>&1
exit_status "Installed Dolphin"
entry_status "Installing Dolphin Dependencies"
yay -S kde-thumbnailer-apk raw-thumbnailer resvg --answerclean All --answerdiff None --noconfirm > /dev/null 2>&1
exit_status "Installed Dolphin Dependencies"

# Fish
entry_status "Installing Fish"
sudo pacman -S fish --noconfirm > /dev/null 2>&1
exit_status "Installed Fish"
entry_status "Configuring Fish"
mkdir /home/"${username}"/.config/fish
mkdir /home/"${username}"/.config/fish/functions
cat > /home/"${username}"/.config/fish/config.fish << 'EOF'
if status is-interactive
  starship init fish | source
end
EOF
cat > /home/"${username}"/.config/fish/functions/fish_greeting.fish << 'EOF'
function fish_greeting
  switch (random 1 5)
    case 1
      echo "Shimmy Shimmy Yay, Shimmy Yay, Shimmy Yaaa~ (Drank) Swalla'la'la"
    case 2
      echo "Uh, sama lamaa duma lamaa, you assuming I'm a human What I gotta do to get it through to you I'm superhuman Innovative and I'm made of rubber So that anything you say is ricocheting off of me and-"
    case 3
      echo "What's this smell? wut da heeeeeeeell oh my god no waaaaayy"
    case 4
      echo "Super idol 的笑容都没你的甜八月正午的阳光都没你耀眼热爱105度的你滴滴清纯的蒸馏水"
    case 5
      echo "近前看其牆上寫著秦香蓮年三十二歲那狀告當朝駙馬郎欺君王瞞皇上"
  end
  echo ""
end
EOF
exit_status "Configured Fish"

# Starship
entry_status "Installing Starship"
sudo pacman -S starship --noconfirm > /dev/null 2>&1
exit_status "Installed Starship"
entry_status "Configuring Starship"
cat > /home/"${username}"/.config/starship.toml << 'EOF'
# ~/.config/starship.toml

format = """($nix_shell$container$git_metrics\n)$cmd_duration\
$hostname\
$localip\
$shlvl\
$shell\
$env_var\
$jobs\
$sudo\
$username\
$character"""

right_format = """
$singularity\
$kubernetes\
$directory\
$vcsh\
$fossil_branch\
$git_branch\
$git_commit\
$git_state\
$git_status\
$hg_branch\
$pijul_channel\
$docker_context\
$package\
$c\
$cpp\
$cmake\
$cobol\
$daml\
$dart\
$deno\
$dotnet\
$elixir\
$elm\
$erlang\
$fennel\
$golang\
$guix_shell\
$haskell\
$haxe\
$helm\
$java\
$julia\
$kotlin\
$gradle\
$lua\
$nim\
$nodejs\
$ocaml\
$opa\
$perl\
$php\
$pulumi\
$purescript\
$python\
$raku\
$rlang\
$red\
$ruby\
$rust\
$scala\
$solidity\
$swift\
$terraform\
$vlang\
$vagrant\
$zig\
$buf\
$conda\
$pixi\
$meson\
$spack\
$memory_usage\
$aws\
$gcloud\
$openstack\
$azure\
$crystal\
$custom\
$status\
$os\
$battery\
$time"""

add_newline = false
continuation_prompt = "[▸▹ ](dimmed white)"

[aws]
format = '\[[$symbol($profile)(\($region\))(\[$duration\])]($style)\]'

[bun]
format = '\[[$symbol($version)]($style)\]'

[c]
format = '\[[$symbol($version(-$name))]($style)\]'

[cpp]
format = '\[[$symbol($version(-$name))]($style)\]'

[cmake]
format = '\[[$symbol($version)]($style)\]'

[cmd_duration]
format = '\[[  $duration]($style)\] '

[cobol]
format = '\[[$symbol($version)]($style)\]'

[conda]
format = '\[[$symbol$environment]($style)\]'

[crystal]
format = '\[[$symbol($version)]($style)\]'

[daml]
format = '\[[$symbol($version)]($style)\]'

[dart]
format = '\[[$symbol($version)]($style)\]'

[deno]
format = '\[[$symbol($version)]($style)\]'

[docker_context]
format = '\[[$symbol$context]($style)\]'

[dotnet]
format = '\[[$symbol($version)(🎯 $tfm)]($style)\]'

[elixir]
format = '\[[$symbol($version \(OTP $otp_version\))]($style)\]'

[elm]
format = '\[[$symbol($version)]($style)\]'

[erlang]
format = '\[[$symbol($version)]($style)\]'

[fennel]
format = '\[[$symbol($version)]($style)\]'

[fossil_branch]
format = '\[[$symbol$branch]($style)\]'

[gcloud]
format = '\[[$symbol$account(@$domain)(\($region\))]($style)\]'

[git_branch]
format = '\[[$symbol$branch]($style)\]'

[git_status]
format = '([\[$all_status$ahead_behind\]]($style))'

[golang]
format = '\[[$symbol($version)]($style)\]'

[gradle]
format = '\[[$symbol($version)]($style)\]'

[guix_shell]
format = '\[[$symbol]($style)\]'

[haskell]
format = '\[[$symbol($version)]($style)\]'

[haxe]
format = '\[[$symbol($version)]($style)\]'

[helm]
format = '\[[$symbol($version)]($style)\]'

[hg_branch]
format = '\[[$symbol$branch]($style)\]'

[java]
format = '\[[$symbol($version)]($style)\]'

[julia]
format = '\[[$symbol($version)]($style)\]'

[kotlin]
format = '\[[$symbol($version)]($style)\]'

[kubernetes]
format = '\[[$symbol$context( \($namespace\))]($style)\]'

[lua]
format = '\[[$symbol($version)]($style)\]'

[memory_usage]
format = '\[$symbol[$ram( | $swap)]($style)\]'

[meson]
format = '\[[$symbol$project]($style)\]'

[nim]
format = '\[[$symbol($version)]($style)\]'

[nix_shell]
format = '\[[$symbol$state( \($name\))]($style)\]'

[nodejs]
format = '\[[$symbol($version)]($style)\]'

[ocaml]
format = '\[[$symbol($version)(\($switch_indicator$switch_name\))]($style)\]'

[opa]
format = '\[[$symbol($version)]($style)\]'

[openstack]
format = '\[[$symbol$cloud(\($project\))]($style)\]'

[os]
format = '\[[$symbol]($style)\]'

[package]
format = '\[[$symbol$version]($style)\]'

[perl]
format = '\[[$symbol($version)]($style)\]'

[php]
format = '\[[$symbol($version)]($style)\]'

[pijul_channel]
format = '\[[$symbol$channel]($style)\]'

[pixi]
format = '\[[$symbol$version( $environment)]($style)\]'

[pulumi]
format = '\[[$symbol$stack]($style)\]'

[purescript]
format = '\[[$symbol($version)]($style)\]'

[python]
format = '\[[${symbol}${pyenv_prefix}(${version})(\($virtualenv\))]($style)\]'

[raku]
format = '\[[$symbol($version-$vm_version)]($style)\]'

[red]
format = '\[[$symbol($version)]($style)\]'

[ruby]
format = '\[[$symbol($version)]($style)\]'

[rust]
format = '\[[$symbol($version)]($style)\]'

[scala]
format = '\[[$symbol($version)]($style)\]'

[spack]
format = '\[[$symbol$environment]($style)\]'

[sudo]
format = '\[[as $symbol]($style)\]'

[swift]
format = '\[[$symbol($version)]($style)\]'

[terraform]
format = '\[[$symbol$workspace]($style)\]'

[time]
format = '\[[$time]($style)\]'

[username]
format = '\[[$user]($style)\]'

[vagrant]
format = '\[[$symbol($version)]($style)\]'

[vlang]
format = '\[[$symbol($version)]($style)\]'

[zig]
format = '\[[$symbol($version)]($style)\]'

[solidity]
format = '\[[$symbol($version)]($style)\]'

[line_break]
disabled = true
EOF
exit_status "Configured Starship"

# Fastfetch
entry_status "Installing Fastfetch"
sudo pacman -S fastfetch --noconfirm > /dev/null 2>&1
exit_status "Installed Fastfetch"
entry_status "Configuring Fastfetch"
mkdir /home/"${username}"/.config/fastfetch
cat > /home/"${username}"/.config/fastfetch/config.jsonc << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "auto",
    "source": "arch",
    "width": 35,
    "height": 35,
    "padding": {
      "top": 0,
      "left": 0,
      "right": 2
    },
    "color": {
      "1": "\u001b[38;2;177;204;211m",
      "2": "\u001b[38;2;177;204;211m"
    }
  },
  "display": {
    "separator": ": ",
    "color": {
      "keys": "\u001b[38;2;177;204;211m",
      "title": "\u001b[38;2;210;175;149m"
    },
    "key": {
      "type": "string"
    }
  },
  "modules": [
    {
      "type": "custom",
      "key": " ",
      "format": "╭─────────────────────── Hardware ───────────────────────╮"
    },
    {
      "type": "cpu",
      "key": "  CPU"
    },
    {
      "type": "custom",
      "key": "  Cooler",
      "format": "Thermalright Peerless Assassin 120 Black"
    },
    {
      "type": "board",
      "key": "  Board"
    },
    {
      "type": "custom",
      "key": "  RAM",
      "format": "G.Skill Ripjaws V 16 GB (2 x 8 GB) DDR4-3200 CL16"
    },
    {
      "type": "custom",
      "key": "  SSD",
      "format": "Kingston A400 120 GB M.2-2280 SATA"
    },
    {
      "type": "custom",
      "key": "  HDD",
      "format": "Seagate BarraCuda 1 TB 3.5\" 7200 RPM"
    },
    {
      "type": "gpu",
      "key": "  GPU"
    },
    {
      "type": "custom",
      "key": "  Case",
      "format": "NZXT H510i ATX Mid Tower"
    },
    {
      "type": "custom",
      "key": "  PSU",
      "format": "Corsair CV450 450 W 80+ Bronze Certified ATX"
    },
    {
      "type": "monitor",
      "key": "  Monitor"
    },
    {
      "type": "custom",
      "key": " ",
      "format": "╰────────────────────────────────────────────────────────╯"
    },
    {
      "type": "custom",
      "key": " ",
      "format": "╭─────────────────────── Software ───────────────────────╮"
    },
    {
      "type": "os",
      "key": "  OS"
    },
    {
      "type": "kernel",
      "key": "  Kernel"
    },
    {
      "type": "packages",
      "key": "  Packages"
    },
    {
      "type": "shell",
      "key": "  Shell"
    },
    {
      "type": "terminal",
      "key": "  Terminal"
    },
    {
      "type": "wm",
      "key": "  WM"
    },
    {
      "type": "lm",
      "key": "  LM"
    },
    {
      "type": "uptime",
      "key": "  Uptime"
    },
    {
      "type": "colors",
      "paddingLeft": 2,
      "symbol": "circle"
    },
    {
      "type": "custom",
      "key": " ",
      "format": "╰────────────────────────────────────────────────────────╯"
    }
  ]
}
EOF
exit_status "Configured Fastfetch"

# Display manager
entry_status "Installing Greetd"
sudo pacman -S greetd greetd-tuigreet --noconfirm > /dev/null 2>&1
exit_status "Installed Greetd"
entry_status "Configuring Greetd"
sudo sed --in-place 's|command = "agreety --cmd /bin/sh"|command = "tuigreet --cmd Hyprland --remember"|g' /etc/greetd/config.toml
exit_status "Configured Greetd"
entry_status "Enabling Greetd"
sudo systemctl enable greetd.service > /dev/null 2>&1
exit_status "Enabled Greetd"

# Spotify
entry_status "Installing Spotify"
yay -S spotify --answerclean All --answerdiff None --noconfirm > /dev/null 2>&1
exit_status "Installed Spotify"
entry_status "Installing Spotify Dependencies"
sudo pacman -S ffmpeg4.4 libnotify zenity --noconfirm > /dev/null 2>&1
exit_status "Installed Spotify Dependencies"
entry_status "Configuring Spotify"
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
exit_status "Configured Spotify"

# SpotX
entry_status "Applying SpotX"
bash <(curl -sSL https://spotx-official.github.io/run.sh) > /dev/null 2>&1
exit_status "Applied SpotX"

# Spicetify
entry_status "Installing Spicetify"
yay -S spicetify-cli --answerclean All --answerdiff None --noconfirm > /dev/null 2>&1
exit_status "Installed Spicetify"

cat > /home/"${username}"/.config/spicetify/user.css << 'EOF'
/* Background buttons, main play/pause button and progress bar */
.encore-bright-accent-set,
.encore-inverted-light-set,
.x-progressBar-fillColor {
    background-color: var(--spice-button-active) !important;
}

/* Left sidebar search button */
.x-filterBox-expandButton {
    border-radius: 1000px !important;
}

/* Queue and recently played right sidebar buttons */
.encore-text-body-small-bold {
    border-radius: 10px !important;
}

/* Hover animations for buttons, tracklist and context menu */
button,
.main-trackList-trackListRow,
.main-contextMenu-menuItemButton {
    transition: color 200ms cubic-bezier(0, 0.55, 0.45, 1), background-color 200ms cubic-bezier(0, 0.55, 0.45, 1) !important;
}

/* Search bar and dropdown */
.main-topBar-searchBar,
#recent-searches-dropdown > div {
    background-color: var(--spice-main-elevated) !important;
}

/* Hide the main header on the home page */
.main-home-homeHeader {
  display: none !important;
}

/* Remove any decorative pseudo-elements inside the home header */
.search-searchCategory-contentArea::before,
.search-searchCategory-contentArea::after {
  display: none !important;
  content: none !important;
}

/* Hide the gradient background bar that appears between the playlist/album header and the song list */
.main-actionBarBackground-background {
  display: none !important;
}

.main-view-container__scroll-node-child div[style*="--background-base"]:not([style*="--background-base-min-contrast"]) {
  display: none !important;
}
EOF

# VSCodium
entry_status "Installing VSCodium"
yay -S vscodium-bin --answerclean All --answerdiff None --noconfirm > /dev/null 2>&1
exit_status "Installed VSCodium"

# Zen Browser
entry_status "Installing Zen Browser"
yay -S zen-browser-bin --answerclean All --answerdiff None --noconfirm > /dev/null 2>&1
exit_status "Installed Zen Browser"

# Vesktop
entry_status "Installing Vesktop"
yay -S vesktop --answerclean All --answerdiff None --noconfirm > /dev/null 2>&1
exit_status "Installed Vesktop"

# Steam
entry_status "Installing Steam"
sudo pacman -S steam --noconfirm > /dev/null 2>&1
exit_status "Installed Steam"

#######################################
# Post-Installation
#######################################

# Clean
# entry_status "Removing Files From Cache And Unused Repositories"
# yay -Scc --noconfirm
# exit_status "Removed Files From Cache And Unused Repositories"

# Allow members of group wheel sudo access with a password
entry_status "Allowing Sudo Access With Password"
sudo sed --in-place 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
exit_status "Allowed Sudo Access Without Password"

# Launch Hyprland
entry_status "Launching Hyprland"
Hyprland > /dev/null 2>&1
exit_status "Launched Hyprland"

# swww img /home/"${username}"/Pictures/Wallpapers/Desktop.png
