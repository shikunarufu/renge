#!/bin/bash

# Spotify Song Information for Hyprlock

song_info="$(playerctl metadata --format '{{title}}' --follow)"
echo "${song_info}"
