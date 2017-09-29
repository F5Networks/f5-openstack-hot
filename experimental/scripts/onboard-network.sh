#!/bin/bash
echo '******Starting Additional Network Configuration******'

default_gateway="__default_gateway__"
vlan_create="__network_vlan_create__"
vlan_name="__network_vlan_name__"
vlan_tag="__network_vlan_tag__"
vlan_mtu=__network_vlan_mtu__
vlan_nic=__network_vlan_nic__
vlan_last_nic_index="__network_vlan_last_nic_index__"
vlan_nic_index="__network_vlan_nic_index__"
self_port_lockdown="__network_self_port_lockdown__"

self_ip=__network_self_ip_addr__
self_ip_name=__network_self_name__
self_ip_cidr=__network_self_cidr_block__
self_ip_prefix=${self_ip_cidr#*/}

logFile=""
vlan_opt=""
vlan=""
gateway_opt=""
msg=""
stat="FAILURE"


function set_vars() {

    if [[ "$vlan_nic" == "" ]]; then
        vlan_nic_ctr=$(( vlan_nic_index + 1 ))
        vlan_nic="1.${vlan_nic_ctr}"
    fi

    if [[ "$vlan_name" == "None" || "$vlan_name" == "" ]]; then
        vlan_name="${vlan_nic}_vlan"
    fi

    if [[ "$default_gateway" != "None" && "$default_gateway" != "" ]]; then

        # onboarding_network_config
        if [[ "$vlan_nic_index" == "" ]]; then
            default_gateway="${default_gateway}"
            gateway_opt="--default-gw"
        # onboarding_network_config_indexed
        else
            # only pass the default gw param when configuring last nic
            if [[ "$vlan_nic_index" == "$vlan_last_nic_index" ]]; then
                default_gateway="${default_gateway}"
                gateway_opt="--default-gw"
            else
                default_gateway=""
                gateway_opt=""
            fi
        fi
    else
        default_gateway=""
        gateway_opt=""
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
            vlan_tag=",tag:${vlan_tag}" 
        fi
        vlan="name:${vlan_name},nic:${vlan_nic}${vlan_mtu}${vlan_tag}"
        vlan_opt="--vlan"
    else
        vlan=""
        vlan_opt=""
    fi

    case "$self_port_lockdown" in
        " " | "" | "None" )
            self_port_lockdown=""
            ;;
        "allow-default" )
            self_port_lockdown=",allow:default"
            ;;
        ### NOTE:
        ### To be supported in future cloud-libs fix
        # "allow-all" )
        #     self_port_lockdown=",allow:all"
        #     ;;
        # "allow-none" )
        #     self_port_lockdown=",allow:none"
        #     ;;
        * )
            self_port_lockdown=",allow:${self_port_lockdown}"
            ;;
    esac

    if [[ "$self_ip_name" == "None" || "$self_ip_name" == "" ]]; then
        self_ip_name="${vlan_name}_self"
    fi

    if [[ "$vlan_nic_index" == "" || "$vlan_nic_index" == "None" ]]; then
        logFile="/var/log/onboard-network.log"
    else
        logFile="/var/log/onboard-network-$vlan_nic_index.log"
    fi
}

function onboard_network_run() {
    echo "Configuring vlan: ${vlan_name} self_ip: ${self_ip}"

    f5-rest-node /config/cloud/openstack/node_modules/f5-cloud-libs/scripts/network.js \
    -o "${logFile}" \
    --log-level debug \
    --host localhost \
    --user admin \
    --password-url file:///config/cloud/openstack/adminPwd \
    "$vlan_opt" "$vlan" \
    --self-ip "name:${self_ip_name},address:${self_ip}/${self_ip_prefix},vlan:${vlan_name}${self_port_lockdown}" \
    "$gateway_opt" "$default_gateway"
}

function disable_dhclient() {
    if [[ "$vlan_nic_index" == "" || "$vlan_nic_index" == "None" || "$vlan_nic_index" == "$vlan_last_nic_index" ]]; then
        echo "Disabling dhclient for mgmt nic"
        tmsh modify sys db dhclient.mgmt { value disable }
        tmsh save sys config 
    fi
}

function send_heat_signal() {
    onboardNetworkErrorCount=$(tail "$logFile" | grep "Network setup error" -i -c)

    if [ "$onboardNetworkErrorCount" -gt 0 ]; then
        msg="Onboard-network command exited with error. See $logFile for details."
    else
        onboardNetworkFailureCount=$(tail "$logFile" | grep "network setup failed" -i -c)
        if [ "$onboardNetworkFailureCount" -gt 0 ]; then
            msg="Onboard-network command exited with failure. See $logFile for details."
        else
            stat="SUCCESS"
            msg="Onboard-network command exited without error."
        fi
    fi

    echo "$msg"
    wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30
}

function main() {
    set_vars
    onboard_network_run
    disable_dhclient
    send_heat_signal
}

main

