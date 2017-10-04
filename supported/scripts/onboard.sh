#!/bin/bash
echo '*****ONBOARD STARTING******'

#vars
#some default values set by heat str_replace
addOn_licenses="__add_on_licenses__"
dns="__dns__"
hostName="__host_name__"
mgmtIp="__mgmt_ip__"
adminPwd=""
newRootPwd=""
oldRootPwd=""
msg=""
stat="FAILURE"
logFile="/var/log/onboard.log"

function set_vars() {
    if [ "$addOn_licenses" == "--add-on None" ]; then
        addOn_licenses="" 
    fi

    if [ "$dns" == "--dns None" ]; then
        dns=""
    fi

    #remove trailing . from fqdn
    hostName=${hostName%.}
    if [[ $hostName == "" ]]; then
        echo 'building hostname manually - no fqdn returned from neutron port assignment'
        dnsSuffix=$(/bin/grep search /etc/resolv.conf | awk '{print $2}')
        hostName="host-$mgmtIp.$dnsSuffix"
    fi

    onboardRun=$(grep "Starting Onboard call" -i -c -m 1 "$logFile" )
    if [ "$onboardRun" -gt 0 ]; then
        echo 'WARNING: onboard already previously ran.'
        oldRootPwd=$(</config/cloud/openstack/rootPwd)
    else
        oldRootPwd=$(</config/cloud/openstack/rootPwdRandom)
    fi

    adminPwd=$(</config/cloud/openstack/adminPwd)
    newRootPwd=$(</config/cloud/openstack/rootPwd)
}

function set_adminPwd() {
    tmsh modify auth user admin shell tmsh password "$adminPwd"
}

function onboard_run() {
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
            msg="Onboard completed but licensing failed. Error 51092: This license has already been activated on a different unit."
            stat="SUCCESS"
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
}

function send_heat_signal() {
    echo "$msg"
    wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30
}

function main() {
    set_vars
    set_adminPwd
    onboard_run
    send_heat_signal
}

main