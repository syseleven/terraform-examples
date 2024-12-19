# Firewall-as-a-Service (FWaaS): Firewall groups example

## Overview

In this example we deploy a virtual machine, a router and a firewall group
that protects the network including the VM.

## Firewall group

The fireall group in this example allows HTTP and SSH into the internal subnet and HTTP, HTTPS and DNS to the outside.
Some rules like `allow_to_http` are used twice, for ingress and egress policies.

* group `firewall_group`
  * ingress policy `ingress_policy`
    * rule `allow_to_http` (allow destination port 80) to reach the HTTP service in the VM
    * rule `allow_to_ssh` (allow destination port 22) to reach the VM
    * rule `allow_from_http` (allow source port 80) for return traffic from external HTTP servers
    * rule `allow_from_https` (allow source port 443) for return traffic from external HTTPS servers
    * rule `allow_from_dns` (allow source port 53) for return traffic from external DNS servers
    * rule `deny` (deny all)
  * egress policy `egress_policy`
    * rule `allow_from_http` (allow source port 80) for return traffic from VM's HTTP server
    * rule `allow_from_ssh` (allow source port 22) for return traffic from VM's SSH server
    * rule `allow_to_http` (allow source port 80) to reach external HTTP servers
    * rule `allow_to_https` (allow source port 443) to reach external HTTPS servers
    * rule `allow_to_dns` (allow source port 53) to reach external DNS servers
    * rule `deny` (deny all)

## Example VM

The VM created in this example hosts an HTTP server that simply returns the host name when queried.
