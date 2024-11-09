#!/bin/sh
echo -ne '\033c\033]0;HIVE\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/HIVE_0.0.1.x86_64" "$@"
