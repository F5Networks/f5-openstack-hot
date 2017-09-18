# Deploying the BIG-IP in OpenStack - Clustered 2 NIC

## Introduction
 
This solution uses a Heat Orchestration Template to launch and configure two BIG-IP 2-NIC VEs in a clustered, highly available configuration in an Openstack Private Cloud.  When you deploy your applications behind a HA pair of F5 BIG-IP VEs, the BIG-IP VE instances are all in Active-Standby, and are used as a single device for failover. If one device becomes unavailable, the standby takes over traffic management duties, ensuring you have the highest level of availability for your applications. You can also configure the BIG-IP VE to enable F5's L4/L7 security features, access control, and intelligent traffic management.

In a 2-NIC implementation, each BIG-IP VE has one interface used for management and data-plane traffic from the Internet, and the second interface connected into the Neutron networks where traffic is processed by the pool members in a traditional two-ARM design. Traffic flows from the BIG-IP VE to the application servers.

The **cluster** heat orchestration template incorporates existing networks defined in Neutron. 

## Prerequisites and Configuration Notes
  - The HA (Highly Available) solution consists of two templates that configures clustering:
    - *f5_bigip_cluster_2_nic.yaml*, the parent template that needs to be specified as the template paramater
    - *f5_bigip_cluster_instance_2_nic.yaml*, the big-ip instance-specific template referenced by the parent template
  - Management Interface IP is determined via DHCP.
  - The cluster Self-IP must reside on the same subnet as the VLAN configured for the data/public NIC. 
  - An additional Network Interface static IP address must be provided. If DHCP is desired, the template can be modified to remove the fixed_ips property for the port. 
  - If you do not specify a URL override (the parameter name is f5_cloudlibs_url_override), the default location is github and the subnet for the management network requires a route and access to Internet for the initial configuration to download the BIG-IP cloud library.
  - If you specify a value for f5_cloudlibs_url_override or f5_cloudlibs_tag, ensure that corresponding hashes are valid by either updating scripts/verifyHash or by providing a f5_cloudlibs_verify_hash_url_override value.

## Security
This Heat Orchestration Template downloads helper code to configure the BIG-IP system. If you want to verify the integrity of the template, you can open and modify definition of verifyHash file in /scripts/verifyHash.

## Supported instance types and OpenStack versions:
 - BIG-IP Virtual Edition Image Version 13.0 or later
 - OpenStack Mitaka Deployment

### Help
While this template has been created by F5 Networks, it is in the experimental directory and therefore has not completed full testing and is subject to change.  F5 Networks does not offer technical support for templates in the experimental directory. For supported templates, see the templates in the **supported** directory.

We encourage you to use our [Slack channel](https://f5cloudsolutions.herokuapp.com) for discussion and assistance on F5 Cloud templates.  This channel is typically monitored Monday-Friday 9-5 PST by F5 employees who will offer best-effort support.

## Launching Stacks

1. Ensure the prerequisites are configured in your environment. See the README from this project's root folder. 
2. Clone this repository or manually download the contents (zip/tar). As the templates use nested stacks and referenced components, we recommend you retain the project structure as is for ease of deployment. If any of the files changed location, make sure that the corresponding paths are updated in the environment files. 
3. Locate and update the environment file (_env.yaml) with the appropriate parameter values. Note that some default values will be used if no value is specified for an optional parameter. 
4. Launch the stack using the OpenStack CLI with a command like the following:

#### CLI Syntax
`openstack stack create <stackname> -t <path-to-template> -e <path-to-env>`

#### CLI Example
```
openstack stack create stack-2NIC-cluster -t src/f5-openstack-hot/experimental/templates/cluster/2nic/f5_bigip_cluster_2_nic.yaml -e src/f5-openstack-hot/experimental/templates/cluster/2nic/f5_bigip_cluster_2_nic_env.yaml
```

### Parameters
The following parameters can be defined in your environment file. 
<br>

#### BIG-IP General Provisioning 

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| bigip_image | x | The BIG-IP VE image to be used on the compute instance. | BIG-IP VE must be 13.0 or later |
| bigip_flavor | x | Type of instance (flavor) to be used for the VE. |  |
| use_config_drive |  | Use config drive to provide meta and user data. With default value of false, the metadata service will be used instead. |  |
| f5_cloudlibs_tag |  | Tag that determines version of f5 cloudlibs to use for provisioning (onboard helper).  |  |
| f5_cloudlibs_url_override |  | Alternate URL for f5-cloud-libs package. If not specified, the default GitHub location for f5-cloud-libs will be used. If version is different from default f5_cloudlibs_tag, ensure that hashes are valid by either updating scripts/verifyHash or by providing a f5_cloudlibs_verify_hash_url_override value.  |  |
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
| bigip_license_keys | x | List of Primary BIG-IP VE License Base Keys | Syntax: List of Base License Keys |
| bigip_addon_license_keys | | Additional BIG-IP VE License Keys | Syntax: List of AddOn License Keys. One list item per BIG-IP instance. Each list item consists of add-on keys separated by a semicolon `addonKey1;addonKey2` |
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
| bigip_self_ip_addresses | x | List of Self-IP addresses to associate with the BIG-IP VLAN.  | A static value must be supplied. |
| bigip_self_cidr_block | x | CIDR Block for the BIG-IP SelfIP address. |  |
| bigip_self_port_lockdown |  | Optional list of service:port lockdown settings for the VLAN. If no value is supplied, default is used.  |  Syntax: List of `service:port` example: `[tcp:443, tcp:22]` |


#### BIG-IP Cluster

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| bigip_device_group |  | Name of the BIG-IP Device Group to create or join. Default 'Sync'  |  |
| bigip_auto_sync |  | Toggles flag for enabling BIG-IP Cluster Auto Sync. Default true  |  |
| bigip_save_on_auto_sync |  | Toggles flag for enabling saving on config-sync auto-sync . Default true  |  |
| bigip_cluster_self_ip_addresses | x | List of BIG-IP Self-IP addresses to use for clustering |  |

<br>

### Parameter Values
bigip_modules: 
 - modules: [afm,am,apm,asm,avr,dos,fps,gtm,ilx,lc,ltm,pem,swg,urldb]
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
completed and submitted the [F5 Contributor License Agreement](http://f5-openstack-docs.readthedocs.io/en/latest/cla_landing.html).