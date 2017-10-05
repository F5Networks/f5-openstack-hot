#!/bin/bash
echo '******Starting Cluster Configuration******'

msg=""
stat="FAILURE"
deviceName="__host_name__"
deviceName=${deviceName%.}
masterIp="__master_mgmt_ip__"
configSyncIp="__config_sync_ip__"
useConfigDrive="__use_config_drive__"
autoSync="__auto_sync__"
saveOnAutoSync="__save_on_auto_sync__"

if [[ $deviceName == "" ]]; then
    configDriveDest="/mnt/config"
    echo 'Attempting to retrieve hostname from metadata'
    if [[ "$useConfigDrive" == "True" ]]; then
        deviceName=$(python -c 'import sys, json; print json.load(sys.stdin)["hostname"]' <"$configDriveDest"/openstack/latest/meta_data.json)
    else
        deviceName=$(curl -s -f --retry 20 http://169.254.169.254/latest/meta-data/hostname)
    fi
fi

if [[ "$autoSync" == "True" ]]; then
    autoSync="--auto-sync"

    if [[ "$saveOnAutoSync=" == "True" ]]; then
        saveOnAutoSync="--save-on-auto-sync"
    else
        saveOnAutoSync=""
    fi
else
    autoSync=""
fi

isMaster=false
if [[ "__mgmt_ip__" == "$masterIp" ]]; then
    isMaster=true
fi

deviceCurr=$(tmsh list cm device | grep bigip1 -c)
if [[ "$deviceCurr" -gt 0 ]]; then
    echo 'Warning: DeviceName is showing as default bigip1. Manually changing'
    tmsh mv cm device bigip1 "$deviceName"
fi

echo 'Configuring config-sync ip'
tmsh modify cm device "$deviceName" configsync-ip $configSyncIp unicast-address { { effective-ip $configSyncIp effective-port 1026 ip $configSyncIp } }

if [[ "$isMaster" == true ]] ; then 
echo 'Master device'
    f5-rest-node /config/cloud/openstack/node_modules/f5-cloud-libs/scripts/cluster.js \
    -o /var/log/onboard-cluster.log \
    --log-level debug \
    --host __mgmt_ip__\
    --user admin \
    --password-url file:///config/cloud/openstack/adminPwd \
    --port __mgmt_port__ \
    --create-group \
    --device-group __device_group__ \
    --sync-type __sync_type__ \
    --device "$deviceName" \
    --network-failover \
    "$autoSync" \
    "$saveOnAutoSync"
else
echo 'Standby device'
    f5-rest-node /config/cloud/openstack/node_modules/f5-cloud-libs/scripts/cluster.js \
    -o /var/log/onboard-cluster.log \
    --log-level debug \
    --host __mgmt_ip__\
    --user admin \
    --password-url file:///config/cloud/openstack/adminPwd \
    --port __mgmt_port__ \
    --join-group \
    --device-group __device_group__ \
    --sync \
    --remote-host __master_mgmt_ip__ \
    --remote-user admin \
    --remote-password-url file:///config/cloud/openstack/adminPwd 

fi

onboardClusterErrorCount=$(tail /var/log/onboard-cluster.log | grep "cluster failed" -i -c)

if [ "$onboardClusterErrorCount" -gt 0 ]; then
    msg="Onboard-cluster command exited with error. See /var/log/onboard-cluster.log for details."
else
    stat="SUCCESS"
    msg="Onboard-cluster command exited without error."
fi


msg="$msg *** Instance: $deviceName"
echo "$msg"
wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30