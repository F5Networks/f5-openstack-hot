# Deploying the BIG-IP in OpenStack - nNIC

[![Slack Status](https://f5cloudsolutions.herokuapp.com/badge.svg)](https://f5cloudsolutions.herokuapp.com)
[![Releases](https://img.shields.io/github/release/f5networks/f5-openstack-hot.svg)](https://github.com/f5networks/f5-openstack-hot/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-openstack-hot.svg)](https://github.com/f5networks/f5-openstack-hot/issues)

## Introduction

This solution uses a Heat Orchestration Template to launch an nNIC (multi NIC) deployment of a BIG-IP VE in an OpenStack Private Cloud. In a multi NIC implementation, one interface is for management and data-plane traffic from the Internet, and the NIC count you provide determines the number of additional NICs used for processing traffic.  You can include up to 10 total NICs, including the NIC for management and data-plane traffic from the Internet.

The BIG-IP VE has the <a href="https://f5.com/products/big-ip/local-traffic-manager-ltm">Local Traffic Manager</a> (LTM) module enabled to provide advanced traffic management functionality. This means you can also configure the BIG-IP VE to enable F5's L4/L7 security features, access control, and intelligent traffic management.

This template gives you the option of using a [BIG-IQ device](https://f5.com/products/big-iq-centralized-management) to license BIG-IP VEs from a pool of license/registration keys.

The **standalone** heat orchestration template incorporates existing networks defined in Neutron.

Templates under **prod_stack** do not require an external network and do not create a floating IP address on the Neutron port.

This template is in the **static** directory, meaning you configure the BIG-IP VE management IP address statically.  This is useful if there is no DHCP server available, or if it is disabled on the neutron subnet.  If you want to use a template that assigned using DHCP, see the template in the **dynamic** directory.

## Prerequisites and Configuration Notes

- Management interface IP is configured statically.
- If you do not specify a URL override (the parameter name is **f5_cloudlibs_url_override**), the default location is GitHub and the subnet for the management network requires a route and access to the Internet for the initial configuration to download the BIG-IP cloud library.
- If you specify a value for **f5_cloudlibs_url_override** or **f5_cloudlibs_tag**, ensure the corresponding hashes are valid by either updating **scripts/verifyHash** or by providing a **f5_cloudlibs_verify_hash_url_override** value.
- **Important**: This [article](https://support.f5.com/csp/article/K13092#userpassword) contains links to information regarding BIG-IP user and password management. Please take note of the following when supplying password values:
  - The BIG-IP version and any default policies that may apply
  - Any characters you should avoid
- This template leverages the built in heat resource type *OS::Heat::WaitCondition* to track status of onboarding by sending signals to the orchestration API.
- This template can send non-identifiable statistical information to F5 Networks to help us improve our templates. See [Sending statistical information to F5](#sending-statistical-information-to-f5).
- In order to pass traffic from your clients to the servers, after launching the template, you must create virtual server(s) on the BIG-IP VE.
- F5 has created a matrix that contains all of the tagged releases of the F5 OpenStack Heat Orchestration templates, and the corresponding BIG-IP versions available for a specific tagged release. See https://github.com/F5Networks/f5-openstack-hot/blob/master/openstack-bigip-version-matrix.md.

## Security

This Heat Orchestration Template downloads helper code to configure the BIG-IP system. If you want to verify the integrity of the template, you can open and modify the definition of the verifyHash file in **/scripts/verifyHash**.

Additionally, F5 provides checksums for all of our supported OpenStack heat templates. For instructions and the checksums to compare against, see this [DevCentral link](https://devcentral.f5.com/codeshare/checksums-for-f5-supported-cft-and-arm-templates-on-github-1014) .

Instance configuration data is retrieved from the metadata service. OpenStack supports encrypting the metadata traffic.
If SSL is enabled in your environment, ensure that calls to the metadata service in the templates are updated accordingly.
For more information, please refer to:

- Heat Template Guide - [Software Deployment](https://docs.openstack.org/heat/latest/template_guide/software_deployment.html)
- Nova Admin - [Encrypting Compute Metadata Traffic](https://docs.openstack.org/nova/latest/admin/security.html#encrypt-compute-metadata-traffic)

**Note**: The templates use cloud-init for provisioning. To mitigate security risks associated with retrieving cloud-config data, or if you do not fully trust the medium over which your cloud-config will be stored and/or transmitted, we recommend you change your passwords after stack creation has been completed successfully. 

## Supported instance types and OpenStack versions

- BIG-IP Virtual Edition Image Version 13.0 or later
- OpenStack Mitaka Deployment

### Getting Help

While this template has been created by F5 Networks, it is in the experimental directory and therefore has not completed full testing and is subject to change.  F5 Networks does not offer technical support for templates in the experimental directory. For supported templates, see the templates in the **supported** directory.

**Community Support**
We encourage you to use our [Slack channel](https://f5cloudsolutions.herokuapp.com) for discussion and assistance on F5 OpenStack Heat Orchestration templates. There are F5 employees who are members of this community who typically monitor the channel Monday-Friday 9-5 PST and will offer best-effort assistance. This slack channel community support should **not** be considered a substitute for F5 Technical Support. See the [Slack Channel Statement](https://github.com/F5Networks/f5-openstack-hot/blob/master/slack-channel-statement.md) for guidelines on using this channel.

## Launching Stacks

1. Ensure the prerequisites are configured in your environment. See README from this project's root folder.
2. Clone this repository or manually download the contents (zip/tar). As the templates use nested stacks and referenced components, we recommend you retain the project structure as-is for ease of deployment. If any of the files changed location, make sure that the corresponding paths are updated in the environment files.
3. Locate and update the environment file (**_env.yaml**) with the appropriate parameter values. Note that some default values are used if no value is specified for an optional parameter.
4. Launch the stack using the OpenStack CLI with a command using the following syntax:

### CLI Syntax

`openstack stack create <stackname> -t <path-to-template> -e <path-to-env>`

### CLI Example

```bash
openstack stack create stack-nnic-test -t src/f5-openstack-hot/experimental/templates/standalone/nnic/prod_stack/static/f5_bigip_standalone_n_nic.yaml -e src/f5-openstack-hot/experimental/templates/standalone/nnic/prod_stack/static/f5_bigip_standalone_n_nic_env.yaml
```

### Parameters

The following parameters can be defined in your environment file.

#### BIG-IP General Provisioning

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_image | Yes | The BIG-IP VE image to be used on the compute instance. | BIG-IP VE must be 13.0 or later |
| bigip_flavor | Yes | Type of instance (flavor) to be used for the VE. |  |
| use_config_drive | No | Use config drive to provide meta and user data. With the default value of false, the metadata service is used instead. |  |
| libs_proxy_protocol | No | Use specified protocol when downloading libs through a proxy |  |
| libs_proxy_host | No | Use specified protocol when downloading libs through a proxy |  |
| libs_proxy_port | No | Use specified port when downloading libs through a proxy |  |
| libs_proxy_auth | No | Default auth value in the format <username:password> for downloading onboarding libs through a proxy |  |
| libs_proxy_addtl_opts | No | Additional parameters to add to onboarding libs download request with proxy |  |
| f5_cloudlibs_tag | No | Tag that determines the version of F5 cloudlibs to use for provisioning (onboard helper).  |  |
| f5_cloudlibs_url_override | No | Alternate URL for the f5-cloud-libs package. If not specified, the default GitHub location for f5-cloud-libs is used. If version is different from default f5_cloudlibs_tag, ensure that hashes are valid by either updating scripts/verifyHash or by providing a f5_cloudlibs_verify_hash_url_override value.  |  |
| f5_cloudlibs_verify_hash_url_override | No | Alternate URL for verifyHash used to validate f5-cloud-libs package. If not specified, the scripts/verifyHash is used.
| f5_cloudlibs_openstack_tag | No | Tag that determines version of F5 cloudlibs-openstack to use for provisioning (onboard helper).  |  |
| f5_cloudlibs_openstack_url_override |  | Alternate URL for f5-cloud-libs-openstack package. If not specified, the default GitHub location for f5-cloud-libs is used. If version is different from default f5_cloudlibs_tag, ensure that hashes are valid by either updating scripts/verifyHash or by providing a f5_cloudlibs_verify_hash_url_override value.  |  |
| bigip_servers_ntp | No | A list of NTP servers to configure on the BIG-IP VE. |  |
| bigip_timezone | No | The NTP timezone to configure on the BIG-IP |  |
| bigip_remote_hosts_names | No | A list of remote hosts to add to the BIG-IP |  |
| bigip_remote_hosts_ips | No | A list of remote host ips to add to the BIG-IP. The index should match the entries provided in `bigip_remote_hosts_names` |  |
| bigip_servers_dns | No | A list of DNS servers to configure on the BIG-IP VE. |  |
| allow_usage_analytics | No | This deployment can send anonymous statistics to F5 to help us determine how to improve our solutions. If you select No, statistics are not sent.  |  |

#### BIG-IP nNIC Provisioning

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_nic_count | Yes | Number of additional NICs to attach to the BIG-IP VE. Note: Exclude the management NIC from the count. | min: 1 max: 9 |

#### BIG-IP Credentials

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_os_ssh_key | Yes | Name of the key-pair to be installed on the BIG-IP VE instance to allow root SSH access. |  |
| bigip_admin_pwd | Yes | Password for the BIG-IP admin user. |  |
| bigip_root_pwd | Yes | Password for the BIG-IP root user. |  |

#### BIG-IP Licensing and Modules

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_licensing_type | Yes |  Type of licensing to use for BIG-IP. |  Allowed values are `BYOL` (License Key), `NO_LIC` (skip licensing), or `BIGIQ` (BIG-IQ License Manager v5.2 or v5.3). |
| bigip_license_key | No | Primary BIG-IP VE License Base Key |  |
| bigip_addon_license_keys | No | Additional BIG-IP VE License Keys |  |
| bigip_modules | No | Modules to provision on the BIG-IP.  Default `ltm:nominal` | Syntax: List of `module:level`. See [Parameter Values](#parameter-values) |
| bigiq_license_host_ip | No | The IP address (or FQDN) for the existing BIG-IQ instance to be used when licensing the BIG-IP. | Must be reachable from the BIG-IP instance. Must be provided if `bigip_licensing_type` is `BIGIQ`|
| bigiq_license_username | No | The BIG-IQ username to use to license the BIG-IP instances. | Must be provided if `bigip_licensing_type` is `BIGIQ` |
| bigiq_license_pwd | No | The BIG-IQ password to use to license the BIG-IP instances. | Must be provided if `bigip_licensing_type` is `BIGIQ`|
| bigiq_license_pool | No | The BIG-IQ License Pool to use to license the BIG-IP instances. | Must be provided if `bigip_licensing_type` is `BIGIQ` |
| bigiq_use_bigip_floating_ip | No | Determines whether to use the floating ip of the BIG-IP for BIG-IQ licensing | Must be provided if `bigip_licensing_type` is `BIGIQ` |
| bigiq_alt_bigip_port | No | The alternate port to use when licensing the BIG-IP through BIG-IQ. If not specified, management port is used. | Must be provided if `bigip_licensing_type` is `BIGIQ` |


#### OS Network

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| mgmt_network | Yes | Network to which the BIG-IP management interface is attached. | Network must exist |
| mgmt_security_group_name | Yes | Name to apply on the security group for the BIG-IP management network. |  |
| network_vlan_security_group_rules | Yes | The rules to apply to the security group | OS::Neutron::SecurityGroup rules |
| network_vlan_names | Yes | OS Neutron Network to map to the BIG-IP VLANs | Networks must exist |
| network_vlan_subnets | Yes | The Neutron Subnet list for the corresponding BIG-IP VLANs. Specify multiple fixed ips by providing subnet names in the format `<subnet_name;subnet_name;subnet_name>`  | Subnets must exist |

#### BIG-IP Network

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_default_gateway | No  | Optional upstream Gateway IP Address for the BIG-IP instance.  |  |
| bigip_mgmt_port | No | The default is **443** |  |
| bigip_mgmt_nic_name | No | The default is ***mgmt** |  |
| bigip_mgmt_nic_gateway | Yes | Gateway to configure the management nic with |  |
| bigip_mgmt_nic_mtu | No | The MTU to configure teh management nic with. The default is **1400** |  |
| bigip_vlan_names | No | Names of the VLAN to be created on the BIG-IP VE. |  |
| bigip_vlan_mtus | No | MTU values of the VLAN on the BIG-IP. The default is **1400** |  |
| bigip_vlan_tags | No | Tag to apply on the VLAN on the BIG-IP. Use the default value **None** for untagged |  |
| bigip_self_ip_addresses | Yes | Self-IP addresses to associate with the BIG-IP VLAN.  | A static value must be supplied. |
| bigip_self_cidr_blocks | Yes | CIDR Blocks for the BIG-IP SelfIP address. |  |
| bigip_self_port_lockdowns | No | Optional list of service:port lockdown settings for the VLAN. If no value is supplied, default is used.  |  Syntax: List of `service:port` example: `[tcp:443, tcp:22]`. Additional allowed values: `[allow-all, allow-default, allow-none\]` |

#### OS Heat

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| os_heat_wc_notify_options | No | Additional options for the heat wait condition signals sent via curl |  |

### Parameter Values

bigip_modules:

- modules: [afm,am,apm,asm,avr,dos,fps,gtm,ilx,lc,ltm,pem,swg,urldb]
- levels: [custom,dedicated,minimum,nominal,none]

### Sending statistical information to F5

All of the F5 templates now have an option to send anonymous statistical data to F5 Networks to help us improve future templates.
None of the information we collect is personally identifiable, and only includes:

- Customer ID: this is a hash of the project ID, not the actual ID
- Deployment ID: hash of stack ID
- F5 template name
- F5 template version
- Cloud Name
- Region: this is a hash of the region (if supplied as parameter)
- BIG-IP version
- F5 license type
- F5 Cloud libs version
- F5 script name

This information is critical to the future improvements of templates, but should you decide to select **No**, information will not be sent to F5.

## Filing Issues

If you find an issue, we would love to hear about it.
You have a choice when it comes to filing issues:

- Use the **Issues** link on the GitHub menu bar in this repository for items such as enhancement or feature requests and non-urgent bug fixes. Tell us as much as you can about what you found and how you found it.


## Copyright

Copyright 2014-2018 F5 Networks Inc.

## License

### Apache V2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations
under the License.

### Contributor License Agreement

Individuals or business entities who contribute to this project must have
completed and submitted the F5 Contributor License Agreement.