#!/bin/sh
printf '\033c\033]0;%s\a' Frozen Board
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Frozen Board.x86_64" "$@"
