# TCP load-balanced setup

## Overview

In this example we deploy a TCP-based load balancer using the Neutron LBaaS v2
API. Incoming requests are distributed round-robin.

## Neutron LBaaS v2 vs. Octavia

Neutron LBaaS is not available in all SysEleven regions. If you want to deploy
a TCP load balancer using the Octavia API instead (available in all regions),
you may simply edit the provider block in the beginning of `main.tf` and
set `use_octavia = true` there.

Please note that recent versions of the
Terraform OpenStack provider removed support for Neutron LBaaS.
The example here sets an upper limit for the version of the OpenStack provider.
Version 1.54.1 was the last version to support Neutron LBaaS.
Starting with provider version 2.0.0 you must not set `use_octavia` anymore
as Octavia is the only supported LBaaS variant.
