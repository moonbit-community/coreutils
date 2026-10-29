#!/bin/bash

set -e

moon run src/wc -- -lcmw --max-line-length README.md
moon run src/wc < README.md

# Compare stdin counts with the platform wc in a UTF-8 locale. Check flags
# separately because implementations print combined -m/-c columns differently.
if locale -a | grep -qi '^C\.utf8$'; then
  export LC_ALL=C.utf8
else
  export LC_ALL=en_US.UTF-8
fi
check_counts() {
  input=$1
  for flag in -l -w -m -c; do
    expected=$(printf '%s' "$input" | /usr/bin/wc "$flag" | tr -d '[:space:]')
    actual=$(printf '%s' "$input" | moon run src/wc -- "$flag" | tr -d '[:space:]')
    if [ "$actual" != "$expected" ]; then
      printf 'wc %s mismatch: expected %s, got %s\n' "$flag" "$expected" "$actual" >&2
      exit 1
    fi
  done
}
check_counts ''
check_counts 'hello'
check_counts $'hello\n'
check_counts $'hello world\nlast'
check_counts $'a\tb\n\nc'
check_counts $'é 😀\n尾'
