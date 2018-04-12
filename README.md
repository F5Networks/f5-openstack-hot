# F5 OpenStack HOT (Heat Orchestration Templates)

[![Slack Status](https://f5cloudsolutions.herokuapp.com/badge.svg)](https://f5cloudsolutions.herokuapp.com)
[![Releases](https://img.shields.io/github/release/f5networks/f5-openstack-hot.svg)](https://github.com/f5networks/f5-openstack-hot/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-openstack-hot.svg)](https://github.com/f5networks/f5-openstack-hot/issues)


## Introduction
 
Welcome to the GitHub repository for F5's Heat Orchestration Templates for deploying F5 in OpenStack environments.  All of the templates in this repository have been developed by F5 Networks engineers. Across all branches in this repository, there are two directories: *supported* and *experimental*

  - **supported**<br>
  The *supported* directory contains heat templates that have been created and fully tested by F5 Networks. These templates are fully supported by F5, meaning you can get assistance if necessary from F5 Technical Support via your typical methods.

  - **experimental**<br>
  The *experimental* directory also contains heat templates that have been created by F5 Networks. However, these templates have not completed full testing and are subject to change. F5 Networks does not offer technical support for templates in the experimental directory, so use these templates with caution.

## Template information
These templates employ similar pattern as OpenStack TripleO wherein the common/reusable templates and components such as software configs and scripts are referenced by parent templates. When launching a stack, you only need to specify the parent template as the template param, and Heat engine automatically takes care of the dependencies.

Descriptions for each template are contained at the top of each template in the *Description* key.
For additional information, and assistance in deploying a template, see the README file on the individual template pages.

### Template options
Each template category in this repo has sub-directories with different versions of a particular template. 
  - ***Existing Stack***  
  Templates under **existing_stack** directories deploy into an existing networking stack; meaning the networking infrastructure MUST be available prior to deploying. 
  - ***Prod Stack***  
  Templates under **prod_stack**  directories do not require an external network and do not create a floating IP address on the Neutron port.

Under each of those categories, some templates also contain both of the following sub-directories:
  - ***Dynamic***    
  Templates under **dynamic** directories use DHCP to dynamically determine the BIG-IP VE management IP address. All supported templates currently only have this option.
  - ***Static***    
  Templates under **static** directories require you to configure the BIG-IP VE management IP address statically.  This is useful if there is no DHCP server available, or if it is disabled on the neutron subnet.  Many of the templates in the Experimental directory now have this option. 

### Matrix for tagged releases
F5 has created a matrix that contains all of the tagged releases of the F5 OpenStack Heat Orchestration templates, and the corresponding BIG-IP versions available for a specific tagged release. See https://github.com/F5Networks/f5-openstack-hot/blob/master/openstack-bigip-version-matrix.md.

## CVE-2017-6168 information
If you have launched an F5 CFT template from a prior release, see the <a href="#important">important note</a> at the bottom of this page.

## Supported Versions

### BIG-IP VE
The templates are developed for standard BIG-IP Virtual Edition images version **13.0 or later**.
Earlier versions may require image patching to create OpenStack-ready images in *glance*.
**Note:**
Refer to [f5-openstack-heat](https://github.com/F5Networks/f5-openstack-heat) for templates that launch pre-version 13.0 instances.

### OpenStack
The templates are developed on an operational OpenStack Mitaka deployment.
For additional resources on configuring environments with F5 Integration for OpenStack Neutron LBaaS, refer to this [configuration guide](http://clouddocs.f5.com/cloud/openstack/v1/lbaas/index.html)

## Prerequisites
The following is a summary of prerequisites for successfully launching templates from this repo:
  - Neutron Components:
    - Management network and subnet (where management UI can be accessed)
    - External network and subnet (where floating IP resides)
    - Additional network(s) and subnet(s) (e.g. Data Subnet)
    - Corresponding router(s) configuration
  - Nova Components:
    - Key pair for SSH access to BIG-IP VE
  - Heat Components:
    - [f5-openstack-heat-plugins](https://github.com/F5Networks/f5-openstack-heat-plugins) is optional. It is only needed if you need to reference a custom resource type that does not exist in the `resource_registry` section of the environment file. 
  - Glance Components:
    - BIG-IP Virtual Edition Image Version 13.0 or later added to Images. The image file must be in qcow.zip format and can be any size (ALL, LTM, or LTM_1SLOT).

**Note**: The templates use cloud-init for provisioning. To mitigate security risks associated with retrieving cloud-config data, or if you do not fully trust the medium over which your cloud-config will be stored and/or transmitted, we recommend you change your passwords after stack creation has been completed successfully. 


## List of Supported F5 OpenStack Heat Orchestration templates 
The following is a list of the current *supported* F5 OpenStack HOT templates. Click the links to view the README files which include the deployment instructions and additional information.

**Standalone 1 NIC**
  - [Existing Stack](https://github.com/F5Networks/f5-openstack-hot/tree/master/supported/templates/standalone/1nic/existing_stack/dynamic)
  - [Prod Stack](https://github.com/F5Networks/f5-openstack-hot/tree/master/supported/templates/standalone/1nic/prod_stack/dynamic)

**Standalone nNIC**
  - [Existing Stack](https://github.com/F5Networks/f5-openstack-hot/tree/master/supported/templates/standalone/nnic/existing_stack/dynamic)
  - [Prod Stack](https://github.com/F5Networks/f5-openstack-hot/tree/master/supported/templates/standalone/nnic/prod_stack/dynamic)
  
**Cluster 2 NIC**
  - [Existing Stack](https://github.com/F5Networks/f5-openstack-hot/tree/master/supported/templates/cluster/2nic/existing_stack/dynamic)
  - [Prod Stack](https://github.com/F5Networks/f5-openstack-hot/tree/master/supported/templates/cluster/2nic/prod_stack/dynamic)
  



<br>
<a name="important"></a>
<table>
 <tr>
  <td align=center>:warning: <strong>IMPORTANT<strong> :warning:  </td>
 </tr>
 <tr>
  <td>BIG-IP virtual servers configured with a Client SSL profile may be vulnerable to an Adaptive Chosen Ciphertext attack (AKA Bleichenbacher attack). For complete information on this vulnerability, see https://support.f5.com/csp/article/K21905460. <br>F5 has released hotfixes for all vulnerable releases. <br>  
   <ul>
    <li><em>If you have an existing BIG-IP VE deployment in using an F5 OpenStack Heat Orchestration Template </em>  <br>See the <a href="https://support.f5.com/csp/article/K21905460">Security Advisory</a>, which contains information about upgrading your BIG-IP VE to a non-vulnerable version.</li>
    <li><em>For <strong>new</strong> BIG-IP VE deployments in OpenStack</em><br> F5 has uploaded new, non-vulnerable BIG-IP versions to downloads.f5.com.  Ensure you download the latest HF version. See the <a href="https://support.f5.com/csp/article/K21905460">Security Advisory</a> for details.</li>
    
   </ul></td>
 </tr>
</table>


### Copyright

Copyright 2014-2018 F5 Networks Inc.


### License


### Apache V2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations
under the License.


### Contributor License Agreement

Individuals or business entities who contribute to this project must have
completed and submitted the `F5 Contributor License Agreement`