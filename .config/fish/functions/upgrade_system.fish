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

  # Rank mirrors
  clear
  if confirm 'Rank mirrors?'
    set -l country (curl --fail --silent --max-time 5 --ipv4 ifconfig.io/country_code)
    set -l country_args
    if test -n "$country"
      set country_args --entry-country=$country
    end

    sudo rate-mirrors --save=/etc/pacman.d/mirrorlist --max-jumps=0 \
      $country_args --allow-root arch
    or printf '%s\n' 'Warning: mirror ranking failed; keeping current mirrorlist.' >&2

    if not systemd-detect-virt --quiet --vm
      sudo rate-mirrors --save=/etc/pacman.d/cachyos-mirrorlist --max-jumps=0 \
        $country_args --allow-root cachyos
      or printf '%s\n' 'Warning: CachyOS mirror ranking failed.' >&2
      sudo cp --force /etc/pacman.d/cachyos-mirrorlist /etc/pacman.d/cachyos-v3-mirrorlist
      sudo sed --in-place 's|/$arch/|/$arch_v3/|g' /etc/pacman.d/cachyos-v3-mirrorlist
    end
  end

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

  # BleachBit
  clear
  if confirm 'Clean the disk space?'
    bleachbit
  end

  # Reboot
  clear
  if confirm 'Reboot?'
    systemctl reboot
  end
end
