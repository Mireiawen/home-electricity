#!/bin/bash
set -e

# Ansible roles
ansible-galaxy "role" "install" \
	--roles-path "roles" \
	--role-file "requirements.yml"
