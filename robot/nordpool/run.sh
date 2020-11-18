#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Determine the directory with files
SCRIPT_DIR="$(dirname "$(cd "${0%/*}" 2>'/dev/null'; echo "${PWD}"/"${0##*/}")")"

# Specify the report files
REPORT_FILE="${HOME}/Downloads/Day-ahead prices.xls"
REPORT_DESTINATION="/mnt/reports/Day-ahead prices.xls"

# Clean up the possible old temporary download file
rm -f "${REPORT_FILE}"
rm -rf "/tmp/.com.google.Chrome."*

# Run the tasks
pushd "${SCRIPT_DIR}" >>'/dev/null'
robot --rpa \
	--report 'NONE' \
	--output 'NONE' \
	--log 'NONE' \
	'nordpool.robot'
popd >>'/dev/null'

mv "${REPORT_FILE}" "${REPORT_DESTINATION}"
