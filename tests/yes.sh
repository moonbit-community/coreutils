#!/bin/bash

set -e

(moon run src/yes -- hello 2>/dev/null || :) | head -n 2 | grep -qx 'hello'
(moon run src/yes 2>/dev/null || :) | head -n 2 | grep -qx 'y'
