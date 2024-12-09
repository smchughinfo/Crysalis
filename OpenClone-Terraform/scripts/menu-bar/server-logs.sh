#!/bin/bash

source /scripts/shell-helpers/aliases.sh

get_pod_names() {
    local prefix=$1
    
    # Store matching pod names in an array
    pod_names=($(k get pods | awk -v prefix="$prefix" '$1 ~ "^"prefix {print $1}'))
}

print_logs() {
    local deployment_name=$1

    # Call the get_pod_names function to populate the pod_names array
    get_pod_names "$deployment_name"
    
    # Print all matching pod names and their logs
    echo "Matching pod names for deployment: $deployment_name"
    for pod in "${pod_names[@]}"; do
        echo "$pod"
        echo "Fetching logs for pod: $pod"
        k logs "$pod"
        echo "--------------------------------------------------"
    done
}

