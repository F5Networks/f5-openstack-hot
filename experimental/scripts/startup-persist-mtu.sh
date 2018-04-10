#!/bin/bash
# Template from: K11948: Configuring the BIG-IP system to run commands or scripts upon system startup

export REMOTEUSER=root

nic="__nic__"
mtu="__mtu__"
# Limit to 4 times in while-loop, ie. 4 x 30 secs sleep = 2 mins.
MAX_LOOP=4

while true
do
MCPD_RUNNING=`ps aux | grep "/usr/bin/mcpd" | grep -v grep | wc -l`

if [ "$MCPD_RUNNING" -eq 1 ]; then
# Here you could perform customized command(s) after MCPD is found running when the BIG-IP system starts up.
# Customized startup command(s) can be added below this line.

ip link set $nic mtu $mtu

# Customized startup command(s) should end above this line.

exit
fi

# If MCPD is not ready yet, script sleep 30 seconds and check again.
sleep 30

# Safety check not to run this script in background beyond 2 mins (ie. 4 times in while-loop).
if [ "$MAX_LOOP" -eq 1 ]; then
echo "MCPD not started within 2 minutes. Exiting script."
exit
fi
((MAX_LOOP--))
done
