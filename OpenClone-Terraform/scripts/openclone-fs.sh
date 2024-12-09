#!/bin/bash

source /scripts/shell-helpers/aliases.sh

get_first_pod_with_mount() {
    pod_name=$(k get pods --selector=pod_id=openclone-website-pod --output=jsonpath='{.items[0].metadata.name}')
    echo $pod_name
}

push_openclone_fs() {
    host="dev.sftp.openclone.ai"
    username="openclone-ftp"
    password="abc123"
    source_dir="/DatabaseRestore/Backups/OpenCloneFS"
    dest_dir="/OpenCloneFS"

    # Use lftp to mirror the local directory to the remote SFTP server, bypassing host key verification
    lftp -u "$username","$password" sftp://$host <<EOF
set sftp:auto-confirm yes
set sftp:connect-program "ssh -a -x -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
mirror -R "$source_dir" "$dest_dir"
EOF
}

# allow functions in this script to be called from terminal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source /scripts/shell-helpers/function-runner.sh
fi