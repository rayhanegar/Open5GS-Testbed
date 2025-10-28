#!/bin/bash

# Open5GS Services Restart Script
# This script restarts all Open5GS related services
# Usage: sudo ./open5gs-restart-services.sh

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_status "Starting Open5GS services restart..."
echo "=========================================="

# Reload systemd daemon to pick up any unit file changes
print_status "Reloading systemd daemon..."
systemctl daemon-reload
print_success "Systemd daemon reloaded"
echo "----------------------------------------"

# List of Open5GS services based on configuration files present
# Core Network Functions
SERVICES=(
    "open5gs-nrfd"      # Network Repository Function
    "open5gs-scpd"      # Service Communication Proxy
    "open5gs-ausfd"     # Authentication Server Function
    "open5gs-udmd"      # Unified Data Management
    "open5gs-udrd"      # Unified Data Repository
    "open5gs-pcfd"      # Policy Control Function
    "open5gs-bsfd"      # Binding Support Function
    "open5gs-nssfd"     # Network Slice Selection Function
    "open5gs-amfd"      # Access and Mobility Management Function
    "open5gs-smfd"      # Session Management Function
    "open5gs-upfd"      # User Plane Function
    "open5gs-sgwcd"     # Serving Gateway Control Plane (4G)
    "open5gs-sgwud"     # Serving Gateway User Plane (4G)
    "open5gs-mmed"      # Mobility Management Entity (4G)
    "open5gs-hssd"      # Home Subscriber Server (4G)
    "open5gs-pcrfd"     # Policy Charging Rules Function (4G)
)

# Optional SEPP services (if configured for roaming)
OPTIONAL_SERVICES=(
    "open5gs-seppd"     # Security Edge Protection Proxy
)

# Counters
success_count=0
failed_count=0
not_found_count=0

# Function to restart a service
restart_service() {
    local service_name=$1
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "^${service_name}.service"; then
        print_warning "Service ${service_name}.service not found - skipping"
        ((not_found_count++))
        return 1
    fi
    
    print_status "Restarting ${service_name}.service..."
    
    # Stop the service first
    systemctl stop "${service_name}.service"
    sleep 1
    
    # Start the service
    if systemctl restart "${service_name}.service"; then
        # Check if service is active
        if systemctl is-active --quiet "${service_name}.service"; then
            print_success "${service_name}.service restarted successfully"
            ((success_count++))
        else
            print_error "${service_name}.service failed to start properly"
            systemctl status "${service_name}.service" --no-pager -l
            ((failed_count++))
        fi
    else
        print_error "Failed to restart ${service_name}.service"
        systemctl status "${service_name}.service" --no-pager -l
        ((failed_count++))
    fi
    
    echo "----------------------------------------"
}

# Restart services in dependency order
print_status "Restarting core services..."

# Start with fundamental services first
restart_service "open5gs-nrfd"
restart_service "open5gs-scpd"

# Authentication and data management
restart_service "open5gs-ausfd"
restart_service "open5gs-udrd"
restart_service "open5gs-udmd"

# Policy and support functions  
restart_service "open5gs-pcfd"
restart_service "open5gs-bsfd"
restart_service "open5gs-nssfd"

# Core network functions
restart_service "open5gs-amfd"
restart_service "open5gs-upfd"
restart_service "open5gs-smfd"

# 4G compatibility services
restart_service "open5gs-sgwcd"
restart_service "open5gs-sgwud"
restart_service "open5gs-mmed"
restart_service "open5gs-hssd"
restart_service "open5gs-pcrfd"

# Optional services
print_status "Checking optional services..."
for service in "${OPTIONAL_SERVICES[@]}"; do
    restart_service "$service"
done

# Summary
echo "=========================================="
print_status "Restart Summary:"
echo "  - Successfully restarted: $success_count services"
echo "  - Failed to restart: $failed_count services"  
echo "  - Not found/skipped: $not_found_count services"
echo "=========================================="

if [ $failed_count -gt 0 ]; then
    print_error "Some services failed to restart. Check logs with: journalctl -u <service-name> -f"
    exit 1
else
    print_success "All available Open5GS services restarted successfully!"
    print_status "You can check service status with: sudo systemctl status open5gs-*"
fi
