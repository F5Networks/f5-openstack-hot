#!/bin/bash
echo '*****ONBOARD STARTING******'

#vars
#some default values set by heat str_replace

#licensing
licenseKey="__license__"
licenseOpt=""
license=""
addOnLicenses="__add_on_licenses__"
dns="__dns__"
hostName="__host_name__"
mgmtPortId="__mgmt_port_id__"
dbVars="__db_vars__"
tz="__timezone__"
msg=""
stat="FAILURE"
lastError=""
logFile="/var/log/cloud/openstack/onboard.log"
wcNotifyOptions="__wc_notify_options__"

allowUsageAnalytics="__allow_ua__"
templateName="__template_name__"
templateVersion="__template_version__"
cloudLibsTag="__cloudlibs_tag__"
custId=$(echo "__cust_id__"|sha512sum|cut -d " " -f 1)
deployId=$(echo "__deploy_id__"|sha512sum|cut -d " " -f 1)
region="__region__"
metrics=""
metricsOpt=""
licenseType="__license_type__"

function set_vars() {
    if [ "$wcNotifyOptions" == "None" ]; then
        wcNotifyOptions=""
    else
        wcNotifyOptions=" $wcNotifyOptions"
    fi

    if [ "$addOnLicenses" == "--add-on None" ]; then
        addOnLicenses=""
    fi

    if [ "$dns" == "--dns None" ]; then
        dns=""
    fi

    if [ "$dbVars" == "--db None" ]; then
        dbVars=""
    fi

    if [ "$licenseType" == "NO_LIC" ]; then
        license=""
        licenseOpt=""
        addOnLicenses=""
    else
        licenseOpt="--license"
        license="${licenseKey}"
    fi


    if [[ "$hostName" == "" || "$hostName" == "None" ]]; then
        echo 'using mgmt neutron portid as hostname - no fqdn returned from neutron port assignment'
        # get first matching domain
        dnsSuffix=$(/bin/grep search /etc/resolv.conf | awk '{print $2}')
        if [[ "$dnsSuffix" == "" ]]; then
            dnsSuffix="openstacklocal"
        fi
            hostName="host-$mgmtPortId.$dnsSuffix"
    else
        #remove trailing . from fqdn
        hostName=${hostName%.}
    fi

    onboardRun=$(grep "Starting Onboard call" -i -c -m 1 "$logFile" )
    if [ "$onboardRun" -gt 0 ]; then
        echo 'WARNING: onboard already previously ran.'
    fi

    if [[ "$allowUsageAnalytics" == "True" ]]; then
        bigIpVersion=$(tmsh show sys version | grep -e "Build" -e " Version" | awk '{print $2}' ORS=".")
        metrics="customerId:${custId},deploymentId:${deployId},templateName:${templateName},templateVersion:${templateVersion},region:${region},bigIpVersion:${bigIpVersion},licenseType:${licenseType},cloudLibsVersion:${cloudLibsTag},cloudName:openstack"
        metricsOpt="--metrics"
        echo "$metrics"
    fi
}


function onboard_run() {
    echo 'Starting Onboard call'
    if f5-rest-node /config/cloud/openstack/node_modules/@f5devcentral/f5-cloud-libs/scripts/onboard.js \
        $metricsOpt $metrics \
        $addOnLicenses \
        $dns \
        --host localhost \
        --hostname "$hostName" \
        $licenseOpt $license \
        --log-level debug \
        __modules__ \
        __ntp__ \
        --output "$logFile" \
        --port __mgmt_port__ \
        --tz $tz \
        $dbVars \
        --user admin --password-url file:///config/cloud/openstack/.adminPwd \
        --password-encrypted ; then

        # older cloud-libs versions exit with 0 signal
        licenseExists=$(tail $logFile -n 25 | grep "Fault code: 51092" -i -c)

        if [ "$licenseExists" -gt 0 ]; then
            msg="Onboard completed but licensing failed. Error 51092: This license has already been activated on a different unit."
            stat="SUCCESS"
        else
            errorCount=$(tail $logFile -n 25 | grep "BIG-IP onboard failed" -i -c)

            if [ "$errorCount" -gt 0 ]; then
                lastError=$(grep "error: \[pid" $logFile | tail -n 1)
                msg="Onboard command failed. See logs for details. Most recent error: $lastError"
            else
                msg="Onboard command exited without error."
                stat="SUCCESS"
            fi

        fi
    else
        licenseExists=$(tail $logFile -n 25 | grep "Fault code: 51092" -i -c)
        if [ "$licenseExists" -gt 0 ]; then
            msg="Onboard completed but licensing failed. Error 51092: This license has already been activated on a different unit."
            stat="SUCCESS"
        else
            lastError=$(grep "error: \[pid" $logFile | tail -n 1)
            msg="Onboard exited with an error signal. See logs for details. Most recent error: $lastError"
            # escape \, /, ' and " for json
            msg=${msg//\\/\\\\}
            msg=${msg//\'/\\\'}
            msg=${msg//\//\\\/}
            msg=${msg//\"/\\\"}
        fi
    fi
}

function send_heat_signal() {
    echo "$msg"
    wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30$wcNotifyOptions
}

function main() {
    set_vars
    onboard_run
    send_heat_signal
}

main
