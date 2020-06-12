#!/bin/bash
set -e

# The Vagrant machine name
MACHINE='robot'

# The loaded Nordpool day-ahead price report
NORDPOOL_REPORT='reports/Day-ahead prices.xls'

# The loaded Lumme-Energiea report
LUMME_REPORT='reports/report.csv'

# Run Nordpool scripts
NORDPOOL="${NORDPOOL:-"1"}"

# Run Lumme-Energia scripts
LUMME_ENERGIA="${LUMME_ENERGIA:-"1"}"

# The default name for the InfluxDB container
INFLUXDB_CONTAINER="influxdb"

# Determine the directory with files
SCRIPT_DIR="$(dirname "$(cd "${0%/*}" 2>'/dev/null'; echo "${PWD}"/"${0##*/}")")"
pushd "${SCRIPT_DIR}" >>'/dev/null'

# Load the secrets
set -a
source 'secrets'
set +a

if [ "${NORDPOOL}" != '0' ]
then
	# Build the Nordpool parser if it does not exist
	if [ ! -x 'parsers/nordpool/nordpool.phar' ]
	then
		bash 'parsers/nordpool/build.sh'
	fi
fi

if [ "${LUMME_ENERGIA}" != '0' ]
then
	# Build the Lumme parser it it does not exist
	if [ ! -x 'parsers/lumme-energia/lumme-energia.phar' ]
	then
		bash 'parsers/lumme-energia/build.sh'
	fi
fi

# Make sure the database container is up
if [ -z "$(docker 'ps' --quiet --filter "name=^${INFLUXDB_CONTAINER}")" ]
then
	bash 'database.sh'
fi

# Get the robot machine status
state="$(vagrant 'status' "${MACHINE}" \
	--machine-readable |\
	grep -Ee ",${MACHINE},state,[a-z]+$" |\
	cut --delim ',' --field '4')"
state="running"

# Start the robot machine if it is not up
if [ "${state}" != 'running' ]
then
	vagrant 'up' "${MACHINE}"
fi

if [ "${NORDPOOL}" != '0' ]
then
	# Run the Nordpool collection task
	vagrant 'ssh' --command "bash 'robot/nordpool/run.sh'"
	
	# Import the data
	env INFLUXDB_DATABASE="${INFLUXDB_DATABASE_NORDPOOL}" \
		./parsers/nordpool/nordpool.phar --input "${NORDPOOL_REPORT}"
fi

if [ "${LUMME_ENERGIA}" != '0' ]
then
	# Run the Nordpool collection task
	vagrant 'ssh' --command \
		"env LUMME_USER_ID='${LUMME_USER_ID}' LUMME_PASSWORD='${LUMME_PASSWORD}' \
		bash 'robot/lumme-energia/run.sh'"
	
	# Import the data
	env INFLUXDB_DATABASE="${INFLUXDB_DATABASE_LUMME}" \
		./parsers/lumme-energia/lumme-energia.phar --input "${LUMME_REPORT}"
fi

popd >>'/dev/null'
