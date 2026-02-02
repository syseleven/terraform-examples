# OpenStack Octavia HTTP Load Balancer with IPv4 and IPv6

This Terraform example demonstrates how to create a load balancer using OpenStack Octavia that supports both IPv4 and IPv6 traffic.

## Overview

This configuration creates:
- **3 Application Instances** running nginx web servers
- **1 Jumphost** for SSH access to the network
- **IPv4 Load Balancer** with floating IP for HTTP traffic
- **IPv6 Load Balancer** for IPv6 HTTP traffic
- **Security Groups** allowing HTTP (80), SSH (22), and ICMP traffic
- **Floating IPs** for external access to the load balancer and jumphost

## Important Note

**This is a temporary solution** until OpenStack Octavia is updated to a version newer than Zed. Dual-stack load balancers are not available in the current version of Octavia, so this configuration creates separate IPv4 and IPv6 load balancers as a workaround.

## Requirements

- OpenStack environment with:
  - Octavia service (load balancer)
  - Neutron networking service
  - Nova compute service
  - Ubuntu 24.04 image available in Glance
  - External network named "ext-net"
  - IPv6 subnet pool named "subnet-pool-v6_1"
- Terraform >= 0.14
- OpenStack Terraform provider >= 2.0.0
- SSH public key for jumphost access

## Usage

1. **Configure variables:**
   Edit `vars.tf` to set your SSH public key. For OpenStack credentials, use environment variables or the OpenStack provider configuration.

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

5. **Access the load balancer:**
   - IPv4: `http://<floating-ip>`
   - IPv6: `http://[<ipv6-address>]`

6. **SSH to jumphost:**
   ```bash
   ssh -i <your-key> ubuntu@<jumphost-floating-ip>
   ```

## Outputs

After successful deployment, the following outputs will be available:

- `loadbalancer_http`: The IPv4 load balancer URL
- `loadbalancer_http_ipv6`: The IPv6 load balancer URL

## Components

### Network Configuration
- Creates a private network `net_lbdemo` with IPv4 subnet `192.168.1.0/24`
- Creates an IPv6 subnet using the specified subnet pool
- Sets up a router connected to the external network

### Load Balancer Configuration
- **IPv4 Load Balancer**: Listens on port 80, uses ROUND_ROBIN algorithm
- **IPv6 Load Balancer**: Listens on port 80, uses ROUND_ROBIN algorithm
- **Health Monitor**: HTTP health check every 10 seconds with 5 second timeout
- **Members**: 3 backend instances for both IPv4 and IPv6 load balancers

### Security Groups
- `sg_icmp`: Allows ICMP traffic (both IPv4 and IPv6)
- `sg_ssh`: Allows SSH access (IPv4 only)
- `sg_web`: Allows HTTP traffic (IPv4 only)

### Application Instances
- 3 instances running nginx web server
- Each instance displays its hostname in the default nginx page
- Configured with user_data for automatic nginx installation

## Cleanup

To remove all resources:

```bash
terraform destroy
```