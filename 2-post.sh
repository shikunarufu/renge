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
# Refer to the wiki for more information.
# https://wiki.hypr.land/Configuring/

# Monitors
monitor = , 1920x1080@180, 0x0, 1
#monitor = , preferred, auto, auto

# Programs
# See https://wiki.hypr.land/Configuring/Keywords/
# Set programs that you use
$terminal = foot
$fileManager = dolphin
$menu = rofi -show drun -show-icons

# Autostart
# Autostart necessary processes (like notifications daemons, status bars, etc.)
# Or execute your favorite apps at launch like this:
# exec-once = $terminal
# exec-once = nm-applet &
# exec-once = waybar & hyprpaper & firefox
#exec-once = hyprpaper
exec-once = waybar

# Environment Variables
# See https://wiki.hypr.land/Configuring/Environment-variables/
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24

# Permissions
# See https://wiki.hypr.land/Configuring/Permissions/
# Please note permission changes here require a Hyprland restart and are not applied on-the-fly for security reasons
# ecosystem {
#   enforce_permissions = 1
# }
# permission = /usr/(bin|local/bin)/grim, screencopy, allow
# permission = /usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland, screencopy, allow
# permission = /usr/(bin|local/bin)/hyprpm, plugin, allow

# Look And Feel
# Refer to https://wiki.hypr.land/Configuring/Variables/
# https://wiki.hypr.land/Configuring/Variables/#general
general {
    gaps_in = 3
    gaps_out = 6

    border_size = 0

    # https://wiki.hypr.land/Configuring/Variables/#variable-types for info about colors
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    # Set to true enable resizing windows by clicking and dragging on borders and gaps
    resize_on_border = false

    # Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
    allow_tearing = false

    layout = dwindle
}
# https://wiki.hypr.land/Configuring/Variables/#decoration
decoration {
    rounding = 10
    rounding_power = 2

    # Change transparency of focused and unfocused windows
    active_opacity = 1.0
    inactive_opacity = 1.0

    shadow {
        enabled = true
        range = 4
        render_power = 3
        color = rgba(1a1a1aee)
    }

    # https://wiki.hypr.land/Configuring/Variables/#blur
    blur {
        enabled = true
        size = 3
        passes = 1

        vibrancy = 0.1696
    }
}
# https://wiki.hypr.land/Configuring/Variables/#animations
animations {
    enabled = yes, please :)

    # Default animations, see https://wiki.hypr.land/Configuring/Animations/ for more

    bezier = easeOutQuint,0.23,1,0.32,1
    bezier = easeInOutCubic,0.65,0.05,0.36,1
    bezier = linear,0,0,1,1
    bezier = almostLinear,0.5,0.5,0.75,1.0
    bezier = quick,0.15,0,0.1,1

    animation = global, 1, 10, default
    animation = border, 1, 5.39, easeOutQuint
    animation = windows, 1, 4.79, easeOutQuint
    animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
    animation = windowsOut, 1, 1.49, linear, popin 87%
    animation = fadeIn, 1, 1.73, almostLinear
    animation = fadeOut, 1, 1.46, almostLinear
    animation = fade, 1, 3.03, quick
    animation = layers, 1, 3.81, easeOutQuint
    animation = layersIn, 1, 4, easeOutQuint, fade
    animation = layersOut, 1, 1.5, linear, fade
    animation = fadeLayersIn, 1, 1.79, almostLinear
    animation = fadeLayersOut, 1, 1.39, almostLinear
    animation = workspaces, 1, 1.94, almostLinear, fade
    animation = workspacesIn, 1, 1.21, almostLinear, fade
    animation = workspacesOut, 1, 1.94, almostLinear, fade
    animation = zoomFactor, 1, 7, quick
}
# Ref https://wiki.hypr.land/Configuring/Workspace-Rules/
# "Smart gaps" / "No gaps when only"
# uncomment all if you wish to use that.
# workspace = w[tv1], gapsout:0, gapsin:0
# workspace = f[1], gapsout:0, gapsin:0
# windowrule = bordersize 0, floating:0, onworkspace:w[tv1]
# windowrule = rounding 0, floating:0, onworkspace:w[tv1]
# windowrule = bordersize 0, floating:0, onworkspace:f[1]
# windowrule = rounding 0, floating:0, onworkspace:f[1]
# See https://wiki.hypr.land/Configuring/Dwindle-Layout/ for more
dwindle {
    pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = true # You probably want this
}
# See https://wiki.hypr.land/Configuring/Master-Layout/ for more
master {
    new_status = master
}
# https://wiki.hypr.land/Configuring/Variables/#misc
misc {
    force_default_wallpaper = -1 # Set to 0 or 1 to disable the anime mascot wallpapers
    disable_hyprland_logo = false # If true disables the random hyprland logo / anime girl background. :(
}

