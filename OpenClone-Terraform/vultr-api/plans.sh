#!/bin/bash

source /vultr-api/api-base.sh

plan_endpoint="plans"

list_plans() {
    get_vultr "$plan_endpoint"
}

get_plan() {
  local plan_id="$1"
  json_data=$(list_plans)

  # Extract the plan for the specified plan_id using jq
  local plan=$(echo "$json_data" | jq -r --arg plan_id "$plan_id" '.plans[] | select(.id == $plan_id)')
  
  # Output the plan
  echo "$plan"
}

get_plan_price() { # this function isn't being used. ordinarily i would delete it but i'm leaving it here for convenience
  local plan_id="$1"
  
  # Use get_plan to get the plan data
  local plan=$(get_plan "$plan_id")

  # Extract the price from the plan data
  local price=$(echo "$plan" | jq -r '.monthly_cost')
  
  # Output the price
  echo "$price"
}

# allow functions in this script to be called from terminal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source /scripts/shell-helpers/function-runner.sh
fi