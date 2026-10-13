#!/usr/bin/env bash
#
# Users

readonly UID_MIN=1000
readonly UID_MAX=59999

main() {
  local name uid shell
  while IFS=: read -r name _ uid _ _ _ shell; do
    if (( uid >= UID_MIN && uid <= UID_MAX )) \
        && [[ "${shell}" != */nologin && "${shell}" != */false ]]; then
      printf '%s\n' "${name}"
    fi
  done < <(getent passwd)
}

main "$@"
