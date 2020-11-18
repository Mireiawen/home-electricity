#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Determine the directory with files
SCRIPT_DIR="$(dirname "$(cd "${0%/*}" 2>'/dev/null'; echo "${PWD}"/"${0##*/}")")"

# Build the PHAR
pushd "${SCRIPT_DIR}" >>'/dev/null'
composer 'install' --no-dev
box 'build'
popd >>'/dev/null'
