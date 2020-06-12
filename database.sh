#!/bin/bash
set -e

# Set the defaults
INFLUXDB_VOLUME="influxdb"
INFLUXDB_CONTAINER="influxdb"
LOCAL_NETWORK="192.168.0.0/16"

# Determine the directory with files
SCRIPT_DIR="$(dirname "$(cd "${0%/*}" 2>'/dev/null'; echo "${PWD}"/"${0##*/}")")"
pushd "${SCRIPT_DIR}" >>'/dev/null'

# Load the secrets if it exists
if [ -f 'secrets' ]
then
	set -a
	source 'secrets'
	set +a
fi

popd >>'/dev/null'

# Start the container
docker 'run' \
	--detach \
	--volume "${INFLUXDB_VOLUME}:/var/lib/influxdb" \
	--restart 'always' \
	--name "${INFLUXDB_CONTAINER}" \
	--label "traefik.enable=true" \
	--label 'traefik.http.routers.influxdb.entrypoints=web' \
	--label 'traefik.http.routers.influxdb.middlewares=http-to-https,whitelist' \
	--label 'traefik.http.routers.influxdb-secure.entrypoints=websecure' \
	--label 'traefik.http.routers.influxdb-secure.middlewares=whitelist' \
	--label 'traefik.http.middlewares.http-to-https.redirectscheme.scheme=https' \
	--label 'traefik.http.middlewares.http-to-https.redirectscheme.permanent=true' \
	--label "traefik.http.middlewares.whitelist.ipwhitelist.sourcerange=${LOCAL_NETWORK}" \
	'influxdb:1.8'

# Wait for the InfluxDB to start up
sleep '10s'

# Create the databases
docker 'exec' \
	"${INFLUXDB_CONTAINER}" \
	'influx' \
		-execute "CREATE DATABASE ${INFLUXDB_DATABASE_NORDPOOL}"

docker 'exec' \
	"${INFLUXDB_CONTAINER}" \
	'influx' \
		-execute "CREATE DATABASE ${INFLUXDB_DATABASE_LUMME}"
