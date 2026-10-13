#!/usr/bin/env bash
#
# Wayland Sessions

readonly SESSION_DIR="/usr/share/wayland-sessions"

main() {
  local file name command
  for file in "${SESSION_DIR}"/*.desktop; do
    [[ -f "${file}" ]] || continue
    name="$(sed -n 's/^Name=//p' "${file}" | head -n 1)"
    command="$(sed -n 's/^Exec=//p' "${file}" | head -n 1)"
    if [[ -n "${name}" && -n "${command}" ]]; then
      printf '%s\t%s\n' "${name}" "${command}"
    fi
  done
}

main "$@"
