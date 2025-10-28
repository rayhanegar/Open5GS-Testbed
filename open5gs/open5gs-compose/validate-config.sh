#!/bin/bash

# Open5GS Container Configuration Validation Script
# This script validates the Open5GS NF container configuration

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================"
echo "Open5GS Container Configuration Validator"
echo "============================================"
echo ""

ISSUES_FOUND=0
WARNINGS_FOUND=0

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2 exists"
        return 0
    else
        echo -e "${RED}✗${NC} $2 missing: $1"
        ((ISSUES_FOUND++))
        return 1
    fi
}

# Function to check directory
check_directory() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $2 directory exists"
        return 0
    else
        echo -e "${YELLOW}!${NC} $2 directory missing: $1 (will be created)"
        ((WARNINGS_FOUND++))
        return 1
    fi
}

# Function to validate YAML syntax
check_yaml() {
    if command -v python3 &> /dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$1'))" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} $2 has valid YAML syntax"
            return 0
        else
            echo -e "${RED}✗${NC} $2 has invalid YAML syntax"
            ((ISSUES_FOUND++))
            return 1
        fi
    else
        echo -e "${YELLOW}!${NC} Cannot validate YAML syntax (python3 not found)"
        ((WARNINGS_FOUND++))
        return 1
    fi
}

# Function to check IP address in config
check_ip_in_config() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $3 contains expected IP: $2"
        return 0
    else
        echo -e "${RED}✗${NC} $3 does not contain expected IP: $2"
        ((ISSUES_FOUND++))
        return 1
    fi
}

echo "1. Checking base directory structure..."
echo "======================================="
check_file "docker-compose.yml" "Docker Compose file"
check_file "mongo-init.js" "MongoDB initialization script"
check_directory "logs" "Logs"

echo ""
echo "2. Checking Network Function directories and configs..."
echo "======================================================="

# Array of NFs to check
declare -a NFS=("amf" "ausf" "nrf" "nssf" "pcf" "scp" "smf" "udm" "udr" "upf")
declare -A NF_IPS=(
    ["amf"]="10.10.0.5"
    ["ausf"]="10.10.0.11"
    ["nrf"]="10.10.0.10"
    ["nssf"]="10.10.0.14"
    ["pcf"]="10.10.0.13"
    ["scp"]="10.10.0.200"
    ["smf"]="10.10.0.4"
    ["udm"]="10.10.0.12"
    ["udr"]="10.10.0.20"
    ["upf"]="10.10.0.7"
)

for nf in "${NFS[@]}"; do
    echo ""
    echo "Checking $nf..."
    check_directory "$nf" "${nf^^}"
    
    if [ -d "$nf" ]; then
        check_file "$nf/Dockerfile" "${nf^^} Dockerfile"
        check_file "$nf/$nf.yaml" "${nf^^} configuration"
        
        if [ -f "$nf/$nf.yaml" ]; then
            check_yaml "$nf/$nf.yaml" "${nf^^} configuration"
            # Check if the correct IP is configured
            if [ "${NF_IPS[$nf]}" != "" ]; then
                check_ip_in_config "$nf/$nf.yaml" "${NF_IPS[$nf]}" "${nf^^} configuration"
            fi
        fi
    fi
done

echo ""
echo "3. Checking Docker and system requirements..."
echo "============================================="

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is installed"
    docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo "  Version: $docker_version"
else
    echo -e "${RED}✗${NC} Docker is not installed"
    ((ISSUES_FOUND++))
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose v1 is installed"
    compose_version=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
    echo "  Version: $compose_version"
elif docker compose version &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose v2 is installed"
    compose_version=$(docker compose version | awk '{print $4}')
    echo "  Version: $compose_version"
else
    echo -e "${RED}✗${NC} Docker Compose is not installed"
    ((ISSUES_FOUND++))
fi

# Check SCTP module
if lsmod | grep -q sctp; then
    echo -e "${GREEN}✓${NC} SCTP kernel module is loaded"
