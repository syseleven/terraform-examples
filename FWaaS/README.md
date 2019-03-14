This example creates two networks with two subnets and adds a VM in each network. 

A firewall is created that allows only SSH and drops ICMP traffic.

To test the firewall you can edit the icmp rule:

```neutron firewall-rule-update --action allow my-rule-2```

Now ping should work between the VMs.
