#!/bin/bash

# Check VPN file
ovpn_file=$(find "/vpn" -type f -name "*.ovpn" -print -quit)

if [ -n "$ovpn_file" ]; then
    echo "ovpn file found: $ovpn_file"
else
    echo "No .ovpn file found in '/vpn', exiting ..."
    exit 1
fi

# Check auth file
auth_file=$(find "/vpn" -type f -name "*.auth" -print -quit)

if [ -n "$auth_file" ]; then
    echo "auth file found: $auth_file"
else
    echo "No .auth file found in '/vpn', Exiting..."
    exit 1
fi

# Setup DNS
DNS="$DNS_SERVER"
# Update the DNS server in the Squid configuration (squid.conf)
sed -i "s/^dns_nameservers .*/dns_nameservers $DNS/" /etc/squid/squid.conf

# Check if the /etc/resolv.conf file exists
if [ -e "/etc/resolv.conf" ]; then
    # Create a new /etc/resolv.conf file with the specified DNS server
    echo "nameserver $DNS" > /etc/resolv.conf

    # Check if the write operation was successful
    if [ $? -eq 0 ]; then
        echo "$DNS setup as DNS server"
    else
        echo "Can't write in /etc/resolv.conf. Exiting..."
        exit 1
    fi
else
    echo "/etc/resolv.conf didn't exist. Can't setup DNS. Exiting..."
    exit 1
fi

# Start the VPN
openvpn --config "$ovpn_file" --auth-user-pass "$auth_file" --daemon

# Wait for the VPN connection to be established
sleep 10

# Get the IP address of the tun0 interface
tun0_ip=$(ip addr show tun0 | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}')

# Check if tun0_ip is not empty
if [ -z "$tun0_ip" ]; then
    echo "Failed to obtain IP address for tun0. Exiting..."
    exit 1
fi

echo "tun0 IP address: $tun0_ip"

# Add routing rule to forward all traffic from Squid through tun0
ip rule add from all to "$tun0_ip" table 128
ip route add default via "$tun0_ip" table 128

# Add routing rule to forward all traffic to 1.0.0.1 via tun0
ip route add 1.0.0.1 via "$tun0_ip"

# Start Squid
squid

# Check VPN connectivity
check_vpn_connection() {
    ping -c 4 -I tun0 1.0.0.1 > /dev/null
    return $?
}

# Wait and check VPN connectivity every 30 seconds
while true; do
    if check_vpn_connection; then
        echo "VPN connection check successful."
    else
        echo "VPN connection failed. Stopping container..."
        exit 1
    fi
    sleep 30
done