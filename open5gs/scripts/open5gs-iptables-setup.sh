#!/bin/bash

# Enhanced 5G Testbed Firewall Setup Script
# Usage: ./setup-iptables.sh [--add|--remove|--status]
# Author: 5G CNF Research Testbed

set -e  # Exit on any error

# Configuration variables
SCRIPT_NAME="5G Testbed Iptables Manager"
VERSION="1.0"
BACKUP_DIR="/etc/open5gs/iptables-backup"
BACKUP_FILE="$BACKUP_DIR/iptables-backup-$(date +%Y%m%d-%H%M%S).rules"

# Network configuration
declare -a TUN_INTERFACES=("ogstun" "ogstun2" "ogstun3")
declare -a SUBNETS=("10.45.0.0/24" "10.45.1.0/24" "10.45.2.0/24")
declare -a SLICE_NAMES=("eMBB" "URLLC" "mMTC")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$SCRIPT_NAME v$VERSION${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTION]

OPTIONS:
    --add       Add 5G testbed iptables rules
    --remove    Remove 5G testbed rules and restore defaults
    --status    Show current iptables status
    --help      Show this help message

EXAMPLES:
    $0 --add       # Setup 5G testbed firewall rules
    $0 --remove    # Clean up and restore original rules
    $0 --status    # Check current firewall status
EOF
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "Creating backup directory: $BACKUP_DIR"
        sudo mkdir -p "$BACKUP_DIR"
    fi
}

# Backup current iptables rules
backup_iptables() {
    log_info "Backing up current iptables rules to: $BACKUP_FILE"
    create_backup_dir
    
    echo "# Iptables backup created on $(date)" | sudo tee "$BACKUP_FILE" > /dev/null
    echo "# Filter table" | sudo tee -a "$BACKUP_FILE" > /dev/null
    sudo iptables-save | sudo tee -a "$BACKUP_FILE" > /dev/null
    
    log_info "Backup completed successfully"
}

# Get default internet interface
get_internet_interface() {
    local iface
    iface=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [[ -z "$iface" ]]; then
        log_error "Could not determine default internet interface"
        exit 1
    fi
    
    echo "$iface"
}

