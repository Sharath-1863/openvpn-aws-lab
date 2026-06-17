# Architecture

## Network Diagram

```
 Laptop / Phone (OpenVPN Client)
            |
            |  OpenVPN tunnel, UDP 1194
            v
        Internet
            |
            v
   AWS EC2 Instance (Public IP)
            |
            v
     OpenVPN Server (daemon)
            |
            v
   tun0 Interface (10.8.0.1)
            |
            v
   VPN Network (10.8.0.0/24)
            |
            v
   NAT (iptables) --> eth0 --> Internet
```

## Components

| Component | Description |
|---|---|
| Client | Laptop or phone running the OpenVPN client, connects using a `.ovpn` profile and certificate issued by the CA |
| Internet | Public network the client traverses to reach the EC2 instance's public IP |
| AWS EC2 Instance | Ubuntu host running the OpenVPN server, exposed on UDP 1194, with a Security Group rule allowing that port |
| OpenVPN Server | Daemon that authenticates clients via TLS certificates and assigns each one an IP from the VPN subnet |
| tun0 | Virtual network interface created by OpenVPN on the server; acts as the gateway for the VPN subnet at `10.8.0.1` |
| VPN Network | `10.8.0.0/24`, the private address space handed out to connected clients |
| NAT (iptables) | Masquerades VPN client traffic out through the server's `eth0` interface so clients can reach the internet through the EC2 instance |

## Traffic Flow

1. The client establishes a UDP connection to the EC2 instance's public IP on port 1194 and completes a TLS handshake using its certificate and the CA.
2. Once authenticated, OpenVPN assigns the client an address from `10.8.0.0/24` (e.g. `10.8.0.2`) and routes its traffic through the `tun0` interface.
3. IP forwarding on the EC2 instance allows traffic to move from `tun0` to `eth0`.
4. iptables NAT rules rewrite the source address of outbound packets so they appear to originate from the EC2 instance, letting the client reach the public internet.
5. Return traffic follows the reverse path: `eth0` to `tun0` to the client over the encrypted tunnel.

## Ports and Protocols

- OpenVPN: UDP 1194 (server listener)
- SSH (management): TCP 22, restricted to the admin's IP in the Security Group
