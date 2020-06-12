#!/bin/bash
set -e

# Determine the directory with files
SCRIPT_DIR="$(dirname "$(cd "${0%/*}" 2>'/dev/null'; echo "${PWD}"/"${0##*/}")")"

# Specify the report files
REPORT_FILE="${HOME}/Downloads/report.csv"
REPORT_DESTINATION="/mnt/reports/report.csv"

# Build the date to click
LUMME_DATE="${LUMME_DATE:-"$(date --utc --date '1 day ago' '+%Y-%m-%d')"}"

# Clean up the possible old temporary download file
rm -f "${REPORT_FILE}"
rm -rf "/tmp/.com.google.Chrome."*

# Run the tasks
pushd "${SCRIPT_DIR}" >>'/dev/null'
robot --rpa \
	--variable "LUMME_USER_ID:${LUMME_USER_ID}" \
	--variable "LUMME_PASSWORD:${LUMME_PASSWORD}" \
	--variable "LUMME_DATE:${LUMME_DATE}" \
	--report 'NONE' \
	--output 'NONE' \
	--log 'NONE' \
	'lumme-energia.robot'
popd >>'/dev/null'

mv "${REPORT_FILE}" "${REPORT_DESTINATION}"
