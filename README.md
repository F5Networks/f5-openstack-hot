# F5 OpenStack HOT (Heat Orchestration Templates)

## Introduction
 
Welcome to the GitHub repository for F5's Heat Orchestration Templates for deploying F5 in OpenStack environments.  All of the templates in this repository have been developed by F5 Networks engineers. Across all branches in this repository, there are two directories: *supported* and *experimental*

  - **supported**<br>
  The *supported* directory contains heat templates that have been created and fully tested by F5 Networks. These templates are fully supported by F5, meaning you can get assistance if necessary from F5 Technical Support via your typical methods.

  - **experimental**<br>
  The *experimental* directory also contains heat templates that have been created by F5 Networks. However, these templates have not completed full testing and are subject to change. F5 Networks does not offer technical support for templates in the experimental directory, so use these templates with caution.

## Template information
These templates employ similar pattern as Openstack TripleO wherein the common/reusable templates and components such as software configs and scripts are referenced by parent templates. When launching a stack, you only need to specify the parent template as the template param, and Heat engine automatically takes care of the dependencies. 

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
For resources on configuring OpenStack environments, please refer to this [configuration guide](https://f5-openstack-docs.readthedocs.io/en/latest/) 
**Note:**
The section [Launch BIG-IP VE in OpenStack](https://f5-openstack-docs.readthedocs.io/en/latest/guides/map_launch-bigip-gui.html) only applies to pre-version 13.0 instances. 

## Prerequisites
The following is a summary of prerequisites for sucessfully launching templates from this repo:
  - Neutron Components:
    - Management network and subnet (where management UI can be accessed)
    - External network and subnet (where floating IP resides)
    - Additional network(s) and subnet(s) (e.g. Data Subnet)
    - Corresponding router(s) configuration
    - Ensure [f5-openstack-lbaasv2-driver](https://f5-openstack-lbaasv2-driver.readthedocs.io/en/latest/) is installed. This should be configured as part of the operational Mitaka deployment.
  - Nova Components:
    - Key pair for SSH access to BIG-IP VE
  - Heat Components:
    - [f5-openstack-heat-plugins](https://f5-openstack-heat-plugins.readthedocs.io/en/latest/) is optional and only needed if you reference a custom resource type in the env files. 
  - Glance Components:
    - BIG-IP Virtual Edition Image Version 13.0 or later added to Images. The image file must be in qcow.zip format and can be any size (ALL, LTM, or LTM_1SLOT).

### Copyright

Copyright 2014-2017 F5 Networks Inc.


### License


Apache V2.0
~~~~~~~~~~~
Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at:

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