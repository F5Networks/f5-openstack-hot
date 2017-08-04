#!/bin/bash

rm /config/cloud/openstack/adminPwd /config/cloud/openstack/rootPwd /config/cloud/openstack/rootPwdRandom /config/cloud/openstack/adminPwdRandom
umount /mnt/config
rmdir /mnt/config


### START CUSTOM CONFIGURATION ###

### END CUSTOM CONFIGURATION ###

echo '*****POST-ONBOARD DONE******' 