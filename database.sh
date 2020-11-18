#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

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
