#!/bin/bash
echo "Trying to open $1 in host browser" >&2
echo $1 | socat stdio unix:/run/user/$(id -u)/guided-setup-open-browser.sock
