# F5 OpenStack HOT (Heat Orchestration Templates)

[![Slack Status](https://f5cloudsolutions.herokuapp.com/badge.svg)](https://f5cloudsolutions.herokuapp.com)
[![Releases](https://img.shields.io/github/release/f5networks/f5-openstack-hot.svg)](https://github.com/f5networks/f5-openstack-hot/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-openstack-hot.svg)](https://github.com/f5networks/f5-openstack-hot/issues)

<table>
 <tr>
  <td align=center>:warning: <strong>CRITICAL<strong> :warning:  </td>
 </tr>
 <tr>
  <td>BIG-IP virtual servers configured with a Client SSL profile may be vulnerable to an Adaptive Chosen Ciphertext attack (AKA Bleichenbacher attack). For complete information on this vulnerability, see https://support.f5.com/csp/article/K21905460. <br>F5 has released hotfixes for all vulnerable releases. <br>  
   <ul>
    <li><em>If you have an existing BIG-IP VE deployment in using an F5 OpenStack Heat Orchestration Template </em>  <br>See the <a href="https://support.f5.com/csp/article/K21905460">Security Advisory</a>, which contains information about upgrading your BIG-IP VE to a non-vulnerable version.</li>
    <li><em>For <strong>new</strong> BIG-IP VE deployments in OpenStack</em><br> F5 has uploaded new, non-vulnerable BIG-IP versions to downloads.f5.com.  Ensure you download the latest HF version. See the <a href="https://support.f5.com/csp/article/K21905460">Security Advisory</a> for details.</li>
    
   </ul></td>
 </tr>
 </table>

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

## Supported Versions

### BIG-IP VE
The templates are developed for standard BIG-IP Virtual Edition images version **13.0 or later**. 
Earlier versions may require image patching to create OpenStack-ready images in *glance*. 
**Note:**
Please refer to [f5-openstack-heat](https://github.com/F5Networks/f5-openstack-heat) for templates that launch pre-version 13.0 instances. 

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

### Copyright

Copyright 2014-2017 F5 Networks Inc.


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
