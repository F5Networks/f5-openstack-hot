#!/bin/bash
echo '******Starting Additional Network Configuration******'

default_gateway="__default_gateway__"
vlan_create="__network_vlan_create__"
vlan_name="__network_vlan_name__"
vlan_tag="__network_vlan_tag__"
vlan_mtu=__network_vlan_mtu__
vlan_nic=__network_vlan_nic__
vlan_allow="__network_vlan_allow__"

vlan_selfip=__network_vlan_selfip_addr__
selfip_name=__network_vlan_selfip_name__
selfip_cidr=__network_vlan_cidr_block__
selfip_prefix=${selfip_cidr#*/}

if [[ "$default_gateway" == "None" ]]; then
    default_gateway=""
    gateway_opt=""
else
    default_gateway="${default_gateway}"
    gateway_opt="--default-gw"
fi

if [[ "$vlan_create" == "True" ]]; then
    if [ "$vlan_mtu" == "0" ]; then
        vlan_mtu=""
    else
        vlan_mtu=",mtu:$vlan_mtu"
    fi

    if [ "$vlan_tag" == "None" ]; then
        vlan_tag=""
    else
        vlan_tag=",vlan:${vlan_tag}" 
    fi
    vlan="name:${vlan_name},nic:${vlan_nic}${vlan_mtu}${vlan_tag}"
    vlan_opt="--vlan"
else
    vlan=""
    vlan_opt=""
fi


if [ "$vlan_allow" == " " ]; then
    vlan_allow=""
else
    vlan_allow=",allow:${vlan_allow}"
fi

if [ "$selfip_name" == "None"  ]; then
    selfip_name="${vlan_name}_self"
fi

msg=""
stat="FAILURE"

echo "Configuring vlan: ${vlan_name} selfip: ${vlan_selfip}"

f5-rest-node /config/cloud/openstack/node_modules/f5-cloud-libs/scripts/network.js \
-o /var/log/onboard-network.log \
--log-level debug \
--host localhost \
--user admin \
--password-url file:///config/cloud/openstack/adminPwd \
"$vlan_opt" "$vlan" \
--self-ip "name:${selfip_name},address:${vlan_selfip}/${selfip_prefix},vlan:${vlan_name}${vlan_allow}" \
"$gateway_opt" "$default_gateway"

onboardNetworkErrorCount=$(tail /var/log/onboard-network.log | grep "Network setup error" -i -c)

if [ "$onboardNetworkErrorCount" -gt 0 ]; then
    msg="Onboard-network command exited with error. See /var/log/onboard-network.log for details."
else
    stat="SUCCESS"
    msg="Onboard-network command exited without error."
fi

echo "$msg"
wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30