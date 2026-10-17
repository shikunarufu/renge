function upgrade_system
    # Upgrade the system
    clear
    printf '%s\n' 'Upgrading the system...'
    sudo pacman --sync --refresh --sysupgrade
    or return

    # Upgrade AUR packages
    set -l dir ~/.cache/aur
    mkdir -p $dir

    # Foreign packages = installed but not in the sync databases
    for pkg in (pacman --query --foreign --quiet)
        # Clone or update the package repository
        if test -d $dir/$pkg/.git
            git -C $dir/$pkg pull --quiet
            or continue
        else
            git clone --quiet https://aur.archlinux.org/$pkg.git $dir/$pkg 2>/dev/null
            or begin
                echo "Skipped $pkg: not found in the AUR"
                continue
            end
        end

        # Read the new version from .SRCINFO
        set -l info $dir/$pkg/.SRCINFO
        set -l ver (string match --regex --groups-only '^\s*pkgver = (.+)$' < $info)[1]
        set -l rel (string match --regex --groups-only '^\s*pkgrel = (.+)$' < $info)[1]
        set -l epoch (string match --regex --groups-only '^\s*epoch = (.+)$' < $info)[1]
        set -l new $ver-$rel
        test -n "$epoch"; and set new $epoch:$new
        set -l old (pacman --query $pkg | string split ' ')[2]

        # Build only if the AUR version is newer
        if test (vercmp $new $old) -gt 0
            echo "$pkg: $old -> $new"
            less $dir/$pkg/PKGBUILD
            read --local --prompt-str "Build $pkg? [y/N] " answer
            if test "$answer" = y
                env -C $dir/$pkg makepkg --syncdeps --install
            end
        end
    end

    # Orphans: list, then remove after pacman asks for confirmation
    set -l orphans (pacman --query --deps --unrequired --quiet)
    if test (count $orphans) -gt 0
        printf '%s\n' $orphans
        sudo pacman --remove --nosave --recursive $orphans
    end

    # Package cache
    sudo paccache --remove
end
