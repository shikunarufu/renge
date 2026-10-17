function upgrade_system
  # Upgrade the system
  clear
  printf '%s\n' 'Upgrading the system...'
  sudo pacman --sync --refresh --sysupgrade
  or return

  # Upgrade AUR packages
  if confirm 'Upgrade AUR packages?'
    set -l dir ~/.cache/aur
    mkdir -p $dir

    for pkg in (pacman --query --foreign --quiet)
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

      set -l info $dir/$pkg/.SRCINFO
      set -l ver (string match --regex --groups-only '^\s*pkgver = (.+)$' < $info)[1]
      set -l rel (string match --regex --groups-only '^\s*pkgrel = (.+)$' < $info)[1]
      set -l epoch (string match --regex --groups-only '^\s*epoch = (.+)$' < $info)[1]
      set -l new $ver-$rel
      test -n "$epoch"; and set new $epoch:$new
      set -l old (pacman --query $pkg | string split ' ')[2]

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
  set -l orphans (pacman --query --deps --unrequired --quiet)
  if test (count $orphans) -gt 0
    printf '%s\n' $orphans
    sudo pacman --remove --nosave --recursive $orphans
  end

  # Package cache
  if confirm 'Clean the package cache?'
    sudo paccache --remove
  end
end
funcsave upgrade_system
