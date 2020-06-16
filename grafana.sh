#!/bin/bash
set -e

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

# Build the provisioning configuration
j2 'grafana/datasources/nordpool.yml.j2' >'grafana/datasources/nordpool.yml'
j2 'grafana/datasources/lumme-energia.yml.j2' >'grafana/datasources/lumme-energia.yml'

popd >>'/dev/null'

# Start the container
docker 'run' \
	--detach \
	--volume "${SCRIPT_DIR}/grafana:/etc/grafana/provisioning:ro" \
	--volume "${GRAFANA_VOLUME}:/var/lib/grafana" \
	--restart 'always' \
	--name "${GRAFANA_CONTAINER}" \
	--env 'GF_AUTH_ANONYMOUS_ENABLED=true' \
	--env "GF_AUTH_ANONYMOUS_ORG_NAME=${GRAFANA_ORGANIZATION_NAME}" \
	--env 'GF_SECURITY_ALLOW_EMBEDDING=true' \
	--label 'traefik.enable=true' \
	--label 'traefik.http.routers.grafana.entrypoints=web' \
	--label 'traefik.http.routers.grafana.middlewares=http-to-https,whitelist' \
	--label 'traefik.http.routers.grafana-secure.entrypoints=websecure' \
	--label 'traefik.http.routers.grafana-secure.middlewares=whitelist' \
	--label 'traefik.http.middlewares.http-to-https.redirectscheme.scheme=https' \
	--label 'traefik.http.middlewares.http-to-https.redirectscheme.permanent=true' \
	--label "traefik.http.middlewares.whitelist.ipwhitelist.sourcerange=${LOCAL_NETWORK}" \
	'grafana/grafana'

# Update the default organiztion name to match with configuration
data="$(jq -n --arg 'name' "${GRAFANA_ORGANIZATION_NAME}" '{ name: $name }')"
sleep '5s'
docker 'run' \
	--rm \
	--link "${GRAFANA_CONTAINER}:grafana" \
	--interactive --tty \
	'curlimages/curl' \
		--user "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PADD}" \
		--request 'PUT' \
		--header 'Accept: application/json' \
		--header 'Content-type: application/json' \
		 --data "${data}" \
		'http://grafana:3000/api/orgs/1' |\
		jq -r '.message'