else
    echo -e "${YELLOW}!${NC} SCTP kernel module is not loaded (required for AMF N2 interface)"
    echo "  To load: sudo modprobe sctp"
    ((WARNINGS_FOUND++))
fi

# Check IP forwarding
ipv4_forward=$(cat /proc/sys/net/ipv4/ip_forward)
if [ "$ipv4_forward" = "1" ]; then
    echo -e "${GREEN}✓${NC} IPv4 forwarding is enabled"
else
    echo -e "${YELLOW}!${NC} IPv4 forwarding is disabled"
    echo "  To enable: sudo sysctl -w net.ipv4.ip_forward=1"
    ((WARNINGS_FOUND++))
fi

echo ""
echo "4. Checking specific configuration issues..."
echo "==========================================="

# Check AMF configuration
if [ -f "amf/amf.yaml" ]; then
    # Check if AMF has correct NGAP binding
    if grep -q "address: 10.10.0.5" "amf/amf.yaml" && grep -q "port: 38412" "amf/amf.yaml"; then
        echo -e "${GREEN}✓${NC} AMF NGAP interface correctly configured"
    else
        echo -e "${RED}✗${NC} AMF NGAP interface misconfigured"
        ((ISSUES_FOUND++))
    fi
fi

# Check UPF configuration
if [ -f "upf/upf.yaml" ]; then
    # Check if UPF has correct GTPU binding
    if grep -q "port: 2152" "upf/upf.yaml"; then
        echo -e "${GREEN}✓${NC} UPF GTP-U interface using standard port 2152"
    else
        echo -e "${YELLOW}!${NC} UPF not using standard GTP-U port 2152"
        ((WARNINGS_FOUND++))
    fi
fi

# Check if docker network will conflict
if docker network ls | grep -q "br-5gcore"; then
    echo -e "${YELLOW}!${NC} Docker network br-5gcore already exists"
    echo "  This may cause conflicts. Consider: docker network rm br-5gcore"
    ((WARNINGS_FOUND++))
fi

echo ""
echo "5. Configuration comparison with reference..."
echo "============================================"

# Compare with external context AMF config
if [ -f "amf/amf.yaml" ]; then
    # Check TAC configuration
    if grep -q "tac: 1" "amf/amf.yaml"; then
        echo -e "${GREEN}✓${NC} AMF TAC matches reference configuration (TAC: 1)"
    else
        echo -e "${YELLOW}!${NC} AMF TAC differs from reference (expected: 1)"
        ((WARNINGS_FOUND++))
    fi
    
    # Check PLMN
    if grep -q "mcc: 001" "amf/amf.yaml" && grep -q "mnc: 01" "amf/amf.yaml"; then
        echo -e "${GREEN}✓${NC} AMF PLMN matches reference (001-01)"
    else
        echo -e "${YELLOW}!${NC} AMF PLMN differs from reference (expected: 001-01)"
        ((WARNINGS_FOUND++))
    fi
fi

echo ""
echo "============================================"
echo "Validation Summary:"
echo "============================================"
if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your Open5GS container configuration appears to be correct."
    echo "You can start the containers with: docker compose up -d"
else
    if [ $ISSUES_FOUND -gt 0 ]; then
        echo -e "${RED}✗ Found $ISSUES_FOUND critical issues that must be fixed${NC}"
    fi
    if [ $WARNINGS_FOUND -gt 0 ]; then
        echo -e "${YELLOW}! Found $WARNINGS_FOUND warnings that should be reviewed${NC}"
    fi
    echo ""
    echo "Please fix the issues above before running docker compose up"
fi

echo ""
echo "Next steps:"
echo "1. Run setup script: sudo ./setup-host-network.sh"
echo "2. Start containers: docker compose up -d"
echo "3. Check logs: docker compose logs -f"
echo "============================================"

exit $ISSUES_FOUND