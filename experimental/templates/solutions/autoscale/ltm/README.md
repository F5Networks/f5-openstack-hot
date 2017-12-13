# Deploying the BIG-IP in OpenStack - Autoscale BIG-IP LTM - Heat Autoscaling Group

[![Slack Status](https://f5cloudsolutions.herokuapp.com/badge.svg)](https://f5cloudsolutions.herokuapp.com)
[![Releases](https://img.shields.io/github/release/f5networks/f5-openstack-hot.svg)](https://github.com/f5networks/f5-openstack-hot/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-openstack-hot.svg)](https://github.com/f5networks/f5-openstack-hot/issues)

## Introduction

This solution uses a Heat template to launch the deployment of F5 Virtual Edition (VE) instances in **OS::Heat::AutoScalingGroup** that can scale arbitrary resources. The BIG-IP VEs have the <a href="https://f5.com/products/big-ip/local-traffic-manager-ltm">Local Traffic Manager</a> (LTM) module enabled to provide advanced traffic management functionality.
In this auto scale solution, as thresholds are met, the number of BIG-IP VE LTM instances automatically increases or decreases accordingly. Scaling thresholds are by default based on **network.incoming.bytes.rate** meter. The meter type can be changed by providing the parameter value. This solution is for BIG-IP LTM only.

The BIG-IP VE(s) are configured in 2-NIC mode. In a 2-NIC implementation, each BIG-IP VE has one interface used for management and data-plane traffic from the Internet, and the second interface connected into the Neutron networks where traffic is processed by the pool members in a traditional two-ARM design. Traffic flows from the BIG-IP VE to the application servers.

The **autoscale_ltm** heat orchestration template incorporates existing networks defined in Neutron.

## Prerequisites and Configuration Notes
  - The autoscale ltm solution consists of two templates that configure clustering:
    - *f5_bigip_autoscale_ltm_2_nic.yaml*, the parent template that needs to be specified as the template parameter.
    - *f5_bigip_autoscale_ltm_instance_2_nic.yaml*, the BIG-IP instance-specific template referenced by the parent template.
  - There are no fixed IP addresses for the interfaces. The addresses will be determined upon Neutron port creation.
  - If you do not specify a URL override (the parameter name is **f5_cloudlibs_url_override**), the default location is GitHub and the subnet for the management network requires a route and access to the Internet for the initial configuration to download the BIG-IP cloud library.
  - If you specify a value for **f5_cloudlibs_url_override** or **f5_cloudlibs_tag**, ensure that corresponding hashes are valid by either updating scripts/verifyHash or by providing a **f5_cloudlibs_verify_hash_url_override** value.
  - **Important**: This [article](https://support.f5.com/csp/article/K13092#userpassword) contains links to information regarding BIG-IP user and password management. Take note of the following when supplying password values:
      - The BIG-IP version and any default policies that may apply
      - Any characters recommended that you avoid
  - This template can send non-identifiable statistical information to F5 Networks to help us improve our templates. See [Sending statistical information to F5](#sending-statistical-information-to-f5).
  - In order to pass traffic from your clients to the servers, after launching the template, you must create virtual server(s) on the BIG-IP VE.
  - This template includes a master election feature, which ensures that if the existing master BIG-IP VE is unavailable, a new master is selected from the BIG-IP VEs in the cluster.
  - This template leverages the following built-in heat resource types:
      - *OS::Heat::WaitCondition* to track status of onboarding by sending signals to the orchestration API.
      - *OS::Ceilometer::Alarm* and *OS::Heat::AutoScalingGroup* to trigger the autoscaling of resources.
      - *OS::Heat::SwiftSignal* to create an endpoint for autoscaling metadata used in master election.
  - **Important**: You may need to perform additional configuration for the OpenStack services Ceilometer (metering) and Swift (container) in your environment in order to utilize this template. This template also requires a user account with sufficient privileges to perform Ceilometer, Swift and Heat operations.

## Security
This Heat Orchestration Template downloads helper code to configure the BIG-IP system. If you want to verify the integrity of the template, you can open and modify the definition of the **verifyHash** file in **/scripts/verifyHash**.

Additionally, F5 provides checksums for all of our supported OpenStack heat templates. For instructions and the checksums to compare against, see this [DevCentral link](https://devcentral.f5.com/codeshare/checksums-for-f5-supported-cft-and-arm-templates-on-github-1014) .

Instance configuration data is retrieved from the metadata service. OpenStack supports encrypting the metadata traffic.
If SSL is enabled in your environment, ensure that calls to the metadata service in the templates are updated accordingly.
For more information, please refer to:
- https://docs.openstack.org/heat/latest/template_guide/software_deployment.html
- https://docs.openstack.org/nova/latest/admin/security.html#encrypt-compute-metadata-traffic


## Supported instance types and OpenStack versions:
 - BIG-IP Virtual Edition Image Version 13.0 or later
 - OpenStack Mitaka Deployment

### Help
While this template has been created by F5 Networks, it is in the experimental directory and therefore has not completed full testing and is subject to change.  F5 Networks does not offer technical support for templates in the experimental directory. For supported templates, see the templates in the **supported** directory.

**Community Support**  
We encourage you to use our [Slack channel](https://f5cloudsolutions.herokuapp.com) for discussion and assistance on F5 OpenStack Heat Orchestration templates. There are F5 employees who are members of this community who typically monitor the channel Monday-Friday 9-5 PST and will offer best-effort assistance. This slack channel community support should **not** be considered a substitute for F5 Technical Support.

## Launching Stacks

1. Ensure the prerequisites are configured in your environment. See the README from this project's root folder.
2. Clone this repository or manually download the contents (zip/tar). As the templates use nested stacks and referenced components, we recommend you retain the project structure as is for ease of deployment. If any of the files changed location, make sure that the corresponding paths are updated in the environment files.
3. Locate and update the environment file (`_env.yaml`) with the appropriate parameter values. Note that some default values are used if no value is specified for an optional parameter.
4. Launch the stack using the OpenStack CLI with a command using the following syntax::

#### CLI Syntax
`openstack stack create <stackname> -t <path-to-template> -e <path-to-env>`

#### CLI Example
```
openstack stack create stack-autoscale-ltm -t src/f5-openstack-hot/experimental/templates/solutions/autoscale/ltm/f5_bigip_autoscale_ltm_instance_2_nic.yaml -e src/f5-openstack-hot/experimental/templates/solutions/autoscale/ltm/f5_bigip_autoscale_ltm_instance_2_nic.yaml
```

### Parameters
The following parameters can be defined in your environment file.
<br>

#### BIG-IP General Provisioning

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_image | Yes | The BIG-IP VE image to be used on the compute instance. | BIG-IP VE must be 13.0 or later |
| bigip_flavor | Yes | Type of instance (flavor) to be used for the VE. |  |
| use_config_drive | No | Use config drive to provide meta and user data. With the default value of false, the metadata service is used instead. |  |
| f5_cloudlibs_tag | No | Tag that determines version of F5 cloudlibs to use for provisioning (onboard helper).  |  |
| f5_cloudlibs_url_override |  | Alternate URL for f5-cloud-libs package. If not specified, the default GitHub location for f5-cloud-libs is used. If version is different from default f5_cloudlibs_tag, ensure that hashes are valid by either updating scripts/verifyHash or by providing a f5_cloudlibs_verify_hash_url_override value.  |  |
| f5_cloudlibs_verify_hash_url_override | No | Alternate URL for the verifyHash file.  |  |
| f5_cloudlibs_openstack_tag | No | Tag that determines version of F5 cloudlibs-openstack to use for provisioning (onboard helper).  |  |
| f5_cloudlibs_openstack_url_override |  | Alternate URL for f5-cloud-libs-openstack package. If not specified, the default GitHub location for f5-cloud-libs is used. If version is different from default f5_cloudlibs_tag, ensure that hashes are valid by either updating scripts/verifyHash or by providing a f5_cloudlibs_verify_hash_url_override value.  |  |
| bigip_servers_ntp | No | A list of NTP servers to configure on the BIG-IP. |  |
| bigip_servers_dns | No | A list of DNS servers to configure on the BIG-IP. |  |
| allow_usage_analytics | No | This deployment can send anonymous statistics to F5 to help us determine how to improve our solutions. If you select No, statistics are not sent.  |  |

#### BIG-IP Credentials

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_os_ssh_key | Yes | Name of the key-pair to be installed on the BIG-IP VE instance to allow root SSH access. |  |
| bigip_admin_pwd | Yes | Password for the BIG-IP admin user. |  |
| bigip_root_pwd | Yes | Password for the BIG-IP root user. |  |

#### BIG-IP Licensing and Modules

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigiq_license_host_ip | Yes | The IP address (or FQDN) for the existing BIG-IQ instance to be used when licensing the BIG-IP. | Must be reachable from the BIG-IP instance |
| bigiq_license_username | Yes | The BIG-IQ username to use to license the BIG-IP instances. |  |
| bigiq_license_pwd | Yes | The BIG-IQ password to use to license the BIG-IP instances. |  |
| bigiq_license_pool | Yes | The BIG-IQ License Pool to use to license the BIG-IP instances. |  |
| bigiq_use_bigip_floating_ip | Yes | Determines whether to use the floating ip of the BIG-IP for BIG-IQ licensing |  |
| bigip_modules | No | Modules to provision on the BIG-IP VE.  The default is `ltm:nominal` | Syntax: List of `module:level`. See [Parameter Values](#parameter-values) |

#### OS Network

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| external_network | Yes | Name of the external network where the floating IP resides. | Network must exist |
| mgmt_network | Yes | Network to which the BIG-IP management interface is attached. | Network must exist |
| mgmt_security_group_name | Yes | Name to apply on the security group for the BIG-IP management network. |  |
| network_vlan_security_group_name | Yes | Name to apply on the security group for BIG-IP VLAN. |  |
| network_vlan_name | Yes | OS Neutron Network to map to the BIG-IP VLAN | Network must exist |
| network_vlan_subnet | Yes | The Neutron Subnet for the corresponding BIG-IP VLAN.  | Subnet must exist |

#### BIG-IP Network

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_default_gateway | No | Optional upstream Gateway IP Address for the BIG-IP instance.  |  |
| bigip_mgmt_port | No | The default is 443 |  |
| bigip_vlan_name | No | Name of the VLAN to be created on the BIG-IP. The default is **data**. |  |
| bigip_vlan_mtu | No | MTU value of the VLAN on the BIG-IP. The default is **1400**. |  |
| bigip_vlan_tag | No | Tag to apply on the VLAN on the BIG-IP. Use the default value **None** for untagged. |  |
| bigip_vlan_nic | No | The NIC associated with the BIG-IP VLAN. For 2-NIC this defaults to **1.1** |  |
| bigip_self_cidr_block | Yes | CIDR Block for the BIG-IP self IP address. |  |
| bigip_self_port_lockdown | No | Optional list of service:port lockdown settings for the VLAN. If no value is supplied, the default is used.  |  Syntax: List of `service:port` example: `[tcp:443, tcp:22]` |


#### BIG-IP Cluster

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| bigip_device_group | No | Name of the BIG-IP Device Group to create or join. The default is **Sync**  |  |
| bigip_auto_sync | No | Toggles flag for enabling BIG-IP Cluster Auto Sync. The default is **true**.  |  |
| bigip_save_on_auto_sync | No | Toggles flag for enabling saving on config-sync auto-sync . The default is **true**.  |  |

#### OS Autoscale

| Parameter | Required | Description | Constraints |
| --- | :---: | --- | --- |
| autoscale_group_tag | Yes | String value to attach as metadata to instance to help identify membership in the autoscaling group  | Must be unique for the tenant.  |
| autoscale_meter_name | No | The meter on which to base the autoscale event. | The default is **network.incoming.bytes.rate** . **NOTE: Ceilometer must be configured accordingly.**  |
| autoscale_meter_stat | No | The meter statistic to evaluate. | Allowed values are [count, **avg**, sum, min] |
| autoscale_adjustment_type | No | Type of adjustment for the scaling policy. | Allowed values are [ **change_in_capacity**, exact_capacity, percent_change_in_capacity] |
| autoscale_policy_cooldown | No | The cooldown period for the scale up/down policy, in seconds |  |
| autoscale_group_cooldown | No | The cooldown period for the autoscale group, in seconds |  |
| autoscale_scale_up_threshold | No | The meter threshold value to evaluate against and trigger a scale UP |  |
| autoscale_scale_down_threshold | No | The meter threshold value to evaluate against and trigger a scale DOWN |  |
| autoscale_scale_up_operator | No | Operator used to compare specified statistic with threshold and trigger a scale UP. | Allowed values are [ge, **gt**, eq, ne, lt, le] |
| autoscale_scale_down_operator | No | Operator used to compare specified statistic with threshold and trigger a scale DOWN. | Allowed values are [ge, gt, eq, ne, **lt**, le] |
| autoscale_period | No | The period (seconds) to evaluate over. This is used to determine the amount of time needed for a threshold to be reached. |  |
| autoscale_num_eval_period | No | The number of periods to evaluate over. This is used to determine the amount of time needed for a threshold to be reached. |  |
| autoscale_set_min_count | No | The minimum number of BIG-IP VE instance to deploy in the scaling group. |  |
| autoscale_set_max_count | No | The maximum number of BIG-IP VE instances to deploy in the scaling group. |  |
| os_username | Yes | User name for OpenStack account that can perform heat, ceilometer, and swift operations |  |
| os_password | Password for OpenStack account that can perform heat, ceilometer, and swift operations |  |
| os_region | Yes | Region for OpenStack account that can perform  heat, ceilometer, and swift operations |  |
| os_auth_url | Yes | Auth Endpoint URL for OpenStack account that can perform  heat, ceilometer, and swift operations |  |
| os_auth_version | No | Version of the Auth URL | The default is **v3** |  |
| os_domain_name | No | Name of the OpenStack account domain | The default is **default |  |

<br>

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
  - Contact us at [solutionsfeedback@f5.com](mailto:solutionsfeedback@f5.com?subject=GitHub%20Feedback) for general feedback or enhancement requests. 
  - Use our [Slack channel](https://f5cloudsolutions.herokuapp.com) for discussion and assistance on F5 cloud templates. There are F5 employees who are members of this community who typically monitor the channel Monday-Friday 9-5 PST and will offer best-effort assistance.
  - For templates in the **supported** directory, contact F5 Technical support via your typical method for more time sensitive changes and other issues requiring immediate support.


## Copyright

Copyright 2014-2017 F5 Networks Inc.


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
completed and submitted the [F5 Contributor License Agreement](http://f5-openstack-docs.readthedocs.io/en/latest/cla_landing.html).
