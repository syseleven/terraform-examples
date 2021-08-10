# HTTPS load-balanced setup

## Overview

In this example we deploy a loadbalancer with SSL offloading and 3 
backend servers. Incoming requests are distributed round robin 
using plain HTTP. 


## Barbican secret container

This example requires a barbican secret container with the name `tls` that 
contains a certificate and a private key.

You can generate an example certificate and a private key using the 
following command:

```shell
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

The certificate and the private key can be stored in barbican with 
the following commands: 

```shell
openstack secret store -s certificate --file cert.pem --name cert
openstack secret store -s private --file  key.pem --name key
```

With the returning secret hrefs from the commands above the barbican
container can be created with 

```shell
openstack secret container create --name certificate --type certificate --secret certificate=<secret href of the cretificate> --secret private_key=<secret href of the private key>
```

