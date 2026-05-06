#!/bin/bash

set -e

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

printf 'a\nb\nc\n' > "$tmp_file"
moon run src/tail -- -n 2 "$tmp_file" | grep -qx 'c'
