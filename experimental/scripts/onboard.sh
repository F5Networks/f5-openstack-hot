#!/bin/bash

echo '*****ONBOARD STARTING******'

logFile="/var/log/onboard.log"
onboardRun=$(grep "Starting Onboard call" -i -c -m 1 "$logFile" )
if [ "$onboardRun" -gt 0 ]; then
    echo 'WARNING: onboard already previously ran.'
    oldRootPwd=$(</config/cloud/openstack/rootPwd)
else
    oldRootPwd=$(</config/cloud/openstack/rootPwdRandom)
fi

addOn_licenses="__add_on_licenses__"
dns="__dns__"
hostName="__host_name__"
hostName=${hostName%.}
useConfigDrive="__use_config_drive__"
adminPwd=$(</config/cloud/openstack/adminPwd)
newRootPwd=$(</config/cloud/openstack/rootPwd)

if [ "$addOn_licenses" == "--add-on None" ]; then
    addOn_licenses="" 
fi

if [ "$dns" == "--dns None" ]; then
    dns=""
fi

echo 'Temporary workaround for update-user'
tmsh modify auth user admin shell tmsh password "$adminPwd"

if [[ $hostName == "" ]]; then
configDriveDest="/mnt/config"
    echo 'Attempting to retrieve hostname from metadata'
    if [[ "$useConfigDrive" == "True" ]]; then
        hostName=$(python -c 'import sys, json; print json.load(sys.stdin)["hostname"]' <"$configDriveDest"/openstack/latest/meta_data.json)
    else
        hostName=$(curl -s -f --retry 20 http://169.254.169.254/latest/meta-data/hostname)
    fi
fi

msg=""
stat="FAILURE"

echo 'Starting Onboard call'
if f5-rest-node /config/cloud/openstack/node_modules/f5-cloud-libs/scripts/onboard.js \
    $addOn_licenses \
    $dns \
    --host localhost \
    --hostname "$hostName" \
    --license "__license__" \
    --log-level debug \
    __modules__ \
    __ntp__ \
    --output "$logFile" \
    --port __mgmt_port__ \
    --set-root-password old:"$oldRootPwd",new:"$newRootPwd" \
    --tz UTC \
    --user admin --password-url file:///config/cloud/openstack/adminPwd ; then

    licenseExists=$(tail /var/log/onboard.log -n 25 | grep "Fault code: 51092" -i -c)

    if [ "$licenseExists" -gt 0 ]; then
        msg="Onboard command failed. Error 51092: This license has already been activated on a different unit."
    else
        errorCount=$(tail /var/log/onboard.log | grep "BIG-IP onboard failed" -i -c)

        if [ "$errorCount" -gt 0 ]; then
            msg="Onboard command failed. See logs for details."
        else
            msg="Onboard command exited without error."
            stat="SUCCESS"
        fi
    fi
else
    msg='Onboard exited with an error signal.'
fi

echo "$msg"
wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30