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
Terraform OpenStack provider changed the default value for `use_octavia`
to `true`. So we recommend to always set `use_octavia` explicitly, either
to `false` to use Neutron L4 load balancers where available or to `true`
to use Octavia.
