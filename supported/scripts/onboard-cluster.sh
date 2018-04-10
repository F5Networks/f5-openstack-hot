#!/bin/bash
echo '******Starting Cluster Configuration******'

msg=""
stat="FAILURE"
deviceName="__host_name__"
wcNotifyOptions="__wc_notify_options__"

masterIp="__master_mgmt_ip__"
mgmtIp="__mgmt_ip__"
configSyncIp="__config_sync_ip__"
configSyncCidr="__config_sync_cidr__"
configSyncVlan="__config_sync_vlan__"
autoSync="__auto_sync__"
saveOnAutoSync="__save_on_auto_sync__"

if [ "$wcNotifyOptions" == "None" ]; then
    wcNotifyOptions=""
else
    wcNotifyOptions=" $wcNotifyOptions"
fi

if [[ "$autoSync" == "True" ]]; then
    autoSync="--auto-sync"

    if [[ "$saveOnAutoSync" == "True" ]]; then
        saveOnAutoSync="--save-on-auto-sync"
    else
        saveOnAutoSync=""
    fi
else
    autoSync=""
fi

isMaster=false
if [[ "$mgmtIp" == "$masterIp" ]]; then
    isMaster=true
fi

deviceCurr=$(tmsh list cm device | grep bigip1 -c)
if [[ "$deviceCurr" -gt 0 ]]; then
  echo 'Warning: DeviceName is showing as default bigip1. Manually changing'

  if [[ "$deviceName" == "" || "$deviceName" == "None"  ]]; then
    echo 'building hostname manually - no fqdn returned from neutron port assignment'
    dnsSuffix=$(/bin/grep search /etc/resolv.conf |n awk '{print $2}')
    hostName="host-$mgmtIp.$dnsSuffix"
  else
    deviceName=${deviceName%.}
  fi
  tmsh mv cm device bigip1 "$deviceName"
else
  hostName=$(tmsh list cm device one-line | awk '{print $3}')
  echo "Using hostName: $hostName"
  deviceName="$hostName"
fi

echo 'Configuring config-sync ip'
if [[ $(tmsh list net self | grep "address $configSyncIp" -c) == 0 ]]; then
    echo 'Configuring cluster self-ip'
    tmsh create net self cluster_self address "$configSyncIp/$configSyncCidr" vlan "$configSyncVlan" allow-service add { tcp:4353 udp:1026 tcp:443 }
else
    echo 'Ensuring correct port lockdown configured for cluster ip'
    cluster_self=$(tmsh list net self | grep "address $configSyncIp" -C 1 | grep self | awk '{print $3}')
    tmsh modify net self "$cluster_self" allow-service add { tcp:4353 udp:1026 tcp:443 }
fi
tmsh modify cm device "$deviceName" configsync-ip $configSyncIp unicast-address { { effective-ip $configSyncIp effective-port 1026 ip $configSyncIp } }

if [[ "$isMaster" == true ]] ; then
echo 'Config-Sync Master device'
    f5-rest-node /config/cloud/openstack/node_modules/@f5devcentral/f5-cloud-libs/scripts/cluster.js \
    -o /var/log/cloud/openstack/onboard-cluster.log \
    --log-level debug \
    --host __mgmt_ip__\
    --user admin \
    --password-url file:///config/cloud/openstack/.adminPwd \
    --password-encrypted \
    --port __mgmt_port__ \
    --create-group \
    --device-group __device_group__ \
    --sync-type __sync_type__ \
    --device "$deviceName" \
    --network-failover \
    "$autoSync" \
    "$saveOnAutoSync"
else
echo 'Config-Sync Secondary device'
    f5-rest-node /config/cloud/openstack/node_modules/@f5devcentral/f5-cloud-libs/scripts/cluster.js \
    -o /var/log/cloud/openstack/onboard-cluster.log \
    --log-level debug \
    --host __mgmt_ip__\
    --user admin \
    --password-url file:///config/cloud/openstack/.adminPwd \
    --password-encrypted \
    --port __mgmt_port__ \
    --join-group \
    --device-group __device_group__ \
    --sync \
    --remote-host __master_mgmt_ip__ \
    --remote-user admin \
    --remote-password-url file:///config/cloud/openstack/.adminPwd

fi

onboardClusterErrorCount=$(tail /var/log/cloud/openstack/onboard-cluster.log -n 25 | grep "cluster failed" -i -c)

if [ "$onboardClusterErrorCount" -gt 0 ]; then
    msg="Onboard-cluster command exited with error. See /var/log/cloud/openstack/onboard-cluster.log for details."
else
    stat="SUCCESS"
    msg="Onboard-cluster command exited without error."
fi


msg="$msg *** Instance: $deviceName"
echo "$msg"
wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30$wcNotifyOptions
