#!/bin/bash

source /scripts/docker-cli/login.sh
source /scripts/docker-cli/tag-resolver.sh
source /vultr-api/registries.sh

# Get last updated date of the container images
get_last_updated_date() {
    local image_name="$1"
    local created_date
    created_date=$(docker inspect --format='{{.Created}}' "$image_name" 2>/dev/null)
    
    if [ -z "$created_date" ]; then
        echo "Image not found locally."
    else
        # Convert the timestamp to mm/dd/yyyy hh:mm am/pm format
        date -d "$created_date" +"%m/%d/%Y %I:%M %p"
    fi
}

push_container() {
    local image_name="$1"

    echo "Last updated date for ${image_name}:1.0 is $(get_last_updated_date "${image_name}:1.0")"
    echo "In your local Docker, make sure to delete and rebuild all container images where you have made code changes. Otherwise, you will be pushing the same image with a different tag. When you're ready, press Enter to continue..."
    read
    echo "Pushing ${image_name}. If this takes a long time delete the container registry. It may be taking a long time because there are a lot of images and it's having to go through them one by one in order to find the next version number. Deleting the registry will reset the version number to 1, making that process faster, but containers will have to do their initial push all over again."
    echo "Please wait..."

    login_to_container_registry
    local_name="${image_name}:1.0"
    remote_name="$(get_next_remote_image_name ${image_name})"
    docker tag $local_name $remote_name
    docker push $remote_name
}

################################################################################
######## EXPOSE SCRIPT TO COMMAND LINE #########################################
################################################################################

# allow functions in this script to be called from terminal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source /scripts/shell-helpers/function-runner.sh
fi