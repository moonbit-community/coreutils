#!/bin/bash

set -e

moon run src/echo -- README.md | grep -qx 'README.md'
moon run src/echo -- hello world | grep -qx 'hello world'
