# Based Image
FROM debian:12.1

# Don't ask confirmation
ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
&& apt install --yes --no-install-recommends \
openvpn \
iputils-ping \
curl \
iproute2 \
dnsutils \
squid \
&& rm -rf /var/lib/apt/lists/*

VOLUME /vpn

# Copy entrypoint make it as executable and run it
COPY entrypoint.sh /opt/
RUN chmod +x /opt/entrypoint.sh

# Squid configuration
COPY squid.conf /etc/squid/

# Expose proxy port
EXPOSE 3128

# Set the default values for the port and DNS using environment variables
ENV DNS_SERVER=8.8.8.8

# ENTRYPOINT will directly run the script without a shell
ENTRYPOINT ["/opt/entrypoint.sh"]
