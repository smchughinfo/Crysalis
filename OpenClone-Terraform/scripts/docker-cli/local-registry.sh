#!/bin/bash

create_local_registry() {
    docker run -d -p 5000:5000 --name $kind_registry_name registry:2

    # Locate all images with "openclone" in the name and the tag "1.0"
    images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep openclone- | grep ":1.0")

    for image in $images; do
        # Retag and push each matching image to the local registry
        # Using the same name and tag, just prefixed with localhost:5000/
        new_image="localhost:5000/${image#*/}" # Strip any registry prefix if present

        # Optional: If we really needed to "delete" it first, we'd have to 
        # enable registry deletion and use registry APIs, which is non-trivial.
        # Here, we'll just push it again. This effectively updates it in the registry.
        
        echo "Pushing $new_image to the local registry..."
        docker tag "$image" "$new_image"
        docker push "$new_image"
    done
}

run_local_registry() {
    docker network connect kind-network registry
    docker start "$kind_registry_name"
}

################################################################################
######## EXPOSE SCRIPT TO COMMAND LINE #########################################
################################################################################

# allow functions in this script to be called from terminal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source /scripts/shell-helpers/function-runner.sh
fi