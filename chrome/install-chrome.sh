#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Downloaded from https://www.google.com/chrome/?platform=linux
CHROME_VERSION="87.0.4280.66-1"

# Downloaded from https://sites.google.com/a/chromium.org/chromedriver/downloads
# Major version must match the Chrome major version
CHROMEDRIVER_VERSION="87.0.4280.20"

# Get the current Chrome version
if [ -n "$(which 'google-chrome')" ]
then
	CHROME_V="$(google-chrome --version |cut --delim ' ' --fields '3')"
else
	CHROME_V='0'
fi

# Get the current Chromedriver version
if [ -n "$(which 'chromedriver')" ]
then
	CHROMEDRIVER_V="$(chromedriver --version |cut --delim ' ' --fields '2')"
else
	CHROMEDRIVER_V='0'
fi

# Determine the directory with files
SCRIPT_DIR="$(dirname "$(cd "${0%/*}" 2>'/dev/null'; echo "${PWD}"/"${0##*/}")")"

# Install the Chrome
if [ "${CHROME_V}" != "${CHROME_VERSION}" ]
then
	dpkg --install "${SCRIPT_DIR}/google-chrome-stable_${CHROME_VERSION}_amd64.deb"
fi

# Install the driver
if [ "${CHROMEDRIVER_V}" != "${CHROMEDRIVER_VERSION}" ]
then
	TEMP="$(mktemp -d)"
	pushd "${TEMP}" >>'/dev/null'
	curl --silent --show-error --location --remote-name \
		"https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"
	unzip "chromedriver_linux64.zip"
	chmod '+x' 'chromedriver'
	mv 'chromedriver' "/usr/bin/chromedriver"
	popd >>'/dev/null'
	rm --recursive --force "${TEMP}"
fi
