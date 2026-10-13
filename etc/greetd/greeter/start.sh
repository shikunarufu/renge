#!/usr/bin/env bash
#
# Quickshell Greeter

main() {
  qs -p /etc/greetd/greeter
  mmsg dispatch quit || mmsg -q
}

main "$@"
