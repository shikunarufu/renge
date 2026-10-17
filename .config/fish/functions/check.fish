function check
  #######################################
  # Check for errors
  #######################################

  # Failed systemd services
  clear
  printf '%s\n' 'Check if any systemd services have failed:'
  systemctl --failed
  read --prompt-str "Press Enter to continue, or type q to quit: " --local answer
  test "$answer" = q; and return

  # Log files
  clear
  read --prompt-str "Look for errors in the pacman log:" --local _
  nvim /var/log/pacman.log
  clear
  read --prompt-str "Look for errors in the systemd journal:" --local _
  journalctl -b
end
