#!/bin/bash
while true; do echo 'checking if mgmt setup ready'
    if [ -f /config/setup-staticMgmt.sh ]; then
        if [ -f /config/cloud/openstack/staticMgmtReady ]; then
            break
        else
            sleep 10
        fi
    else
        break
    fi
done
