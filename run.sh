#!/bin/bash
set -e

# The Vagrant machine name
MACHINE='robot'

# The loaded Nordpool day-ahead price report
NORDPOOL_REPORT='reports/Day-ahead prices.xls'

# The loaded Lumme-Energiea report
LUMME_REPORT='reports/report.csv'

# Determine the directory with files
SCRIPT_DIR="$(dirname "$(cd "${0%/*}" 2>'/dev/null'; echo "${PWD}"/"${0##*/}")")"
pushd "${SCRIPT_DIR}" >>'/dev/null'

# Load the defaults and secrets
set -a
source 'defaults'

if [ -f 'secrets' ]
then
	source 'secrets'
fi
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

if [ "${INFLUXDB_CUSTOM}" == '0' ]
then
	# Make sure the database container is up
	if [ -z "$(docker 'ps' --quiet --filter "name=^${INFLUXDB_CONTAINER}")" ]
	then
		bash 'database.sh'
	fi
fi

# Get the robot machine status
state="$(vagrant 'status' "${MACHINE}" \
	--machine-readable |\
	grep -Ee ",${MACHINE},state,[a-z]+$" |\
	cut --delim ',' --field '4')"

# Start the robot machine if it is not up
if [ "${state}" != 'running' ]
then
	bash "ansible-roles.sh"
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
