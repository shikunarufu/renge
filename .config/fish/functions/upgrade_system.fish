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
        set -l dir ~/.cache/aur
        mkdir -p $dir

        for pkg in (pacman --query --foreign --quiet | string match --invert --regex -- '-debug$')
            if test -d $dir/$pkg/.git
                git -C $dir/$pkg pull --quiet 2>/dev/null
                or continue
            else
                git clone --quiet https://aur.archlinux.org/$pkg.git $dir/$pkg 2>/dev/null
                or continue
            end

            set -l info $dir/$pkg/.SRCINFO
            if not test -f $info
                continue
            end
            set -l ver (string match --regex --groups-only '^\s*pkgver = (.+)$' < $info)[1]
            set -l rel (string match --regex --groups-only '^\s*pkgrel = (.+)$' < $info)[1]
            set -l epoch (string match --regex --groups-only '^\s*epoch = (.+)$' < $info)[1]
            set -l new "$ver-$rel"
            test -n "$epoch"; and set new "$epoch:$new"
            set -l old (pacman --query $pkg | string split --fields 2 ' ')

            if test -z "$new" -o "$new" = -; or test -z "$old"
                continue
            end

            if test (vercmp $new $old) -gt 0
                echo "$pkg: $old -> $new"
                less $dir/$pkg/PKGBUILD
                read --local --prompt-str "Build $pkg? [y/N] " answer
                if test "$answer" = y
                    env -C $dir/$pkg makepkg --syncdeps --install
                end
            end
        end
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
    if confirm 'Reboot?'
        systemctl reboot
    end
end
