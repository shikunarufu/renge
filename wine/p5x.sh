#!/bin/bash
#
# Wine Setup for Persona 5: The Phantom X

mkdir --parents /home/Shiku/Wine/Games/Persona5ThePhantomX
# WINEPREFIX="/home/Shiku/Wine/Games/Persona5ThePhantomX" winecfg
env WINEPREFIX="/home/Shiku/Wine/Games/Persona5ThePhantomX" wineboot -u
WINEPREFIX="/home/Shiku/Wine/Games/Persona5ThePhantomX" winetricks --force --unattended vcrun2022 corefonts dxvk vkd3d
# cd /home/Shiku
# git clone https://github.com/doitsujin/dxvk.git
# cd dxvk
# ./package-release.sh master . --no-package
# cd dxvk-master
# WINEPREFIX="/home/Shiku/Wine/Games/Persona5ThePhantomX" ./setup_dxvk.sh install
WINEPREFIX="/home/Shiku/Wine/Games/Persona5ThePhantomX" wine /home/Shiku/Downloads/P5X-SEA_GAT_common_setup.exe

env WINEPREFIX="~/.wine" wineboot -u
