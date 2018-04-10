#!/bin/bash

err=0
msg="Post-onboard completed without error."
stat="SUCCESS"
keepAdmin="__keep_admin__"
keepConfigDrive="__keep_config_drive__"
keepBigIq="__keep_bigiq__"
setMgmtMtu="__set_mgmt_mtu__"
mgmtMtu="__mgmt_mtu__"
mgmtNic="__mgmt_nic__"
wcNotifyOptions="__wc_notify_options__"

function cleanup() {
    if [[ "$keepAdmin" == "False" ]]; then
       shred -u -z /config/cloud/openstack/.adminPwd
    fi

    if [[ "$keepBigIq" == "False" ]]; then
      shred -u -z /config/cloud/openstack/.bigIqPwd
    fi

    if [[ "$keepConfigDrive" == "False" ]]; then
        mountFound=$(grep '/mnt/config' /proc/mounts -c)
        if [[ $mountFound == 1 ]] ; then
            umount /mnt/config
            rmdir /mnt/config
        fi
    fi

    cloudDir=$(grep -i cloud_dir /etc/cloud/cloud.cfg | awk '{print $2}')
    find "$cloudDir" -type f -execdir shred -u '{}' \;
    tmsh modify sys db service.cloudinit value disable
}

function run_custom_config() {
    echo 'Running custom configuration commands, if any'
    ### START CUSTOM CONFIGURATION ###

    ### END CUSTOM CONFIGURATION ###`
}

function set_mgmt_mtu() {
    # in some cases, mtu needs to be reset after onboard completes.
    if [[ "$setMgmtMtu" == "True" ]]; then
        echo 'Setting management mtu'
            if ! ip link set $mgmtNic mtu $mgmtMtu ; then
                echo 'Unable to set MTU value'
            fi
    fi
}

function send_heat_signal() {
    echo "$msg"
    if [ "$wcNotifyOptions" == "None" ]; then
        wcNotifyOptions=""
    else
        wcNotifyOptions=" $wcNotifyOptions"
    fi
    wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30$wcNotifyOptions
}

function main() {
    echo '*****POST-ONBOARD STARTING******'

    if ! set_mgmt_mtu ; then
        err+=1
    fi

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
