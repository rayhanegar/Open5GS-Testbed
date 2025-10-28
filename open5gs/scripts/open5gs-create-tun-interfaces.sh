#!/bin/bash

# Open5GS TUN Interface Management Script
# This script creates or removes TUN interfaces for each DNN in Open5GS
# Usage: 
#   sudo ./open5gs-create-tun-interfaces.sh --add     (create interfaces)
#   sudo ./open5gs-create-tun-interfaces.sh --remove  (remove interfaces)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
show_usage() {
    echo "Usage: $0 [--add|--remove]"
    echo ""
    echo "Options:"
    echo "  --add     Create TUN interfaces for Open5GS DNNs"
    echo "  --remove  Remove TUN interfaces for Open5GS DNNs"
    echo ""
    echo "TUN Interfaces managed:"
    echo "  ogstun   (10.45.0.1/24)  - eMBB slice (embb.testbed)"
    echo "  ogstun2  (10.45.1.1/24)  - URLLC slice (urllc.v2x)"
    echo "  ogstun3  (10.45.2.1/24)  - mMTC slice (mmtc.testbed)"
    echo ""
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Enable IPv4 forwarding
enable_ipv4_forwarding() {
    print_status "Enabling IPv4 forwarding..."
    
    # Enable immediately
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Make it persistent across reboots
    if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        print_success "IPv4 forwarding enabled and made persistent"
    else
        print_success "IPv4 forwarding enabled (already persistent)"
    fi
}

# Function to check if interface exists
interface_exists() {
    local interface=$1
    ip link show "$interface" &> /dev/null
}

# Function to add TUN interface
add_tun_interface() {
    local interface=$1
    local ip_addr=$2
    local subnet=$3
    local description=$4
    
    print_status "Setting up $interface ($description)..."
    
    # Check if interface exists
    if interface_exists "$interface"; then
        print_warning "Interface $interface already exists, updating IP address..."
        
        # Remove existing IP addresses
        ip addr flush dev "$interface" 2>/dev/null
        
        # Assign new IP address
        if ip addr add "$ip_addr" dev "$interface"; then
            print_success "IP address $ip_addr assigned to existing $interface"
        else
            print_error "Failed to assign IP address to $interface"
            return 1
        fi
        
        # Ensure interface is up
        ip link set "$interface" up
    else
        # Create new TUN interface
        if ip tuntap add name "$interface" mode tun; then
            print_success "TUN interface $interface created"
            
            # Assign IP address
            if ip addr add "$ip_addr" dev "$interface"; then
                print_success "IP address $ip_addr assigned to $interface"
            else
                print_error "Failed to assign IP address to $interface"
                return 1
            fi
            
            # Bring interface up
            if ip link set "$interface" up; then
                print_success "Interface $interface is now up"
            else
                print_error "Failed to bring up interface $interface"
                return 1
            fi
        else
            print_error "Failed to create TUN interface $interface"
            return 1
        fi
    fi
    
    # Add NAT rule (remove existing rule if present to avoid duplicates)
    iptables -t nat -D POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE 2>/dev/null
    
    if iptables -t nat -A POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE; then
        print_success "NAT rule added for subnet $subnet via $interface"
    else
        print_error "Failed to add NAT rule for $interface"
        return 1
    fi
    
    echo "----------------------------------------"
}

# Function to remove TUN interface
remove_tun_interface() {
    local interface=$1
    local subnet=$2
    local description=$3
    
    print_status "Removing $interface ($description)..."
    
    # Remove NAT rule
    if iptables -t nat -D POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE 2>/dev/null; then
        print_success "NAT rule removed for subnet $subnet"
    else
        print_warning "NAT rule for $subnet not found or already removed"
    fi
    
    # Remove interface if it exists
    if interface_exists "$interface"; then
        # Bring interface down first
        ip link set "$interface" down 2>/dev/null
        
        # Remove TUN interface
        if ip tuntap del name "$interface" mode tun; then
            print_success "TUN interface $interface removed"
        else
            print_error "Failed to remove TUN interface $interface"
            return 1
        fi
    else
        print_warning "Interface $interface does not exist"
    fi
    
    echo "----------------------------------------"
}

# Function to add all interfaces
add_all_interfaces() {
    print_status "Creating Open5GS TUN interfaces..."
    echo "=========================================="
    
    # Enable IPv4 forwarding first
    enable_ipv4_forwarding
    echo "----------------------------------------"
    
    # Interface definitions: name, ip/mask, subnet, description
    add_tun_interface "ogstun"  "10.45.0.1/24" "10.45.0.0/24" "eMBB slice (embb.testbed)"
    add_tun_interface "ogstun2" "10.45.1.1/24" "10.45.1.0/24" "URLLC slice (urllc.v2x)"
    add_tun_interface "ogstun3" "10.45.2.1/24" "10.45.2.0/24" "mMTC slice (mmtc.testbed)"
    
    echo "=========================================="
    print_success "All Open5GS TUN interfaces configured!"
    print_status "You can verify interfaces with: ip addr show | grep ogstun"
    print_status "You can verify NAT rules with: iptables -t nat -L POSTROUTING -v"
}

# Function to remove all interfaces
remove_all_interfaces() {
    print_status "Removing Open5GS TUN interfaces..."
    echo "=========================================="
    
    # Interface definitions: name, subnet, description
    remove_tun_interface "ogstun"  "10.45.0.0/24" "eMBB slice (embb.testbed)"
    remove_tun_interface "ogstun2" "10.45.1.0/24" "URLLC slice (urllc.v2x)"
    remove_tun_interface "ogstun3" "10.45.2.0/24" "mMTC slice (mmtc.testbed)"
    
    echo "=========================================="
    print_success "All Open5GS TUN interfaces removed!"
}

# Main script logic
main() {
    case "$1" in
        --add)
            check_root
            add_all_interfaces
            ;;
        --remove)
            check_root
            remove_all_interfaces
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            print_error "Invalid option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"