#!/bin/bash
echo '*****ONBOARD STARTING******'

#vars
#some default values set by heat str_replace

#licensing
licenseKey="__license__"
licenseOpt="--license"
addOnLicenses="__add_on_licenses__"
bigIqHost="__bigiq_host__"
bigIqUsername="__bigiq_username__"
bigIqLicPool="__bigiq_lic_pool__"
bigIqUseAltMgmtIp="__bigiq_use_alt_mgmt_ip__"
bigIqAltMgmtIp="__bigiq_alt_mgmt_ip__"
bigIqAltMgmtPort="__bigiq_alt_mgmt_port__"
bigIqPwdUri="file:///config/cloud/openstack/bigIqPwd"
bigIqMgmtIp=""
bigIqMgmtPort=""

dns="__dns__"
hostName="__host_name__"
mgmtPortId="__mgmt_port_id__"
adminPwd=""
newRootPwd=""
oldRootPwd=""
msg=""
stat="FAILURE"
logFile="/var/log/cloud/openstack/onboard.log"

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
    if [ "$addOnLicenses" == "--add-on None" ]; then
        addOnLicenses=""
    fi

    if [ "$dns" == "--dns None" ]; then
        dns=""
    fi

    if [ "$licenseType" == "BIGIQ" ]; then
        if [ "$bigIqUseAltMgmtIp" == "True" ]; then
            bigIqMgmtIp="--big-ip-mgmt-address ${bigIqAltMgmtIp}"

            if [ "$bigIqAltMgmtPort" != "None" ]; then
                bigIqMgmtPort="--big-ip-mgmt-port ${bigIqAltMgmtPort}"
            fi
        fi
        licenseOpt="--license-pool"
        license="--license-pool-name ${bigIqLicPool} --big-iq-host ${bigIqHost} --big-iq-user ${bigIqUsername} --big-iq-password-uri ${bigIqPwdUri} ${bigIqMgmtIp} ${bigIqMgmtPort}"
    else
        if [ "${licenseKey,,}" == "none" ]; then
            license=""
            licenseOpt=""
        else
            license="${licenseKey}"
        fi
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
        oldRootPwd=$(</config/cloud/openstack/rootPwd)
    else
        oldRootPwd=$(</config/cloud/openstack/rootPwdRandom)
    fi

    adminPwd=$(</config/cloud/openstack/adminPwd)
    newRootPwd=$(</config/cloud/openstack/rootPwd)

    if [[ "$allowUsageAnalytics" == "True" ]]; then
        bigIpVersion=$(tmsh show sys version | grep -e "Build" -e " Version" | awk '{print $2}' ORS=".")
        metrics="customerId:${custId},deploymentId:${deployId},templateName:${templateName},templateVersion:${templateVersion},region:${region},bigIpVersion:${bigIpVersion},licenseType:${licenseType},cloudLibsVersion:${cloudLibsTag},cloudName:openstack"
        metricsOpt="--metrics"
        echo "$metrics"
    fi
}

function set_adminPwd() {
    tmsh modify auth user admin shell tmsh password "$adminPwd"
}

function onboard_run() {
    echo 'Starting Onboard call'
    if f5-rest-node /config/cloud/openstack/node_modules/f5-cloud-libs/scripts/onboard.js \
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
        --set-root-password old:"$oldRootPwd",new:"$newRootPwd" \
        --tz UTC \
        --user admin --password-url file:///config/cloud/openstack/adminPwd ; then

        licenseExists=$(tail /var/log/cloud/openstack/onboard.log -n 25 | grep "Fault code: 51092" -i -c)

        if [ "$licenseExists" -gt 0 ]; then
            msg="Onboard completed but licensing failed. Error 51092: This license has already been activated on a different unit."
            stat="SUCCESS"
        else
            errorCount=$(tail /var/log/cloud/openstack/onboard.log | grep "BIG-IP onboard failed" -i -c)

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