# Input
# https://wiki.hypr.land/Configuring/Variables/#input
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1

    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

    touchpad {
        natural_scroll = false
    }
}
# https://wiki.hypr.land/Configuring/Variables/#gestures
gestures {
    workspace_swipe = false
}
# Example per-device config
# See https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs for more
device {
    name = epic-mouse-v1
    sensitivity = -0.5
}

# Keybindings
# See https://wiki.hypr.land/Configuring/Keywords/
$mainMod = SUPER # Sets "Windows" key as main modifier
# Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more
bind = $mainMod, Q, exec, $terminal
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, $menu
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle
# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d
# Switch workspaces with mainMod + [0-9]
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
# Move active window to a workspace with mainMod + SHIFT + [0-9]
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
# Example special workspace (scratchpad)
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic
# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1
# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
# Laptop multimedia keys for volume and LCD brightness
bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindel = ,XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+
bindel = ,XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-
# Requires playerctl
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPause, exec, playerctl play-pause
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioPrev, exec, playerctl previous

# Windows And Workspaces
# See https://wiki.hypr.land/Configuring/Window-Rules/ for more
# See https://wiki.hypr.land/Configuring/Workspace-Rules/ for workspace rules
# Example windowrule
# windowrule = float,class:^(kitty)$,title:^(kitty)$
# Ignore maximize requests from apps. You'll probably like this.
windowrule = suppressevent maximize, class:.*
# Fix some dragging issues with XWayland
windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0
EOF
#exit_status "Configured Hyprland"
#entry_status "Installing Hyprpaper"
sudo pacman -S hyprpaper --noconfirm
#exit_status "Installed Hyprpaper"
#entry_status "Configuring Hyprpaper"
mkdir /home/"${username}"/Pictures/Wallpapers
cat > /home/"${username}"/.config/hypr/hyprpaper.conf << EOF
preload = /home/"${username}"/Pictures/Wallpapers/Desktop.png
wallpaper = /home/"${username}"/Pictures/Wallpapers/Desktop.png
EOF
#exit_status "Configured Hyprpaper"

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
    "height": 24,
    "modules-left": [
        "clock",
        "clock#date",
        "custom/media",
    ],
    "modules-center": [
        "hyprland/workspaces",
    ],
    "modules-right": [
        "pulseaudio",
        "network",
        "custom/power",
    ],
    "margin-top": 6,
    "margin-left": 6,
    "margin-right": 6,
    "spacing": 6,

    // Module Configuration
    "clock": {
        "interval": "60",
        "format": " {:%H:%M}",
        "tooltip": false,
    },
    "clock#date": {
        "interval": "60",
        "format": " {:%a %b %d}",
        "tooltip": false,
    },
    "hyprland/workspaces": {
        "active-only": "false",
        "hide-active": "false",
        "all-outputs": "false",
        "format-icons": {
            "active": "",
            "default": "",
        },
    },
    "network": {
        "interval": "60",
        "family": "ipv4_6",
        "format-ethernet": "󰛳 Ethernet",
        "format-linked": "󰛵 No IP Address",
        "format-disconnected": "󰲛 Disconnected",
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": {
            "alsa_output.pci-0000_00_1f.3.analog-stereo": "",
            "alsa_output.pci-0000_00_1f.3.analog-stereo-muted": "",
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "phone-muted": "",
            "portable": "",
            "car": "",
            "default": ["", ""]
        },
        "scroll-step": 1,
        "on-click": "pavucontrol",
        "ignored-sinks": ["Easy Effects Sink"]
    },
    "custom/media": {
        "format": "{icon} {text}",
        "return-type": "json",
        "max-length": 40,
        "format-icons": {
            "spotify": "",
            "default": "🎜"
        },
        "escape": true,
        "exec": "$HOME/.config/waybar/mediaplayer.py 2> /dev/null" // Script in resources folder
        // "exec": "$HOME/.config/waybar/mediaplayer.py --player spotify 2> /dev/null" // Filter player based on name
    },
    "custom/power": {
        "format" : "󰣇",
		"tooltip": false,
		"menu": "on-click",
		"menu-file": "$HOME/.config/waybar/power_menu.xml", // Menu file in resources folder
		"menu-actions": {
			"shutdown": "shutdown",
			"reboot": "reboot",
			"suspend": "systemctl suspend",
			"hibernate": "systemctl hibernate"
		}
    }
}
EOF
cat > /home/"${username}"/.config/waybar/style.css << 'EOF'
* {
    /* `otf-font-awesome` is required to be installed for icons */
    font-family: "JetBrainsMono Nerd Font Propo";
    font-size: 13px;
    font-weight: bold;
    border-radius: 6px;
}

