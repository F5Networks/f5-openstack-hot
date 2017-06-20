#!/bin/bash

nicCount=__nic_count__

if [[ "$nicCount" -gt 1 ]]; then
    echo "Disabling dhclient for mgmt nic"
    tmsh modify sys db dhclient.mgmt { value disable }
    tmsh save sys config 
fi

rm /config/cloud/openstack/adminPwd /config/cloud/openstack/rootPwd /config/cloud/openstack/rootPwdRandom /config/cloud/openstack/adminPwdRandom
umount /dev/hdd

echo '*****POST-ONBOARD DONE******' 