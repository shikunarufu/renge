[Service]
ExecStart=
ExecStart=/usr/bin/mpd-mpris -network unix -host %t/mpd/socket
