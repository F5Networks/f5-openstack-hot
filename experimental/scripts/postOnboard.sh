#!/bin/bash

err=0
msg="Post-onboard completed without error."
stat="SUCCESS"
keepAdmin="__keep_admin__"
keepConfigDrive="__keep_config_drive__"
keepBigIq="__keep_bigiq__"

function cleanup() {
    shred -u -z  /config/cloud/openstack/rootPwd /config/cloud/openstack/rootPwdRandom /config/cloud/openstack/adminPwdRandom

    if [[ "$keepAdmin" == "False" ]]; then
       shred -u -z /config/cloud/openstack/adminPwd
    fi

    if [[ "$keepBigIq" == "False" ]]; then
      shred -u -z /config/cloud/openstack/bigIqPwd
    fi

    if [[ "$keepConfigDrive" == "False" ]]; then
        mountFound=$(grep '/mnt/config' /proc/mounts -c)
        if [[ $mountFound == 1 ]] ; then
            umount /mnt/config
            rmdir /mnt/config
        fi
    fi
}

function run_custom_config() {
    echo 'Running custom configuration commands, if any'
    ### START CUSTOM CONFIGURATION ###

    ### END CUSTOM CONFIGURATION ###`
}

function send_heat_signal() {
    echo "$msg"
    wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30
}

function main() {
    echo '*****POST-ONBOARD STARTING******'

    if ! cleanup ; then
        err+=1
    fi

    if ! run_custom_config ; then
        err+=1
    fi

    if [[ err -ne 0 ]]; then
        msg="Post-onboard command(s) exited with an error signal."
        stat="FAILURE"
    fi

    send_heat_signal

    echo '*****POST-ONBOARD DONE******'
}

main
