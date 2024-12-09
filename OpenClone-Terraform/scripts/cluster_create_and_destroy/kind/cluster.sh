#!/bin/bash

source /scripts/docker-cli/docker-network.sh

cluster_name="openclone-kind-cluster"
cluster_control_plane_container_name="openclone-kind-cluster-control-plane"
kind_network_name="kind-network"

################################################################################
######## MAIN LOGIC ############################################################
################################################################################

create_cluster() {
    echo "begin create kind cluster..."
    
    if kind get clusters | grep -q "^${cluster_name}$"; then
        echo "Cluster '${cluster_name}' already exists. Skipping creation."
    else
        export KUBECONFIG="$kind_kube_config_path"
        echo "Cluster '${cluster_name}' does not exist. Creating it now."
        kubernetes_version_without_the_plus=$(echo "$kubernetes_version" | cut -d'+' -f1)
        kind create cluster --name "${cluster_name}" --config "${kind_config_path}" --image "kindest/node:$kubernetes_version_without_the_plus"
    fi

    run_local_registry
    setup_kind_network
}

destroy_cluster() {
    echo "destroying cluster: $cluster_name"
    delete_container_network "$kind_network_name"
    kind delete cluster --name "$cluster_name"
}

################################################################################
######## HELPERS ###############################################################
################################################################################

setup_kind_network() {
    # because we are running kind inside a devcontainer the networking gets complicated. so put them on the same docker network
    control_plane_container_id=$(docker ps --filter "name=$cluster_control_plane_container_name" --format "{{.ID}}")
    registry_container_id=$(docker ps --filter "name=$kind_registry_name" --format "{{.ID}}")
    create_container_network "$kind_network_name" "$HOSTNAME" "$control_plane_container_id" "$registry_container_id"
    update_control_plane_ip_address
    give_container_dns_hostname "$kind_registry_name" "$kind_registry_host" "$kind_network_name"
}

update_control_plane_ip_address() {
    control_plane_ip=$(get_container_ip "$cluster_control_plane_container_name" "$kind_network_name")
    sed -i "s|https://.*:6443|https://$control_plane_ip:6443|" "$kind_kube_config_path"
}

does_cluster_exist() {
    kind get clusters | grep -q "^$cluster_name$"
    if [ $? -eq 0 ]; then
        echo "true"
    else
        echo "false"
    fi
}

################################################################################
######## EXPOSE SCRIPT TO COMMAND LINE #########################################
################################################################################

# allow functions in this script to be called from terminal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source /scripts/shell-helpers/function-runner.sh
fi