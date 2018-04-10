#!/bin/bash
is1Nic="__is_1_nic__"
nic="__nic__"
addr="__addr__"
cidr="__cidr__"
gateway="__gateway__"
dns="__dns__"
mtu="__mtu__"
msg=""
stat="SUCCESS"
logFile="/var/log/cloud/openstack/setup-static-mgmt.log"
wcNotifyOptions="__wc_notify_options__"

function check_mcpd_up() {
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
}

function restart_nic() {
    ifdown "$nic" && ifup "$nic"
    set_mgmt_mtu
}

function disable_mgmt_dhcp() {

    echo 'Disabling mgmt-dhcp...'
    if ! tmsh modify sys global-settings mgmt-dhcp disabled ; then
        msg="Unable to set mgmt-dhcp to disabled."
        stat="FAILURE"
    fi
    tmsh save sys config
    restart_nic
}

function override_1nic() {
    if [[ "$is1Nic" == "True" ]] ; then
        overrideVersion=$(tmsh show sys version | grep "13.1.0.2" -c)
        defaultManagementIp=$(tmsh list sys management-ip | grep "192.168.1.245" -c)

        if [[ $overrideVersion -eq 1 && $defaultManagementIp -eq 0 ]] ; then
            # set to the defaults first so that cfg can be reloaded and new addr saved, otherwise, we get config err mgmt
            echo "No default management ip assigned."
            sed -i "s/IPADDR=/IPADDR=192.168.1.245/g" /etc/sysconfig/network-scripts/ifcfg-mgmt
            sed -i "s/NETMASK=/NETMASK=255.255.255.0/g" /etc/sysconfig/network-scripts/ifcfg-mgmt

            restart_nic
        fi
    fi
}

function set_net_1nic() {
    if [[ "$is1Nic" == "True" ]]; then
        tmsh create net vlan internal interfaces add { 1.0 } mtu $mtu
        tmsh create net self self_1nic address "$addr/$cidr" vlan internal allow-service default
        tmsh create net route default gw "$gateway"
        tmsh save sys config
    fi
}

function create_mgmt_ip() {

    echo 'Creating mgmt - ip... '
    if ! tmsh create /sys management-ip "$addr/$cidr" ; then
        msg="$msg.. Unable to set mgmt-ip."
        stat="FAILURE"
    fi
}

function create_mgmt_gateway() {
    if [[ "$gateway" != "" && "$gateway" != "None" ]]; then
        echo 'Creating mgmt - gateway route...'
        if ! tmsh create sys management-route default gateway $gateway ; then
            msg="$msg.. Unable to create a default gateway route."
            stat="FAILURE"
        fi
    fi
}

function add_dns_servers() {
    if [[ "$dns" != "" && "$dns" != "None" ]]; then
        echo 'Creating dns server entries...'
        # need to set this early in case we need to resolve hosts (e.g. we are downloading libs from github)
        tmsh modify sys dns name-servers add { $dns }
    fi
}

function persist_mtu() {
    # persist mtu value through reboot
    # echo "ip link set $nic mtu $mtu">>/config/startup;
    echo "/config/startup-persist-mtu.sh &" >> /config/startup
}

function set_mgmt_mtu() {
    if [[ "$mtu" != "" && "$mtu" != "None" ]]; then
        echo 'Setting management mtu'
        if ! ip link set $nic mtu $mtu ; then
            msg="$msg.. Unable to set MTU value"
            stat="FAILURE"
        fi
    fi

}

function manage_signal() {
    if [[ "$stat" == "FAILURE" ]]; then
        echo "$msg"
        msg="Setup-staticMgmt command exited with error. See $logFile for details."
    else
        touch /config/cloud/openstack/staticMgmtReady
        msg="Setup-staticMgmt command exited without error."
    fi
    # buffer to ensure net/route up
    sleep 90
    if [ "$wcNotifyOptions" == "None" ]; then
        wcNotifyOptions=""
    else
        wcNotifyOptions=" $wcNotifyOptions"
    fi
    wc_notify --data-binary '{"status": "'"$stat"'", "reason":"'"$msg"'"}' --retry 5 --retry-max-time 300 --retry-delay 30$wcNotifyOptions
}

function main () {
    date "+%Y-%m-%d %X %Z"
    echo 'Starting static network configuration for management NIC'

    persist_mtu
    check_mcpd_up
    disable_mgmt_dhcp
    override_1nic
    create_mgmt_ip
    create_mgmt_gateway
    set_mgmt_mtu
    add_dns_servers
    tmsh save sys config
    set_net_1nic
    restart_nic
    manage_signal
}

main