window#waybar {
    background-color: transparent;
    color: #ffffff;
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}



button {
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px transparent;
    /* Avoid rounded borders under each button name */
    border: none;
    border-radius: 0;
}

/* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
button:hover {
    background: inherit;
    box-shadow: inset 0 -3px #ffffff;
}

/* you can set a style on hover for any module like this */
#pulseaudio:hover {
    background-color: #a37800;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #ffffff;
}

#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
}

#workspaces button.focused {
    background-color: #64727D;
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}

#mode {
    background-color: #64727D;
    box-shadow: inset 0 -3px #ffffff;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#scratchpad,
#power-profiles-daemon,
#mpd {
    padding: 0 11px;
    color: #ffffff;
}

#window,
#workspaces {
    margin: 0 4px;
}

/* If workspaces is the leftmost module, omit left margin */
.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

/* If workspaces is the rightmost module, omit right margin */
.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#clock {
    background: rgba(0, 0, 0, 0.5);
}

#battery {
    background-color: #ffffff;
    color: #000000;
}

#battery.charging, #battery.plugged {
    color: #ffffff;
    background-color: #26A65B;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

/* Using steps() instead of linear as a timing function to limit cpu usage */
#battery.critical:not(.charging) {
    background-color: #f53c3c;
    color: #ffffff;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(12);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#power-profiles-daemon {
    padding-right: 15px;
}

#power-profiles-daemon.performance {
    background-color: #f53c3c;
    color: #ffffff;
}

#power-profiles-daemon.balanced {
    background-color: #2980b9;
    color: #ffffff;
}

#power-profiles-daemon.power-saver {
    background-color: #2ecc71;
    color: #000000;
}

label:focus {
    background-color: #000000;
}

#cpu {
    background-color: #2ecc71;
    color: #000000;
}

#memory {
    background-color: #9b59b6;
}

#disk {
    background-color: #964B00;
}

#backlight {
    background-color: #90b1b1;
}

#network {
    background: rgba(0, 0, 0, 0.2);
}

#network.disconnected {
    background: rgba(0, 0, 0, 0.2);
}

#pulseaudio {
    background-color: #f1c40f;
    color: #000000;
}

#pulseaudio.muted {
    background-color: #90b1b1;
    color: #2a5c45;
}

#wireplumber {
    background-color: #fff0f5;
    color: #000000;
}

#wireplumber.muted {
    background-color: #f53c3c;
}

#custom-media {
    background-color: #66cc99;
    color: #2a5c45;
    min-width: 100px;
}

#custom-media.custom-spotify {
    background-color: #66cc99;
}

#custom-media.custom-vlc {
    background-color: #ffa000;
}

#temperature {
    background-color: #f0932b;
}

#temperature.critical {
    background-color: #eb4d4b;
}

#tray {
    background-color: #2980b9;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #eb4d4b;
}

#idle_inhibitor {
    background-color: #2d3436;
}

#idle_inhibitor.activated {
    background-color: #ecf0f1;
    color: #2d3436;
}

#mpd {
    background-color: #66cc99;
    color: #2a5c45;
}

#mpd.disconnected {
    background-color: #f53c3c;
}

#mpd.stopped {
    background-color: #90b1b1;
}

#mpd.paused {
    background-color: #51a37a;
}

#language {
    background: #00b093;
    color: #740864;
    padding: 0 5px;
    margin: 0 5px;
    min-width: 16px;
}

#keyboard-state {
    background: #97e1ad;
    color: #000000;
    padding: 0 0px;
    margin: 0 5px;
    min-width: 16px;
}

#keyboard-state > label {
    padding: 0 5px;
}

#keyboard-state > label.locked {
    background: rgba(0, 0, 0, 0.2);
}

#scratchpad {
    background: rgba(0, 0, 0, 0.2);
}

#scratchpad.empty {
	background-color: transparent;
}

#privacy {
    padding: 0;
}

#privacy-item {
    padding: 0 5px;
    color: white;
}

#privacy-item.screenshare {
    background-color: #cf5700;
}

#privacy-item.audio-in {
    background-color: #1ca000;
}

#privacy-item.audio-out {
    background-color: #0069d4;
}
EOF

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
