# ovpn-prox

This container allows you to easily run a secure Docker container with a configured VPN tunnel and Squid proxy. All outgoing traffic from the container goes through the VPN, ensuring a private and protected Internet connection.

To make the container work correctly, it is necessary to map a directory containing files with the extensions .ovpn and .auth from the host to the /vpn directory inside the container. The specific file names are not important, as long as they end with the required extensions.

The .ovpn file should contain the OpenVPN connection configuration, while the .auth file should include the login credentials with the username on the first line and the password on the second line.

This is achieved using Docker's volume mapping feature by specifying the full path of the directory containing the .ovpn and .auth files on the host, followed by :/vpn to link this directory to the /vpn directory inside the container. This way, the container will have access to these files to establish the VPN connection and configure the Squid proxy.
ex: `/chemin/vers/dossier:/vpn`

Example with Docker Compose:
```version: '3.8'

services:
  openvpn:
    image: jr0w3/ovpn-prox:latest
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=0
    volumes:
      - /chemin/vers/dossier:/vpn
    environment:
      - DNS_SERVER=8.8.8.8   # Default DNS server if not provided
    ports:
      - "3128:3128" # Squid proxy port
```
