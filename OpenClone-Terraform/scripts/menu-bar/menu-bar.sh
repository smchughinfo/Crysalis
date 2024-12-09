#!/bin/bash

source /scripts/database/database.sh
source /scripts/menu-bar/server-logs.sh
source /scripts/shell-helpers/aliases.sh

function MENU_get_nodes {
    k get nodes -o wide
}

function MENU_get_pods {
    k get pods -o wide
}

function MENU_get_service_endpoints {
    k get endpoints -o wide
}

function MENU_get_state {
    terraform state list -state=/vultr-terraform/vultr/terraform.tfstate
    terraform state list -state=/vultr-terraform/kubernetes/terraform.tfstate
}

function MENU_describe_service {
    k describe svc
}

function MENU_get_nodeport_external_addresses {
    # Get all external IPv4 addresses for nodes
    hosts=$(k get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

    # Loop through each NodePort service and get its port
    for service in $(k get svc --field-selector spec.type=NodePort -o jsonpath='{.items[*].metadata.name}'); do
        port=$(k get svc "$service" -o jsonpath='{.spec.ports[0].nodePort}')
        
        # Print each host:port combination with service name for the current NodePort service
        for host in $hosts; do
            echo "$service - $host:$port"
        done
    done
}

function MENU_remote_shell {
    # Get all pods in the current namespace
    pods=($(k get pods --no-headers | awk '{print $1}'))

    # Check if there are any pods
    if [[ ${#pods[@]} -eq 0 ]]; then
        echo "No pods found in the current namespace."
        return
    fi

    echo "Available pods:"
    i=1
    for pod in "${pods[@]}"; do
        echo "$i. $pod"
        i=$((i+1))
    done

    read -p "Please enter a value: " choice

    if [[ $choice -ge 1 && $choice -le ${#pods[@]} ]]; then
        selected_pod=${pods[$((choice-1))]}
        
        # Check if there are multiple containers in the pod
        containers=($(k get pod $selected_pod -o jsonpath='{.spec.containers[*].name}'))
        if [[ ${#containers[@]} -gt 1 ]]; then
            echo "Pod '$selected_pod' has multiple containers:"
            j=1
            for container in "${containers[@]}"; do
                echo "$j. $container"
                j=$((j+1))
            done
            read -p "Please enter the container number: " container_choice
            if [[ $container_choice -ge 1 && $container_choice -le ${#containers[@]} ]]; then
                selected_container=${containers[$((container_choice-1))]}
                echo "Connecting to container '$selected_container' in pod '$selected_pod'..."
                k exec -it $selected_pod -c $selected_container -- /bin/bash
            else
                echo "Invalid container selection."
            fi
        else
            # Only one container in the pod
            echo "Connecting to pod '$selected_pod'..."
            k exec -it $selected_pod -- /bin/bash
        fi
    else
        echo "Invalid selection."
    fi
}

function MENU_delete_pod {
    # Get all pods in the current namespace
    pods=($(k get pods --no-headers | awk '{print $1}'))

    # Check if there are any pods
    if [[ ${#pods[@]} -eq 0 ]]; then
        echo "No pods found in the current namespace."
        return
    fi

    echo "Available pods:"
    i=1
    for pod in "${pods[@]}"; do
        echo "$i. $pod"
        i=$((i+1))
    done

    read -p "Please enter the number of the pod to delete: " choice

    if [[ $choice -ge 1 && $choice -le ${#pods[@]} ]]; then
        selected_pod=${pods[$((choice-1))]}
        echo "Are you sure you want to delete pod '$selected_pod'? This action cannot be undone. (y/n)"
        read -p "Confirm deletion: " confirmation
        if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
            echo "Deleting pod '$selected_pod'..."
            k delete pod $selected_pod
            echo "Pod '$selected_pod' has been deleted."
        else
            echo "Deletion cancelled."
        fi
    else
        echo "Invalid selection."
    fi
}

function MENU_delete_metrics_infrastructure() {
    # Delete Grafana and Prometheus Helm releases
    h delete grafana --namespace default
    h delete prometheus --namespace default

    # Find and delete all pods with "prometheus" or "grafana" in their names
    k get pods -n default \
        | grep -E 'prometheus|grafana' \
        | awk '{print $1}' \
        | xargs -r k delete pod -n default

    # Uninstall Helm
    echo "Uninstalling Helm..."

    # Find the Helm binary path
    HELM_PATH=$(command -v helm)

    if [ -n "$HELM_PATH" ]; then
        echo "Helm binary found at $HELM_PATH"

        # Remove the Helm binary
        if [ -w "$HELM_PATH" ]; then
            rm "$HELM_PATH"
            echo "Helm binary removed."
        else
            sudo rm "$HELM_PATH"
            echo "Helm binary removed with sudo."
        fi

        # Remove Helm configuration and cache directories
        rm -rf ~/.helm
        rm -rf ~/.cache/helm
        echo "Helm configuration and cache directories removed."
    else
        echo "Helm binary not found. It may have already been uninstalled."
    fi
}

function MENU_get_database_connection_command() {
    external_ip=$(get_external_database_host)
    external_port=$(get_external_database_port)
    echo "psql -h ${external_ip} -p ${external_port} -U postgres -d postgres"
    echo "password=${TF_VAR_postgres_password}"
}

function MENU_print_server_log {
    # Get the list of deployments dynamically
    deployments=($(k get deployments -o jsonpath='{.items[*].metadata.name}'))
    
    # Check if any deployments were found
    if [[ ${#deployments[@]} -eq 0 ]]; then
        echo "No deployments found."
        return
    fi

    # Print the list of deployments
    echo "Which logs would you like to print?"
    for i in "${!deployments[@]}"; do
        echo "$((i + 1)). ${deployments[$i]}"
    done
    
    # Ask the user to input a value
    read -p "Please enter a number: " user_choice
    
    # Validate the input and call print_logs for the selected deployment
    if [[ $user_choice -ge 1 && $user_choice -le ${#deployments[@]} ]]; then
        selected_deployment="${deployments[$((user_choice - 1))]}"
        print_logs "$selected_deployment"
    else
        echo "Invalid selection. Please enter a number between 1 and ${#deployments[@]}."
        MENU_print_server_log  # Retry the selection process
    fi
}

################################################################################
######## MENU ##################################################################
################################################################################

# This script allows you to either:
# 1. Pass a function name as an argument (in the format --function_name) to run a specific utility directly.
#    - Example: ./script.sh --MENU_print_server_log will run the function MENU_print_server_log.
# 2. If no argument is passed, the script will display a numbered menu listing all available functions (those prefixed with MENU_).
#    - You can select a function by entering its corresponding number.
# 
# The script works by:
# - Extracting all functions that are prefixed with MENU_.
# - If a function name is passed as an argument, it will attempt to match and execute the corresponding function.
# - If no argument is provided, it generates a menu of available functions, allowing the user to choose one by number.
# - Invalid input will prompt the user to enter a valid number from the menu.

# Extract the function names prefixed with MENU_
function_list=$(declare -F | awk '{print $3}' | grep '^MENU_')

# Check if a function was passed as an argument
if [[ $1 =~ ^-- ]]; then
    # Remove the '--' prefix to get the function name
    function_name="${1#--}"

    # Check if the function exists using grep
    if echo "$function_list" | grep -q "^MENU_$function_name$"; then
        # Run the function if it exists
        echo "Running $function_name..."
        MENU_$function_name
        exit 0
    else
        echo "Function MENU_$function_name not found."
        exit 1
    fi
fi

# If no function is passed, proceed with the menu prompt
echo "Which utility would you like to run? Please enter a value:"
i=1
for func in $function_list; do
    # Remove the MENU_ prefix for display purposes
    display_name=${func#MENU_}
    echo "$i. $display_name"
    functions_array[$i]=$func
    ((i++))
done

# Read user input
read -p "Enter the number of the utility to run: " choice

# Execute the selected function from the menu
selected_function=${functions_array[$choice]}

if [[ -n "$selected_function" ]]; then
    echo "Running ${selected_function#MENU_}.."
    $selected_function
else
    echo "Invalid selection. Please enter a valid number."
fi
