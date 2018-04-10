#!/bin/bash
echo '******Starting Autoscale Configuration******'

msg=""
stat="FAILURE"
iCallName="ClusterUpdate"
mgmtIp="__mgmt_ip__"
mgmtPort="__mgmt_port__"
deviceGroup="__device_group__"
hostName="__host_name__"
useConfigDrive="__use_config_drive__"

instanceUrl=""
autoscaleGroupTag="__autoscale_group_tag__"
autoscaleMetadataUrl="__autoscale_metadata_url__"
autoscaleMetadataResource="__autoscale_metadata_resource__"
autoscaleStack="__autoscale_stack__"
osCreds="file:///config/cloud/openstack/.os"

bigIqHost="__bigiq_host__"
bigIqUser="__bigiq_username__"
bigIqPwdUri="file:///config/cloud/openstack/.bigIqPwd"
bigIqLicPool="__bigiq_lic_pool__"
bigIqMgmtIp="__bigiq_alt_mgmt_ip__"
bigIqMgmtPort="__bigiq_alt_mgmt_port__"
bigIqUseAltMgmt="__bigiq_use_alt_mgmt_ip__"

wcNotifyOptions="__wc_notify_options__"

function set_vars(){
    if [ "$wcNotifyOptions" == "None" ]; then
        wcNotifyOptions=""
    else
        wcNotifyOptions=" $wcNotifyOptions"
    fi

    if [[ $hostName == "" ]]; then
        configDriveDest="/mnt/config"
        echo 'Attempting to retrieve hostname from metadata'
        if [[ "$useConfigDrive" == "True" ]]; then
            hostName=$(python -c 'import sys, json; print json.load(sys.stdin)["hostname"]' <"$configDriveDest"/openstack/latest/meta_data.json)
        else
            hostName=$(curl -s -f --retry 20 http://169.254.169.254/latest/meta-data/hostname)
        fi
    fi

    deviceCurr=$(tmsh list cm device | grep bigip1 -c)
    if [[ "$deviceCurr" -gt 0 ]]; then
        echo 'Warning: DeviceName is showing as default bigip1. Manually changing'
        tmsh mv cm device bigip1 "$hostName"
    fi

    if [[ "$useConfigDrive" == "True" ]]; then
        instanceUrl="file:///mnt/config/openstack/latest/meta_data.json"
    else
        instanceUrl="http://169.254.169.254/openstack/latest/meta_data.json"
    fi

    if [[ "$bigIqUseAltMgmt" != "True" ]]; then
        bigIqMgmtIp="$mgmtIp"
    fi

    if [[ "$bigIqMgmtPort" == "None" ]]; then
        bigIqMgmtPort="$mgmtPort"
    fi

    # escape ampersand
    autoscaleMetadataUrl=${autoscaleMetadataUrl/&/\\&}
    # remove trailing .
    hostName=${hostName%.}
}

function run_autoscale() {
  local logMessage="$1"
  local clusterAction="$2"
  local addtlParam="$3"

  echo "$logMessage"

  if f5-rest-node /config/cloud/openstack/node_modules/@f5devcentral/f5-cloud-libs/scripts/autoscale.js \
    --output /var/log/cloud/openstack/onboard-autoscale.log \
    --log-level debug \
    --host "$mgmtIp" \
    --port "$mgmtPort" \
    --user admin \
    --password-url file:///config/cloud/openstack/.adminPwd \
    --password-encrypted \
    --cloud openstack \
    --provider-options instanceMetadataUrl:"$instanceUrl",autoscaleMetadataUrl:"$autoscaleMetadataUrl",osCredentialsUrl:"$osCreds",autoscaleGroupTag:"$autoscaleGroupTag",autoscaleMetadataResource:"$autoscaleMetadataResource",autoscaleStack:"$autoscaleStack" \
    --device-group "$deviceGroup" \
    --network-failover \
    --cluster-action "${clusterAction}" \
    "$addtlParam" \
    --license-pool \
        --license-pool-name "$bigIqLicPool" \
        --big-iq-host "$bigIqHost" \
        --big-iq-user "$bigIqUser" \
        --big-iq-password-uri "$bigIqPwdUri" \
        --big-ip-mgmt-address "$bigIqMgmtIp" \
        --big-ip-mgmt-port "$bigIqMgmtPort" ; then
        return 0;
    else
        return 1;
    fi
}

function create_iCall() {
    local logMessage="Creating periodic iCall for updating cluster data for autoscale"
    local clusterAction="update"
    local addtlParam=""

    echo "$logMessage"

    # create script
    tmsh create sys icall script "$iCallName" \
        definition '{' \
            exec f5-rest-node /config/cloud/openstack/node_modules/@f5devcentral/f5-cloud-libs/scripts/autoscale.js \
                --output /var/log/cloud/openstack/onboard-autoscale.log \
                --log-level debug \
                --host localhost \
                --port "$mgmtPort" \
                --user admin \
                --password-url file:///config/cloud/openstack/.adminPwd \
                --password-encrypted \
                --cloud openstack \
                --provider-options instanceMetadataUrl:"$instanceUrl",autoscaleMetadataUrl:"$autoscaleMetadataUrl",osCredentialsUrl:"$osCreds",autoscaleGroupTag:"$autoscaleGroupTag",autoscaleMetadataResource:"$autoscaleMetadataResource",autoscaleStack:"$autoscaleStack" \
                --device-group "$deviceGroup" \
                --network-failover \
                --cluster-action "$clusterAction" \
                    --license-pool \
                    --license-pool-name "$bigIqLicPool" \
                    --big-iq-host "$bigIqHost" \
                    --big-iq-user "$bigIqUser" \
                    --big-iq-password-uri "$bigIqPwdUri" \
                    --big-ip-mgmt-address "$bigIqMgmtIp" \
                    --big-ip-mgmt-port "$bigIqMgmtPort" \
                "$addtlParam" \
        '}'

    # create handler
    tmsh create sys icall handler periodic /Common/"$iCallName" { first-occurrence now interval 120 script /Common/"$iCallName"  }

    tmsh save /sys config
}

function start_or_join_cluster() {
    local logMessage="**********Starting or Joining cluster**********"
    local clusterAction="join"
    local addtlParam="--block-sync"
    run_autoscale "$logMessage" "${clusterAction}" "${addtlParam}"
    return $?
}

function set_cluster_configsync() {
    if [ -f /config/cloud/master ]; then
        local logMessage="**********Unblock cluster sync - set configsync**********"
        local clusterAction="unblock-sync"
        local addtlParam=""
        run_autoscale "$logMessage" "${clusterAction}" "${addtlParam}"
    fi
    return $?
}

function setup_cluster_update() {
    # check if iCall already exists
    iCallExists=$(tmsh list sys icall handler | grep "$iCallName" -c)

    if [ "$iCallExists" -gt 0 ]; then
        echo "Found iCall handler matching name $iCallName"
    else
        echo "No iCall handler matching name $iCallName. Setting up iCall."
        create_iCall
    fi

    return $?
}

function send_heat_signal() {
    if [ -f /var/log/cloud/openstack/onboard-autoscale.log ]; then
        onboardAutoscaleErrorCount=$(tail /var/log/cloud/openstack/onboard-autoscale.log -n 25 | grep "error" -i -c)

        if [ "$onboardAutoscaleErrorCount" -gt 0 ]; then
            msg="Onboard-autoscale command exited with error. See /var/log/cloud/openstack/onboard-autoscale.log for details."
        else
            stat="SUCCESS"
            msg="Onboard-autoscale command exited without error."
        fi
    else
        msg="Onboard-autoscale log not found and command not run successfully. See /var/log/cloud/openstack/runScript.log for details. "
    fi

    msg="$msg *** Instance: $hostName"
    echo "$msg"
    wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30$wcNotifyOptions
}

function main() {
    local logMessage=""
    set_vars
    onboardErrorCount=$(tail /var/log/cloud/openstack/onboard.log -n 25 | grep "BIG-IP onboard failed" -i -c)
    if [[ "$onboardErrorCount" -gt 0 ]]; then
     logMessage="ERROR: Onboard command did not finish successfuly. Unable to proceed with autoscale set up."
        echo "$logMessage" >> /var/log/cloud/openstack/onboard-autoscale.log
    else
        if start_or_join_cluster ; then
            if set_cluster_configsync ; then
                if setup_cluster_update ; then
                    logMessage="Successfully setup iCall for cluster updates."
                else
                    "ERROR: Set up iCall cluster update failed. Unable to proceed with autoscale set up."
                fi
            else
                logMessage="ERROR: Set cluster configsync failed. Unable to proceed with autoscale set up."
            fi
        else
            logMessage="ERROR: Start or join cluster failed. Unable to proceed with autoscale set up."
        fi

    fi

    send_heat_signal
}

main
