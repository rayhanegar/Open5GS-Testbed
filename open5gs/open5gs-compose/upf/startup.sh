#!/usr/bin/env bash
# UPF Startup Script - Creates TUN interfaces and launches Open5GS UPF safely
set -euo pipefail

NF_USER=${NF_USER:-open5gs}
NF_GROUP=${NF_GROUP:-open5gs}
LOG_DIR=${NF_LOG_DIR:-/var/log/open5gs}
RUN_DIR=${NF_RUN_DIR:-/var/run/open5gs}
CONFIG_SRC=${NF_CONFIG_SRC:-/etc/open5gs/custom/upf.yaml}
CONFIG_DST=${NF_CONFIG_DST:-/etc/open5gs/upf.yaml}

mkdir -p "${LOG_DIR}" "${RUN_DIR}" "$(dirname "${CONFIG_DST}")"
chown -R "${NF_USER}:${NF_GROUP}" "${LOG_DIR}" "${RUN_DIR}"

if [ -f "${CONFIG_SRC}" ]; then
    cp "${CONFIG_SRC}" "${CONFIG_DST}"
    chown "${NF_USER}:${NF_GROUP}" "${CONFIG_DST}"
fi

echo "Creating TUN interfaces for Open5GS UPF..."

# Function to create and configure TUN interface
create_tun_interface() {
    local IFACE=$1
    local SUBNET=$2
    local GATEWAY=$3
    
    # Create TUN interface if it doesn't exist
    if ! ip link show $IFACE > /dev/null 2>&1; then
        echo "Creating interface $IFACE..."
        ip tuntap add name $IFACE mode tun
        ip addr add $GATEWAY/24 dev $IFACE
        ip link set dev $IFACE up
        echo "Interface $IFACE created with IP $GATEWAY"
    else
        echo "Interface $IFACE already exists"
    fi
}

# Create TUN interfaces for each DNN
# DNN: embb.testbed
create_tun_interface ogstun 10.45.0.0 10.45.0.1

# DNN: urllc.v2x  
create_tun_interface ogstun2 10.45.1.0 10.45.1.1

# DNN: mmtc.testbed
create_tun_interface ogstun3 10.45.2.0 10.45.2.1

# IPv6 for embb.testbed
if ! ip -6 addr show dev ogstun | grep -q "2001:db8:cafe::1"; then
    ip -6 addr add 2001:db8:cafe::1/48 dev ogstun
    echo "IPv6 address added to ogstun"
fi

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Configure iptables NAT rules for each subnet
echo "Configuring NAT rules..."
iptables -t nat -C POSTROUTING -s 10.45.0.0/24 ! -o ogstun -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 10.45.0.0/24 ! -o ogstun -j MASQUERADE
iptables -t nat -C POSTROUTING -s 10.45.1.0/24 ! -o ogstun2 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 10.45.1.0/24 ! -o ogstun2 -j MASQUERADE
iptables -t nat -C POSTROUTING -s 10.45.2.0/24 ! -o ogstun3 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 10.45.2.0/24 ! -o ogstun3 -j MASQUERADE
ip6tables -t nat -C POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE 2>/dev/null || \
    ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE

# Accept input on TUN interfaces
iptables -C INPUT -i ogstun -j ACCEPT 2>/dev/null || iptables -I INPUT -i ogstun -j ACCEPT
iptables -C INPUT -i ogstun2 -j ACCEPT 2>/dev/null || iptables -I INPUT -i ogstun2 -j ACCEPT
iptables -C INPUT -i ogstun3 -j ACCEPT 2>/dev/null || iptables -I INPUT -i ogstun3 -j ACCEPT
ip6tables -C INPUT -i ogstun -j ACCEPT 2>/dev/null || ip6tables -I INPUT -i ogstun -j ACCEPT

echo "TUN interfaces configured successfully"

# Start UPF daemon
echo "Starting Open5GS UPF daemon..."
exec gosu "${NF_USER}:${NF_GROUP}" /usr/bin/open5gs-upfd -c "${CONFIG_DST}"