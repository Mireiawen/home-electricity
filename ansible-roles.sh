#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Ansible roles
ansible-galaxy "role" "install" \
	--roles-path "roles" \
	--role-file "requirements.yml"
