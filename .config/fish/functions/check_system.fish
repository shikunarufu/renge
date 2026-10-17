function check_system
  # Failed systemd services
  clear
  printf '%s\n' 'Check if any systemd services have failed.'
  systemctl --failed
  confirm 'Continue?'
  or return

  # Pacman log
  clear
  confirm 'Look for errors in the pacman log file. Continue?'
  or return
  nvim -R /var/log/pacman.log

  # Systemd journal
  clear
  confirm 'Look for errors in the systemd journal. Continue?'
  sudo journalctl -b
end
funcsave check_system
