#!/bin/bash

source /scripts/devcontainer-host/host-commands.sh
source /scripts/shell-helpers/aliases.sh

function wait_for_external_database_host_to_exist() {
    local host=""
    local wait_time=0
    local connection_success=false

    echo "Starting check for external database host..."

    while [[ "$connection_success" == false ]]; do
        # Get the external host IP
        host=$(k get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}' | cut -d' ' -f1)

        if [[ -n "$host" ]]; then
            echo "Database host found: $host. Checking if we can connect to PostgreSQL..."

            # Try to connect to PostgreSQL using psql
            PGPASSWORD="$TF_VAR_postgres_password" psql -h "$host" -U postgres -p "$(get_external_database_port)" -c '\q' &>/dev/null

            if [[ $? -eq 0 ]]; then
                connection_success=true
                echo "Successfully connected to PostgreSQL at $host."
            else
                echo "Failed to connect to PostgreSQL. Waiting for $wait_time seconds before retrying..."
            fi
        else
            echo "Database host not found. Waiting for $wait_time seconds..."
        fi

        # Sleep and increment the wait time
        sleep 5
        ((wait_time+=5))
    done

    echo "PostgreSQL connection established. Script will now proceed."
}

function get_external_database_host() {
    echo "$(k get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}' | cut -d' ' -f1)"
}

function get_external_database_port() {
    echo "$(k get svc openclone-database-nodeport -o jsonpath='{.spec.ports[0].nodePort}')"
}

function get_external_super_connectionstring() {
    local database="$1"
    echo "Host=$(get_external_database_host);Port=$(get_external_database_port);Database=$database;Username=postgres;Password=$TF_VAR_postgres_password;Include Error Detail=true;"
}

function restore() {
    wait_for_external_database_host_to_exist
    echo "doing restore... "
    default_connection="$(get_external_super_connectionstring "$TF_VAR_openclone_openclonedb_name")"
    log_connection="$(get_external_super_connectionstring "$TF_VAR_openclone_logdb_name")"

    # Combine all arguments into a single string
    local command="${OpenClone_Root_Dir}/DatabaseRestore/BatchScripts/restore.bat"
    command+=" --remote"
    command+=" --openclone_db_super_connection_string \"$default_connection\""
    command+=" --log_db_super_connection_string \"$log_connection\""
    command+=" --openclone_db_user_name \"$TF_VAR_openclone_openclonedb_user\""
    command+=" --openclone_db_user_password \"$TF_VAR_openclone_openclonedb_password\""
    command+=" --log_db_user_name \"$TF_VAR_openclone_logdb_user\""
    command+=" --log_db_user_password \"$TF_VAR_openclone_logdb_password\""

    # Pass the combined string to run_host_command
    run_host_command "$command"
}

function get_remote_shell_command() {
    # Get all pods in the namespace and filter for the database pod
    db_pod=$(k get pods --no-headers | grep database | awk '{print $1}')
    namespace=$(k get pod "$db_pod" -o jsonpath='{.metadata.namespace}')

    # Check if the pod is found
    if [[ -z "$db_pod" ]]; then
        echo "No database pod found."
        exit 1
    fi

    # Get the node IP and container details
    node_name=$(k get pod "$db_pod" -o jsonpath='{.spec.nodeName}')
    node_ip=$(k get node "$node_name" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

    containers=($(k get pod "$db_pod" -o jsonpath='{.spec.containers[*].name}'))
    container_name="${containers[0]}"

    # SSH user (assuming a default, modify as needed)
    ssh_user="your-ssh-user"

    # Generate the SSH connection command
    echo "ssh $ssh_user@$node_ip \"kubectl exec -it $db_pod -n $namespace -c $container_name -- /bin/bash\""
}

function migrate() {
    run_host_command "${OpenClone_Root_Dir}/DatabaseRestore/BatchScripts/migrate.bat"
}

# allow functions in this script to be called from terminal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source /scripts/shell-helpers/function-runner.sh
fi