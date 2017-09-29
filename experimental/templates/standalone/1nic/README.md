# Deploying the BIG-IP in OpenStack - 1 NIC

## Introduction
 
This solution uses a Heat Orchestration Template to launch a 1-NIC deployment of a BIG-IP VE in an Openstack Private Cloud. Traffic flows from the BIG-IP VE to the application servers. This is the standard Cloud design where the compute instance of F5 is running with a single interface, which processes both management and data plane traffic. This is a traditional model in the cloud where the deployment is considered one-armed.

The **standalone** heat orchestration template incorporates existing networks defined in Neutron. 

## Prerequisites and configuration notes
  - Management Interface IP is determined via DHCP. 
  - If you do not specify a URL override (the parameter name is f5_cloudlibs_url_override), the default location is GitHub and the subnet for the management network requires a route and access to Internet for the initial configuration to download the BIG-IP cloud library.
  - If you specify a value for f5_cloudlibs_url_override or f5_cloudlibs_tag, ensure that corresponding hashes are valid by either updating scripts/verifyHash or by providing a f5_cloudlibs_verify_hash_url_override value.
  - :exclamation:**Important**: This [article](https://support.f5.com/csp/article/K13092#userpassword) contains links to information regarding BIG-IP user and password management. Please take note of the following when supplying password values:
      - The BIG-IP version and any default policies that may apply
      - Any characters recommended that you avoid
  - This template leverages the built in heat resource type *OS::Heat::WaitCondition* to track status of onboarding by sending signals to the orchestration API.

## Security
This Heat Orchestration Template downloads helper code to configure the BIG-IP system. If you want to verify the integrity of the template, you can open and modify definition of verifyHash file in /scripts/verifyHash.

Instance configuration data is retrieved from metadata service. OpenStack supports encrypting the metadata traffic.
If SSL is enabled in your environment, ensure that calls to the metadata service in the templates are updated accordingly.
For more information, please refer to:
- https://docs.openstack.org/heat/latest/template_guide/software_deployment.html
- https://docs.openstack.org/nova/latest/admin/security.html#encrypt-compute-metadata-traffic

## Supported instance types and OpenStack versions:
 - BIG-IP Virtual Edition Image Version 13.0 or later
 - OpenStack Mitaka Deployment

### Help
While this template has been created by F5 Networks, it is in the experimental directory and therefore has not completed full testing and is subject to change.  F5 Networks does not offer technical support for templates in the experimental directory. For supported templates, see the templates in the **supported** directory.

We encourage you to use our [Slack channel](https://f5cloudsolutions.herokuapp.com) for discussion and assistance on F5 Cloud templates.  This channel is typically monitored Monday-Friday 9-5 PST by F5 employees who will offer best-effort support.


## Launching Stacks

1. Ensure the prerequisites are configured in your environment. See README from this project's root folder. 
2. Clone this repository or manually download the contents (zip/tar). As the templates use nested stacks and referenced components, we recommend you retain the project structure as-is for ease of deployment.
3. Locate and update the environment file (_env.yaml) with the appropriate parameter values. Note that some default values will be used if no value is specified for an optional parameter. 
4. Launch the stack using the OpenStack CLI with a command like the following:

#### CLI Syntax
`openstack stack create <stackname> -t <path-to-template> -e <path-to-env>`

#### CLI Example
```
openstack stack create stack-1NIC-test -t src/f5-openstack-hot/experimental/templates/standalone/1nic/f5_bigip_standalone_1_nic.yaml -e src/f5-openstack-hot/experimental/templates/standalone/1nic/f5_bigip_standalone_1_nic_env.yaml
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
| bigip_license_key | x | Primary BIG-IP VE License Base Key |  |
| bigip_addon_license_keys |  | Additional BIG-IP VE License Keys |  |
| bigip_modules |  | Modules to provision on the BIG-IP.  Default `ltm:nominal` | Syntax: List of `module:level`. See [Parameter Values](#parameter-values) |

#### OS Network

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| external_network | x | Name of external network where floating IP resides. | Network must exist |
| mgmt_network | x | Network to which the BIG-IP management interface is attached. | Network must exist |
| mgmt_security_group_name | x | Name to apply on the security group for the BIG-IP management network. |  |

#### BIG-IP Network

| Parameter | Required | Description | Constraints |
| --- | --- | --- | --- |
| bigip_mgmt_port |  | Default 8443 |  |

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