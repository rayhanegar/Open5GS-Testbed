#!/bin/bash

# Host network configuration script for Open5GS containers
# This script sets up the host networking to allow external access to containers

echo "============================================"
echo "Open5GS Container Network Setup Script"
echo "============================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script with sudo"
    exit 1
fi

# Control whether iptables rules are persisted across reboots (default: disabled)
SAVE_RULES=${SAVE_RULES:-false}

echo ""
echo "1. Enabling IP forwarding..."
# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Enable IPv6 forwarding
sysctl -w net.ipv6.conf.all.forwarding=1
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

echo ""
echo "2. Setting up iptables rules for container access..."

# Allow forwarding from Docker network
iptables -A FORWARD -s 10.10.0.0/24 -j ACCEPT
iptables -A FORWARD -d 10.10.0.0/24 -j ACCEPT

# NAT for container network to access Internet
iptables -t nat -A POSTROUTING -s 10.10.0.0/24 ! -d 10.10.0.0/24 -j MASQUERADE

# Allow UE traffic from UPF (10.45.0.0/16 is UE subnet)
iptables -t nat -A POSTROUTING -s 10.45.0.0/16 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 -j MASQUERADE

# Port forwarding for external gNB access via ICN Ethernet
# Get ICN Ethernet IP from enp3s20 interface
ICN_ETH_IP=$(ip -4 addr show enp3s20 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)

if [ -z "$ICN_ETH_IP" ]; then
    echo "Warning: ICN Ethernet interface (enp3s20) not found or no IP assigned"
    echo "Please ensure ICN Ethernet is running and authenticated"
    exit 1
fi

echo "Detected ICN Ethernet IP: $ICN_ETH_IP"

# Forward SCTP port for AMF (NGAP)
iptables -t nat -A PREROUTING -p sctp --dport 38412 -j DNAT --to-destination 10.10.0.5:38412

# Forward UDP port for UPF (GTP-U/N3)
iptables -t nat -A PREROUTING -p udp --dport 2152 -j DNAT --to-destination 10.10.0.7:2152
iptables -t nat -A PREROUTING -p udp --dport 2153 -j DNAT --to-destination 10.10.0.7:2153

echo ""
echo "3. Configuring SCTP..."
# Load SCTP kernel module if not already loaded
modprobe sctp

# Check if SCTP module is loaded
if lsmod | grep -q sctp; then
    echo "SCTP module loaded successfully"
else
    echo "Warning: SCTP module could not be loaded. AMF N2 interface may not work."
fi

if [ "$SAVE_RULES" = "true" ]; then
    echo ""
    echo "4. Saving iptables rules..."
    # Save iptables rules (Ubuntu/Debian)
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
        echo "Rules saved using netfilter-persistent"
    elif command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4
        ip6tables-save > /etc/iptables/rules.v6
        echo "Rules saved to /etc/iptables/"
    fi
else
    echo ""
    echo "4. Skipping persistent iptables save (set SAVE_RULES=true to enable)"
fi

echo ""
echo "5. Docker network verification..."
# Check if Docker network exists
if docker network ls | grep -q "open5gs-containers_5gcore"; then
    echo "Docker network 'open5gs-containers_5gcore' exists"
else
    echo "Docker network will be created when you run docker-compose up"
fi

echo ""
echo "============================================"
echo "Network setup completed!"
echo ""
echo "Important notes:"
echo "1. AMF NGAP is accessible on port 38412 (SCTP)"
echo "2. UPF GTP-U is accessible on ports 2152-2153 (UDP)"
echo "3. SBI interfaces are accessible on ports 77xx (TCP)"
echo "4. Your gNB should connect to $ICN_ETH_IP:38412 for N2 interface"
echo "5. Your gNB should connect to $ICN_ETH_IP:2152 for N3 interface"
echo ""
echo "To start the Open5GS containers:"
echo "  docker-compose up -d"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f [service_name]"
echo ""
echo "To stop containers:"
echo "  docker-compose down"
echo "============================================"