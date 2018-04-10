#!/bin/bash

function wait_cloud_libs_install() {
    #TODO: parameterize an initial sleep
    while true; do echo 'waiting for cloud libs install to complete'
        if [ -f /config/cloud/openstack/cloudLibsReady ]; then
            break
        else
            sleep 10
        fi
    done
}

function main() {
    wait_cloud_libs_install
}

main