# Check if interface exists
interface_exists() {
    local interface=$1
    if ip link show "$interface" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Add 5G testbed iptables rules
add_rules() {
    print_header
    log_info "Setting up iptables for 5G Network Slicing testbed..."
    
    # Backup current rules
    backup_iptables
    
    # Enable IP forwarding using sysctl
    log_info "Enabling IPv4 forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=1
    
    # Make IP forwarding persistent
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        log_info "Making IPv4 forwarding persistent..."
        echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf > /dev/null
    fi
    
    # Get internet interface
    local inet_iface
    inet_iface=$(get_internet_interface)
    log_info "Using internet interface: $inet_iface"
    
    log_info "Adding INPUT rules for TUN interfaces..."
    # Accept traffic from all TUN interfaces
    for i in "${!TUN_INTERFACES[@]}"; do
        local interface="${TUN_INTERFACES[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        if interface_exists "$interface"; then
            log_debug "Adding INPUT rule for $interface ($slice_name)"
            sudo iptables -I INPUT -i "$interface" -j ACCEPT
        else
            log_warn "Interface $interface does not exist yet, rule will be added anyway"
            sudo iptables -I INPUT -i "$interface" -j ACCEPT
        fi
    done
    
    log_info "Adding FORWARD rules for TUN interfaces..."
    # Allow forwarding from and to TUN interfaces
    for i in "${!TUN_INTERFACES[@]}"; do
        local interface="${TUN_INTERFACES[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        log_debug "Adding FORWARD rules for $interface ($slice_name)"
        sudo iptables -I FORWARD -i "$interface" -j ACCEPT
        sudo iptables -I FORWARD -o "$interface" -j ACCEPT
    done
    
    log_info "Adding NAT rules for internet access..."
    # NAT rules for internet access
    for i in "${!SUBNETS[@]}"; do
        local subnet="${SUBNETS[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        log_debug "Adding NAT rule for subnet $subnet ($slice_name)"
        sudo iptables -t nat -A POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE
    done
    
    # Optional: Add slice isolation rules (commented out by default)
    log_info "Slice isolation rules available but not applied (see script for details)"
    log_info "To enable slice isolation, uncomment the relevant section in add_slice_isolation()"
    
    log_info "${GREEN}5G testbed iptables rules added successfully!${NC}"
    
    # Show summary
    show_summary
}

# Add network slice isolation rules (optional)
add_slice_isolation() {
    log_info "Adding network slice isolation rules..."
    
    # Block inter-slice communication
    # Uncomment these lines if you want complete slice isolation
    
    # eMBB ↔ URLLC isolation
    # sudo iptables -I FORWARD -s 10.45.0.0/24 -d 10.45.1.0/24 -j DROP
    # sudo iptables -I FORWARD -s 10.45.1.0/24 -d 10.45.0.0/24 -j DROP
    
    # eMBB ↔ mMTC isolation  
    # sudo iptables -I FORWARD -s 10.45.0.0/24 -d 10.45.2.0/24 -j DROP
    # sudo iptables -I FORWARD -s 10.45.2.0/24 -d 10.45.0.0/24 -j DROP
    
    # URLLC ↔ mMTC isolation
    # sudo iptables -I FORWARD -s 10.45.1.0/24 -d 10.45.2.0/24 -j DROP
    # sudo iptables -I FORWARD -s 10.45.2.0/24 -d 10.45.1.0/24 -j DROP
    
    log_debug "Slice isolation rules are commented out - enable manually if needed"
}

# Remove 5G testbed specific rules
remove_rules() {
    print_header
    log_info "Removing 5G testbed iptables rules..."
    
    # Remove INPUT rules for TUN interfaces
    log_info "Removing INPUT rules..."
    for interface in "${TUN_INTERFACES[@]}"; do
        log_debug "Removing INPUT rules for $interface"
        while sudo iptables -C INPUT -i "$interface" -j ACCEPT 2>/dev/null; do
            sudo iptables -D INPUT -i "$interface" -j ACCEPT
        done
    done
    
    # Remove FORWARD rules for TUN interfaces  
    log_info "Removing FORWARD rules..."
    for interface in "${TUN_INTERFACES[@]}"; do
        log_debug "Removing FORWARD rules for $interface"
        # Remove inbound FORWARD rules
        while sudo iptables -C FORWARD -i "$interface" -j ACCEPT 2>/dev/null; do
            sudo iptables -D FORWARD -i "$interface" -j ACCEPT
        done
        # Remove outbound FORWARD rules
        while sudo iptables -C FORWARD -o "$interface" -j ACCEPT 2>/dev/null; do
            sudo iptables -D FORWARD -o "$interface" -j ACCEPT
        done
    done
    
    # Remove NAT rules
    log_info "Removing NAT rules..."
    local inet_iface
    inet_iface=$(get_internet_interface)
    
    for subnet in "${SUBNETS[@]}"; do
        log_debug "Removing NAT rules for subnet $subnet"
        while sudo iptables -t nat -C POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE 2>/dev/null; do
            sudo iptables -t nat -D POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE
        done
    done
    
    # Remove slice isolation rules if they exist
    remove_slice_isolation
    
    log_info "${GREEN}5G testbed iptables rules removed successfully!${NC}"
    
    # Show current status
    show_status
}

# Remove slice isolation rules
remove_slice_isolation() {
    log_debug "Removing any slice isolation rules..."
    
    # Remove all possible slice isolation rules
    local subnets_arr=("10.45.0.0/24" "10.45.1.0/24" "10.45.2.0/24")
    
    for src_subnet in "${subnets_arr[@]}"; do
        for dst_subnet in "${subnets_arr[@]}"; do
            if [[ "$src_subnet" != "$dst_subnet" ]]; then
                while sudo iptables -C FORWARD -s "$src_subnet" -d "$dst_subnet" -j DROP 2>/dev/null; do
                    sudo iptables -D FORWARD -s "$src_subnet" -d "$dst_subnet" -j DROP
                done
            fi
        done
    done
}

# Show current iptables status
show_status() {
    print_header
    log_info "Current iptables status for 5G testbed:"
    
    echo -e "\n${BLUE}=== FILTER TABLE - INPUT CHAIN ===${NC}"
    sudo iptables -L INPUT -n -v --line-numbers | grep -E "(ogstun|Chain|target)" || echo "No 5G testbed rules found in INPUT chain"
    
    echo -e "\n${BLUE}=== FILTER TABLE - FORWARD CHAIN ===${NC}"
    sudo iptables -L FORWARD -n -v --line-numbers | grep -E "(ogstun|Chain|target)" || echo "No 5G testbed rules found in FORWARD chain"
    
    echo -e "\n${BLUE}=== NAT TABLE - POSTROUTING CHAIN ===${NC}"
    sudo iptables -t nat -L POSTROUTING -n -v --line-numbers | grep -E "(10\.45\.|Chain|target)" || echo "No 5G testbed rules found in NAT table"
    
    echo -e "\n${BLUE}=== IP FORWARDING STATUS ===${NC}"
    if [[ $(sysctl net.ipv4.ip_forward | cut -d= -f2 | tr -d ' ') == "1" ]]; then
        echo -e "${GREEN}IP forwarding: ENABLED${NC}"
    else
        echo -e "${RED}IP forwarding: DISABLED${NC}"
    fi
    
    echo -e "\n${BLUE}=== TUN INTERFACE STATUS ===${NC}"
    for i in "${!TUN_INTERFACES[@]}"; do
        local interface="${TUN_INTERFACES[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        if interface_exists "$interface"; then
            local ip_addr
            ip_addr=$(ip addr show "$interface" | grep -oP 'inet \K[^/]+' || echo "No IP assigned")
            echo -e "${GREEN}$interface ($slice_name): UP - IP: $ip_addr${NC}"
        else
            echo -e "${YELLOW}$interface ($slice_name): DOWN/NOT EXISTS${NC}"
        fi
    done
}

# Show configuration summary
show_summary() {
    echo -e "\n${PURPLE}=== 5G TESTBED CONFIGURATION SUMMARY ===${NC}"
    echo -e "${BLUE}Network Slices:${NC}"
    
    for i in "${!TUN_INTERFACES[@]}"; do
        local interface="${TUN_INTERFACES[$i]}"
        local subnet="${SUBNETS[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        echo -e "  ${GREEN}$slice_name:${NC} $subnet → $interface"
    done
    
    echo -e "\n${BLUE}Internet Interface:${NC} $(get_internet_interface)"
    echo -e "${BLUE}IP Forwarding:${NC} $(sysctl net.ipv4.ip_forward | cut -d= -f2 | tr -d ' ')"
    echo -e "${BLUE}Backup Location:${NC} $BACKUP_DIR"
}

# List available backups
list_backups() {
    log_info "Available iptables backups:"
    if [[ -d "$BACKUP_DIR" ]]; then
        ls -la "$BACKUP_DIR"/*.rules 2>/dev/null || log_warn "No backups found"
    else
        log_warn "Backup directory does not exist"
    fi
}

# Restore from specific backup
restore_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log_info "Restoring iptables from backup: $backup_file"
    log_warn "This will replace ALL current iptables rules!"
    
    read -p "Are you sure you want to continue? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo iptables-restore < "$backup_file"
        log_info "Iptables restored successfully"
    else
        log_info "Restore cancelled"
    fi
}

# Main function
main() {
    case "${1:-}" in
        --add)
            add_rules
            ;;
        --remove)
            remove_rules
            ;;
        --status)
            show_status
            ;;
        --list-backups)
            list_backups
            ;;
        --restore)
            if [[ -z "$2" ]]; then
                log_error "Backup file path required for --restore"
                print_usage
                exit 1
            fi
            restore_backup "$2"
            ;;
        --help|help|-h)
            print_usage
            ;;
        *)
            log_error "Invalid or missing option"
            print_usage
            exit 1
            ;;
    esac
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]] && [[ -z "$SUDO_USER" ]]; then
    log_error "This script requires sudo privileges"
    exit 1
fi

# Run main function with all arguments
main "$@"
