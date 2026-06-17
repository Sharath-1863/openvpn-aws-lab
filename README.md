# OpenVPN Server Setup on AWS EC2

## Environment

- AWS EC2
- Ubuntu
- OpenVPN 2.7
- Easy-RSA 3

## Steps Performed

1. Created EC2 instance
2. Installed OpenVPN and Easy-RSA
3. Initialized PKI
4. Created Certificate Authority (CA)
5. Generated server certificate
6. Generated client certificate
7. Generated DH parameters
8. Generated TLS authentication key
9. Created OpenVPN server configuration
10. Enabled IP forwarding
11. Configured NAT using iptables
12. Started OpenVPN service
13. Verified `tun0` interface
14. Automated client creation using Bash script

## OpenVPN Network

VPN Network: `10.8.0.0/24`

Example:

- Server: `10.8.0.1`
- Client1: `10.8.0.2`
- Client2: `10.8.0.3`

## OpenVPN Port

UDP `1194`

## Client Creation

```bash
sudo ./create-client.sh laptop
```

Generated:

```
/home/ubuntu/client-configs/laptop/laptop.ovpn
```
