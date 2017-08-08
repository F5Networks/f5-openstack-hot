# Deploying the BIG-IP in OpenStack - 2 NIC

## Introduction
 
This solution uses a Heat Orchestration Template to launch a 2-NIC deployment of a BIG-IP VE in an Openstack Private Cloud. In a 2-NIC implementation, one interface is for management and data-plane traffic from the Internet, and the second interface is connected into the networks where traffic is processed by the pool members in a traditional two-ARM design. Traffic flows from the BIG-IP VE to the application servers.

The **standalone** heat orchestration template incorporates existing networks defined in neutron. 

## Configuration Notes and Constraints
  - Management Interface IP is determined via DHCP. 
  - Additional Network Interface static IP address must be provided. If DHCP is desired, the template can be modified to remove fixed_ips property for the port. 

## Security
This Heat Orchestration Template downloads helper code to configure the BIG-IP system. If your organization is security conscious and you want to verify the integrity of the template, you can open and modify definition of verifyHash file in /scripts/verifyHash.

## Supported instance types and OpenStack versions:
 - BIG-IP Virtual Edition Image Version 13.0 or later
 - OpenStack Mitaka Deployment

## Launching Stacks

1. Ensure the prerequisites are configured in your environment. See README from this project's root folder. 
2. Clone this repository or manually download the contents (zip/tar). As the templates use nested stacks and referenced components, it is recommended to retain the project structure as is for ease of deployment. If any of the files changed location, make sure that the corresponding paths are updated in the environment files. 
3. Locate and update the environment file (_env.yaml) with the appropriate parameter values. Note that some default values will be used if no value is specified for an optional parameter. 
4. Launch the stack using the OpenStack CLI with a command like below:

#### CLI Syntax
`openstack stack create <stackname> -t <path-to-template> -e <path-to-env>`

#### CLI Example
```
openstack stack create stack-2NIC-test -t src/f5-openstack-hot/experimental/templates/standalone/2nic/f5_bigip_standalone_2_nic.yaml -e src/f5-openstack-hot/experimental/templates/standalone/2nic/f5_bigip_standalone_2_nic_env.yaml
```

### Parameters
The following parameters can be defined on your environment file. 
<br>

#### BIG-IP General Provisioning

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| bigip_image | x | The BIG-IP VE image to be used on the compute instance. | BIG-IP VE must be 13.0 or later |
| bigip_flavor | x | Type of instance (flavor) to be used for the VE. |  |
| use_config_drive |  | Use config drive to provide meta and user data. With default value of false, the metadata service will be used instead. |  |
| f5_cloudlibs_tag |  | Tag that determines version of f5 cloudlibs to use for provisioning (onboard helper).  |  |
| f5_cloudlibs_url_override |  | Alternate URL for f5-cloud-libs package. If not specified, the default GitHub location for f5-cloud-libs will be used.  |  |
| bigip_servers_ntp |  | A list of NTP servers to configure on the BIG-IP. |  |
| bigip_servers_dns |  | A list of DNS servers to configure on the BIG-IP. |  |

#### BIG-IP Credentials

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| bigip_os_ssh_key | x | Name of key-pair to be installed on the BIG-IP VE instance to allow root SSH access. |  |
| bigip_admin_pwd | x | Password for the BIG-IP admin user. |  |
| bigip_root_pwd | x | Password for the BIG-IP root user. |  |

#### BIG-IP Licensing and Modules

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| bigip_license_key | x | Primary BIG-IP VE License Base Key |  |
| bigip_addon_license_keys |  | Additional BIG-IP VE License Keys |  |
| bigip_modules |  | Modules to provision on the BIG-IP.  Default `ltm:nominal` | Syntax: List of `module:level`. See [Parameter Values](#parameter-values) |

#### OS Network

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| external_network | x | Name of external network where floating IP resides. | Network must exist |
| mgmt_network | x | Network to which the BIG-IP management interface is attached. | Network must exist |
| mgmt_security_group_name | x | Name to apply on the security group for the BIG-IP management network. |  |
| network_vlan_security_group_name | x | Name to apply on the security group for BIG-IP VLAN. |  |
| network_vlan_name | x | OS Neutron Network to map to the BIG-IP VLAN | Network must exist |
| network_vlan_subnet | x | The Neutron Subnet for the corresponding BIG-IP VLAN.  | Subnet must exist |

#### BIG-IP Network

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| bigip_default_gateway |  | Optional upstream Gateway IP Address for the BIG-IP instance.  |  |
| bigip_mgmt_port |  | Default 443 |  |
| bigip_vlan_name |  | Name of the VLAN to be created on the BIG-IP. Default "data" |  |
| bigip_vlan_mtu |  | MTU value of the VLAN on the BIG-IP. Default 1400 |  |
| bigip_vlan_tag |  | Tag to apply on the VLAN on the BIG-IP. Use default value "None" for untagged |  |
| bigip_vlan_nic |  | The NIC associated with the BIG-IP VLAN. For 2-NIC this defaults to 1.1 |  |
| bigip_vlan_selfip_addr | x | Self-IP address to associate with the BIG-IP VLAN.  | A static value must be supplied. |
| bigip_vlan_cidr_block | x | CIDR Block for the BIG-IP SelfIP address. |  |
| bigip_vlan_allow |  | Optional list of service:port lockdown settings for the VLAN. If no value is supplied, default is used.  |  Syntax: List of `service:port` example: `[tcp:443, tcp:22]` |

<br>

### Parameter Values
bigip_modules: 
 - modules: [afm,am,apm,asm,avr,fps,gtm,ilx,lc,ltm,pem,swg,vcmp]
 - levels: [custom,dedicated,minimum,nominal,none] 

## Filing Issues
If you find an issue, we would love to hear about it. 
You have a choice when it comes to filing issues:
  - Use the **Issues** link on the GitHub menu bar in this repository for items such as enhancement or feature requests and non-urgent bug fixes. Tell us as much as you can about what you found and how you found it.


## Copyright

Copyright 2014-2017 F5 Networks Inc.


## License


Apache V2.0
~~~~~~~~~~~
Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations
under the License.

Contributor License Agreement
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Individuals or business entities who contribute to this project must have
completed and submitted the `F5 Contributor License Agreement`