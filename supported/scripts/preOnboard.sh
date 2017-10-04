#!/bin/bash
echo '******STARTING PRE-ONBOARD******'

verifyHashOverride="__verify_hash_override__"

if [[ "$verifyHashOverride" != "" && "$verifyHashOverride" != "None" ]]; then
    curl ${verifyHashOverride} > /config/verifyHash
fi

msg=""
stat=""

#*************************************************************************************************
echo 'Starting MCP status check'
checks=0
while [ $checks -lt 120 ]; do echo checking mcpd
    if tmsh -a show sys mcp-state field-fmt | grep -q running; then
        echo mcpd ready
        break
    fi
    echo mcpd not ready yet
    let checks=checks+1
    sleep 10
done
echo loading verifyHash script
if ! tmsh load sys config merge file /config/verifyHash; then
    echo cannot validate signature of /config/verifyHash
    msg="Unable to validate verifyHash."
fi
echo loaded verifyHash
declare -a filesToVerify=(/config/cloud/openstack/f5-cloud-libs.tar.gz)
for fileToVerify in "${filesToVerify[@]}"
do
    echo verifying "$fileToVerify"
    if ! tmsh run cli script verifyHash "$fileToVerify"; then
        echo "$fileToVerify" is not valid
        msg="Unable to verify one or more files."
    fi
    echo verified "$fileToVerify"
done

#*************************************************************************************************
if [[ "$msg" == "" ]]; then
    echo 'Preparing CloudLibs'
    mkdir -p /config/cloud/openstack/node_modules
    tar xvfz /config/cloud/openstack/f5-cloud-libs.tar.gz -C /config/cloud/openstack/node_modules
    touch /config/cloud/openstack/cloudLibsReady
fi

#*************************************************************************************************
echo 'Configuring access to cloud-init data'
useConfigDrive="__use_config_drive__"
configDriveSrc=$(blkid -t LABEL="config-2" -odevice)
configDriveDest="/mnt/config"

if [[ "$useConfigDrive" == "True" ]]; then
    echo 'Configuring Cloud-init ConfigDrive'
    mkdir -p $configDriveDest
    if mount "$configDriveSrc" $configDriveDest; then
        echo 'Adding SSH Key from Config Drive'
        if sshKey=$(python -c 'import sys, json; print json.load(sys.stdin)["public_keys"]["__ssh_key_name__"]' <"$configDriveDest"/openstack/latest/meta_data.json) ; then
            echo "$sshKey" >> /root/.ssh/authorized_keys
        else
            msg="Pre-onboard failed: Unable to inject SSH key from config drive."
            echo "$msg"
        fi
    else
        msg="Pre-onboard failed: Unable to mount config drive."
        echo "$msg"
    fi

else
    echo 'Adding SSH Key from Metadata service'
    declare -r tempKey="/config/cloud/openstack/os-ssh-key.pub"
    if curl http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key -s -f --retry 5   --retry-max-time 300 --retry-delay 10 -o $tempKey ; then
        (head -n1 $tempKey) >> /root/.ssh/authorized_keys 
        rm $tempKey
    else
        msg="Pre-onboard failed: Unable to inject SSH key from metadata service."
        stat="FAILURE"
        echo "$msg"
    fi
fi

#*************************************************************************************************
#buffer wait before sending heat signal
sleep 120

if [[ "$msg" == "" ]]; then
    stat="SUCCESS"
    msg="Pre-onboard completed without error."
else
    stat="FAILURE"
    msg="Last Error:$msg . See /var/log/preOnboard.log for details."
fi

wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30
echo "$msg"
echo '******PRE-ONBOARD DONE******'
