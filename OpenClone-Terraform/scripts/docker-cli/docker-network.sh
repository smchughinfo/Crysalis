#!/bin/bash

create_container_network() {
    local network_name="$1"
    shift  # Shift arguments to process container IDs
    local container_ids_to_add_to_network=("$@")  # Remaining arguments are container IDs

    # Create the network if it doesn't already exist
    if ! docker network ls --filter "name=^${network_name}$" --format "{{.Name}}" | grep -q "^${network_name}$"; then
        echo "Creating Docker network: $network_name"
        docker network create "$network_name"
    else
        echo "Docker network $network_name already exists"
    fi

    # Loop through the container IDs and add them to the network
    for container_id in "${container_ids_to_add_to_network[@]}"; do
        if docker ps --format "{{.ID}}" | grep -q "^${container_id}$"; then
            echo "Connecting container $container_id to network $network_name"
            docker network connect "$network_name" "$container_id"
        else
            echo "Container ID $container_id is not running or does not exist"
        fi
    done
}

delete_container_network() {
    local network_name="$1"

    # Check if the network exists
    if docker network ls --filter "name=^${network_name}$" --format "{{.Name}}" | grep -q "^${network_name}$"; then
        # Get a list of container IDs connected to the network
        local container_ids=($(docker network inspect -f '{{range $id, $container := .Containers}}{{printf "%s " $id}}{{end}}' "$network_name"))

        # Disconnect each container from the network
        for container_id in "${container_ids[@]}"; do
            echo "Disconnecting container $container_id from network $network_name"
            docker network disconnect "$network_name" "$container_id"
        done

        # Remove the network
        echo "Removing Docker network: $network_name"
        docker network rm "$network_name"
    else
        echo "Docker network $network_name does not exist"
    fi
}

get_container_ip() {
  local container_name="$1"
  local network_name="$2"
  docker inspect -f "{{with index .NetworkSettings.Networks \"$network_name\"}}{{.IPAddress}}{{end}}" "$container_name"
}

give_container_dns_hostname() {
    local container_name="$1"
    local hostname="$2"
    local network_name="$3"

    # Verify input
    if [ -z "$container_name" ] || [ -z "$hostname" ] || [ -z "$network_name" ]; then
        echo "Usage: give_running_container_dns_hostname <container_name> <hostname> <network_name>"
        return 1
    fi

    # Get container IP address
    local container_ip
    container_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{if eq .NetworkID "'"$(docker network inspect -f '{{.Id}}' $network_name)"'"}}{{.IPAddress}}{{end}}{{end}}' "$container_name")

    if [ -z "$container_ip" ]; then
        echo "Failed to retrieve IP address for container $container_name on network $network_name."
        return 1
    fi

    # Add custom DNS entry to the network
    echo "Adding custom hostname $hostname for container $container_name on network $network_name with IP $container_ip."
    docker network disconnect "$network_name" "$container_name"
    docker network connect --alias "$hostname" "$network_name" "$container_name"

    echo "Hostname $hostname added successfully for container $container_name on network $network_name."
}


################################################################################
######## EXPOSE SCRIPT TO COMMAND LINE #########################################
################################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source /scripts/shell-helpers/function-runner.sh
fi