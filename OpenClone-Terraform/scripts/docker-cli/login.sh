#!/bin/bash

source /vultr-api/registries.sh

login_to_container_registry() {
    registry=$(get_registry openclone)
    username=$(echo "$registry" | jq -r '.root_user.username')
    password=$(echo "$registry" | jq -r '.root_user.password')
    echo "$password" | docker login "$vultr_region".vultrcr.com -u "$username" --password-stdin
}