#!/bin/bash

set_env_variable() {
    local var_name="$1"
    local var_value="$2"
    local file="$HOME/.bashrc"

    # Check if the variable already exists
    if grep -q "^export $var_name=" "$file"; then
        # Update the existing variable
        sed -i "s|^export $var_name=.*|export $var_name=\"$var_value\"|" "$file"
    else
        # Add a new variable
        echo "export $var_name=\"$var_value\"" >> "$file"
    fi

    # Apply the changes immediately
    export "$var_name=$var_value"
    source "$file"
    echo "Environment variable $var_name set to $var_value and persisted."
}

ensure_success() { # takes in function as parameter. if that functions returns non-zero call it a failure and termiante the current script. you can supply arguments to this like so:  ensure_success terraform -chdir=/terraform/cluster apply -auto-approve -var="database_node_pool_plan=$node_plan"
    "$@"
    if [ $? -ne 0 ]; then
        echo "Command failed: $@. Exiting."
        exit 1
    fi
}

remove_if_exists() {
    if [ -e "$1" ]; then
        rm -rf "$1"
        echo "$1 was deleted."
    else
        echo "$1 does not exist (nothing to delete)."
    fi
}
