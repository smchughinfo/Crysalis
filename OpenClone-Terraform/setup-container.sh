#!/bin/bash

source /scripts/shell-helpers/utility-functions.sh
source /scripts/environment.sh

setup_container() {
    ################################################################################
    ######## CONTAINER PATHS #######################################################
    ################################################################################

    chmod -R 777 /scripts /terraform /vultr-api

    ################################################################################
    ######## APP CONFIGURATIONS ####################################################
    ################################################################################

    set_env_variable TF_VAR_OpenClone_OpenCloneFS "/OpenCloneFS"
    set_env_variable TF_VAR_openclone_openclonedb_user "openclone_user_prod"
    set_env_variable TF_VAR_openclone_openclonedb_name "openclone_db_prod"
    set_env_variable TF_VAR_openclone_logdb_user "log_user_prod"
    set_env_variable TF_VAR_openclone_logdb_name "log_db_prod"
    set_env_variable TF_VAR_openclone_jwt_issuer "https://openclone.ai"
    set_env_variable TF_VAR_openclone_jwt_audience "openclone-prod"
    set_env_variable TF_VAR_openclone_opencloneloglevel "Information"
    set_env_variable TF_VAR_openclone_systemloglevel "Error"

    set_env_variable TF_VAR_openclone_sadtalker_port 5001
    set_env_variable TF_VAR_openclone_sadtalker_hostaddress "http://openclone-sadtalker-clusterip:$TF_VAR_openclone_sadtalker_port"

    set_env_variable TF_VAR_openclone_u2net_port 5002
    set_env_variable TF_VAR_openclone_u2net_hostaddress "http://openclone-u-2-net-clusterip:$TF_VAR_openclone_u2net_port"

    ################################################################################
    ######## ALIASES ###############################################################
    ################################################################################
    
    echo 'source /scripts/shell-helpers/aliases.sh' >> ~/.bashrc

    ################################################################################
    ######## KUBERNETES ENVIRONMENT ################################################
    ################################################################################

    set_env_variable kind_kube_config_path "/terraform/kind-kube-config.yaml"
    set_env_variable vultr_dev_kube_config_path "/terraform/vultr-dev-kube-config.yaml"
    # TF_VAR_kube_config_path <----- this is the actual kube_config that's used. it gets set in environment.sh
    switch_environment $(get_terraform_environment) # use kind as default but prefer environment that was used before rebuild
    set_env_variable kubernetes_version "v1.31.2+1" # this is the remote version. make sure it matches the kubectl you install in your dockerfile

    ################################################################################
    ######## VULTR KUBERNETES CONFIGURATIONS #######################################
    ################################################################################

    set_env_variable vultr_region "ewr"
    set_env_variable vultr_cluster_label "openclone-cluster"
    set_env_variable vultr_database_node_pool_label "database-node-pool"

    ################################################################################
    ######## SECRETS ###############################################################
    ################################################################################

    set_env_variable TF_VAR_postgres_password "puppies"
    set_env_variable TF_VAR_openclone_openclonedb_password "kittens"
    set_env_variable TF_VAR_openclone_logdb_password "bunnies"
    set_env_variable TF_VAR_vultr_api_key "---"
    set_env_variable TF_VAR_openclone_jwt_secretkey "5EC40A39-A73C-46F5-B620-40E317CB40A6-7DD04875-FD50-4F95-B45B-B969750467DF"
    set_env_variable TF_VAR_openclone_openai_api_key "---"
    set_env_variable TF_VAR_openclone_googleclientid "---"
    set_env_variable TF_VAR_openclone_googleclientsecret "---"
    set_env_variable TF_VAR_openclone_elevenlabsapikey "---"
    set_env_variable TF_VAR_openclone_email_dkim "v=DKIM1; k=rsa; p=---"


    ################################################################################
    ######## CONNECTION STRINGS ####################################################
    ################################################################################

    # internal means within the cluster
    set_env_variable TF_VAR_internal_openclone_defaultconnection "Host=openclone-database-clusterip;Port=5432;Database=$TF_VAR_openclone_openclonedb_name;Username=$TF_VAR_openclone_openclonedb_user;Password=$TF_VAR_openclone_openclonedb_password;Include Error Detail=true;"
    set_env_variable TF_VAR_internal_openclone_logdbconnection "Host=openclone-database-clusterip;Port=5432;Database=$TF_VAR_openclone_logdb_name;Username=$TF_VAR_openclone_logdb_user;Password=$TF_VAR_openclone_logdb_password;"

    ################################################################################
    ######## OTHER ENVIRONMENT VARIABLES ###########################################
    ################################################################################

    # TODO: this is terrible! you should brin all environment variables in from the host computer!!! (you might not have been able to do that when you set this up. but now you have lots of different ways devcontainer-host coudl probably help)    set_
    set_env_variable TF_VAR_OpenClone_Root_Dir "C:/Users/seanm/Desktop"
    set_env_variable kind_registry_name registry # todo: rename to kind-registry
    set_env_variable kind_registry_host kind-registry.local # todo: rename to kind-registry

    set_env_variable kind_registry_hostname "kind-registry.local"
    set_env_variable kind_registry_port "5000"
    set_env_variable kind_config_path "/scripts/cluster_create_and_destroy/kind/config/kind-config.yaml"
    kind_config_path_template="/scripts/cluster_create_and_destroy/kind/config/kind-config-template.yaml"
    envsubst < $kind_config_path_template > $kind_config_path
}
setup_container
echo "setup-container.sh complete!" # inform the user of our success.