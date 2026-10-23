function confirm
  read --prompt-str "$argv[1] [Y/n] " --local answer
  or return 1
  not string match --quiet --regex --ignore-case '^n' -- $answer
end

function upgrade_system
  # Systemd services
  clear
  systemctl --failed
  confirm 'Check if any systemd services have failed. Continue?'
  or return

  # Pacman log
  clear
  confirm 'Look for errors in the pacman log file. Continue?'
  or return
  nvim -R /var/log/pacman.log

  # Systemd journal
  clear
  confirm 'Look for errors in the systemd journal. Continue?'
  or return
  sudo journalctl -b

  # System upgrade
  clear
  confirm 'Upgrade the system?'
  or return
  if not sudo informant check
    sudo informant read
    or return
  end
  clear
  sudo pacman --sync --refresh --sysupgrade
  or return

  # Upgrade AUR packages
  clear
  if confirm 'Upgrade AUR packages?'
    paru --sync --sysupgrade --aur
  end

  # Check for orphans and dropped packages
  clear
  set -l orphans (pacman --query --deps --unrequired --quiet)
  if test (count $orphans) -gt 0
    printf '%s\n' $orphans
    sudo pacman --remove --nosave --recursive $orphans
  end

  # Package cache
  clear
  if confirm 'Clean the package cache?'
    sudo paccache --remove
  end

  # Reboot
  clear
  if confirm 'Reboot?'
    systemctl reboot
  end
end
