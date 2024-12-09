#!/bin/bash

source /vultr-api/api-base.sh
source /vultr-api/registries.sh
source /vultr-api/plans.sh
source /scripts/shell-helpers/aliases.sh

region_endpoint="regions"

list_regions() {
    get_vultr "$region_endpoint"
}

list_plans_in_region() {
    local region_id=$1

    # Check if region_id is provided
    if [ -z "$region_id" ]; then
        echo "Error: region_id is required."
        return 1
    fi

    # Get the list of available plans in the region
    plans_in_region=$(get_vultr "$region_endpoint/$region_id/availability")
    if [ -z "$plans_in_region" ]; then
        echo "Error: Failed to retrieve plans in region $region_id."
        return 1
    fi

    # Get all plan details
    plan_details=$(list_plans)
    if [ -z "$plan_details" ]; then
        echo "Error: Failed to retrieve plan details."
        return 1
    fi

    # Filter plan_details to only include plans in available_plans
    filtered_plans=$(echo "$plan_details" | jq --argjson available_plans "$(echo "$plans_in_region" | jq '.available_plans')" '
        .plans | map(select(.id as $id | $available_plans | index($id)))
    ')
    if [ -z "$filtered_plans" ]; then
        echo "Error: Failed to filter plans."
        return 1
    fi

    # Output the filtered plans
    echo "$filtered_plans"
}

filter_plans_in_region() {
    local type="$1"
    local min_cpus="$2"
    local min_ram="$3"
    local min_hdd="$4"

    # Get the list of plans available in the region
    plans_in_region=$(list_plans_in_region "$vultr_region")

    # Filter the plans based on the given criteria
    filtered_plans=$(echo "$plans_in_region" | jq --arg type "$type" \
        --argjson min_cpus "$min_cpus" \
        --argjson min_ram "$min_ram" \
        --argjson min_hdd "$min_hdd" \
        'map(select(
            (.type == $type) and
            (.vcpu_count >= $min_cpus) and
            (.ram >= $min_ram) and
            (.disk >= $min_hdd)
        ))')

    # Output the filtered plans
    echo "$filtered_plans"
}

apply_all() {
    apply_vultr_provider

    start_time=$(date +%s)
    elapsed=0

    echo "Waiting for all nodes to become ready..."

    while true; do
        # Get node statuses, escaping the square brackets
        status=$(k get nodes --field-selector=status.conditions[\?\(@.type==\"Ready\"\)].status==\"True\")

        # Calculate elapsed time
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))

        # Print status and time waited to the log file
        echo "Status: ${status} | Elapsed Time: ${elapsed}s"

        # Break loop if all nodes are ready
        if [[ $(k get nodes --no-headers | wc -l) -eq $(echo "$status" | grep -c ' Ready ') ]]; then
            echo "All nodes are ready."
            break
        fi

        # Wait 5 seconds before next check
        sleep 5
    done

    apply_kubernetes_provider
}

get_cheapest_cpu_node_plan() {
    plans=$(filter_plans_in_region "vc2" 2 4086 160)

    cheapest_price=9999999
    cheapest_plan_id=""

    num_plans=$(echo "$plans" | jq 'length')
    for (( i=0; i<$num_plans; i++ )); do
        # Extract the plan at index i
        plan=$(echo "$plans" | jq ".[$i]")

        plan_id=$(get_plan_id "$plan")

        monthly_cost=$(echo "$plan" | jq -r '.monthly_cost')

        if [ "$monthly_cost" -lt "$cheapest_price" ]; then
            cheapest_price="$monthly_cost"
            cheapest_plan_id="$plan_id"
        fi
    done

    echo "$cheapest_plan_id"
}

###################################################################
######## HELPERS ##################################################
###################################################################

get_plan_id() {
    local plan_json="$1"
    plan_id=$(echo "$plan_json" | jq -r '.id')
    echo "$plan_id"
}

################################################################################
######## EXPOSE SCRIPT TO COMMAND LINE #########################################
################################################################################

# allow functions in this script to be called from terminal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source /scripts/shell-helpers/function-runner.sh
fi
