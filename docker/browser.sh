#!/bin/bash
echo "Trying to open $1 in host browser" >&2
echo $1 | socat stdio TCP:127.0.0.1:8105
