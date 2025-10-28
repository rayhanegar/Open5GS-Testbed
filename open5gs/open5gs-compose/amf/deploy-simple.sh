#!/bin/bash

# Simple Open5GS AMF Deployment Script
# Uses direct binary execution with mounted config

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Simple Open5GS AMF Deployment ===${NC}"

# Check if config file exists
check_config() {
    if [ ! -f "./amf.yaml" ]; then
        echo -e "${RED}Error: amf.yaml not found${NC}"
        echo -e "${YELLOW}Please ensure the configuration file exists in the current directory${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Configuration file found: amf-vm.yaml${NC}"
}

# Get host IP address
get_host_ip() {
    HOST_IP=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
    if [ -z "$HOST_IP" ]; then
        HOST_IP="localhost"
    fi
    echo -e "${GREEN}Host IP: $HOST_IP${NC}"
}

# Deploy AMF
deploy_amf() {
    echo -e "${GREEN}Building and starting AMF container (simplified)...${NC}"
    
    # Go to main containers directory
    cd ../
    
    # Stop existing containers
    echo -e "${YELLOW}Stopping existing containers...${NC}"
    docker-compose down amf || true
    
    # Build and start AMF
    echo -e "${GREEN}Building AMF image...${NC}"
    docker-compose build amf
    
    echo -e "${GREEN}Starting AMF container...${NC}"
    docker-compose up -d amf
    
    echo -e "${GREEN}Waiting for AMF to start...${NC}"
    sleep 5
    
    # Check if container is running
    if docker ps | grep -q open5gs-amf; then
        echo -e "${GREEN}✓ AMF container is running${NC}"
    else
        echo -e "${RED}✗ AMF container failed to start${NC}"
        echo -e "${YELLOW}Checking logs:${NC}"
        docker-compose logs amf
        exit 1
    fi
    
    # Go back to amf directory
    cd amf/
}

# Verify deployment
verify_deployment() {
    echo -e "${GREEN}=== Deployment Verification ===${NC}"
    
    # Check container status
    echo -e "${YELLOW}Container status:${NC}"
    docker ps | grep open5gs-amf || echo -e "${RED}Container not found${NC}"
    
    # Check if ports are listening
    echo -e "${YELLOW}Port status:${NC}"
    if netstat -tuln | grep -q ":38412 "; then
        echo -e "${GREEN}✓ NGAP port 38412 is listening${NC}"
    else
        echo -e "${YELLOW}⚠ NGAP port 38412 may not be bound${NC}"
    fi
    
    if netstat -tuln | grep -q ":7705 "; then
        echo -e "${GREEN}✓ SBI port 7705 is listening${NC}"
    else
        echo -e "${YELLOW}⚠ SBI port 7705 may not be bound${NC}"
    fi
    
    # Show recent logs
    echo -e "${YELLOW}Recent AMF logs:${NC}"
    docker logs open5gs-amf --tail=20
}

# Show connection info
show_info() {
    get_host_ip
    echo
    echo -e "${GREEN}=== Connection Information ===${NC}"
    echo -e "${GREEN}AMF is accessible at:${NC}"
    echo -e "${YELLOW}  NGAP: $HOST_IP:38412 (SCTP)${NC}"
    echo -e "${YELLOW}  SBI:  http://$HOST_IP:7705${NC}"
    echo -e "${YELLOW}  Metrics: http://$HOST_IP:9005/metrics${NC}"
    echo
    echo -e "${GREEN}For UERANSIM gNB configuration:${NC}"
    echo -e "${BLUE}  amfConfigs:${NC}"
    echo -e "${BLUE}    - address: $HOST_IP${NC}"
    echo -e "${BLUE}      port: 38412${NC}"
    echo
    echo -e "${YELLOW}Useful commands:${NC}"
    echo -e "${YELLOW}  View logs: docker logs open5gs-amf -f${NC}"
    echo -e "${YELLOW}  Stop AMF:  docker-compose -f ../docker-compose.yml stop amf${NC}"
    echo -e "${YELLOW}  Restart:   docker-compose -f ../docker-compose.yml restart amf${NC}"
}

# Main execution
main() {
    check_config
    deploy_amf
    verify_deployment
    show_info
}

# Handle command line arguments
case "${1:-deploy}" in
    deploy)
        main
        ;;
    stop)
        echo -e "${GREEN}Stopping AMF container...${NC}"
        cd ../
        docker-compose stop amf
        cd amf/
        ;;
    logs)
        docker logs open5gs-amf -f
        ;;
    status)
        docker ps | grep open5gs-amf || echo -e "${RED}AMF container not running${NC}"
        ;;
    info)
        show_info
        ;;
    *)
        echo "Usage: $0 {deploy|stop|logs|status|info}"
        echo "  deploy - Build and deploy AMF (default)"
        echo "  stop   - Stop AMF container"
        echo "  logs   - Show AMF logs"
        echo "  status - Show container status"
        echo "  info   - Show connection information"
        exit 1
        ;;
esac