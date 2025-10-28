#!/bin/bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Open5GS Calico Static IP Verification${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found${NC}"
    exit 1
fi

# Check if Calico is installed
echo -e "${YELLOW}Checking Calico installation...${NC}"
CALICO_NODES=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | wc -l)
if [ "$CALICO_NODES" -gt 0 ]; then
    echo -e "${GREEN}✓ Calico is installed ($CALICO_NODES node(s))${NC}"
else
    echo -e "${RED}✗ Calico not found${NC}"
    echo -e "${YELLOW}  Install with: kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml${NC}"
fi

# Check for Open5GS namespace
echo ""
echo -e "${YELLOW}Checking Open5GS namespace...${NC}"
if kubectl get namespace open5gs &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'open5gs' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'open5gs' not found${NC}"
fi

# Check IPPool
echo ""
echo -e "${YELLOW}Checking Calico IPPool...${NC}"
if kubectl get ippool open5gs-pool &>/dev/null 2>&1; then
    CIDR=$(kubectl get ippool open5gs-pool -o jsonpath='{.spec.cidr}')
    echo -e "${GREEN}✓ IPPool 'open5gs-pool' exists${NC}"
    echo -e "  CIDR: ${BLUE}$CIDR${NC}"
else
    echo -e "${RED}✗ IPPool 'open5gs-pool' not found${NC}"
    echo -e "${YELLOW}  Deploy with: kubectl apply -f 00-foundation/calico-ippool.yaml${NC}"
fi

# Check pods and their IPs
echo ""
echo -e "${YELLOW}Checking pod static IP assignments...${NC}"

declare -A EXPECTED_IPS=(
    ["nrf-0"]="10.10.0.10"
    ["scp-0"]="10.10.0.200"
    ["udr-0"]="10.10.0.20"
    ["udm-0"]="10.10.0.12"
    ["ausf-0"]="10.10.0.11"
    ["pcf-0"]="10.10.0.13"
    ["nssf-0"]="10.10.0.14"
    ["amf-0"]="10.10.0.5"
    ["smf-0"]="10.10.0.4"
    ["upf-0"]="10.10.0.7"
)

ALL_OK=true

for POD in "${!EXPECTED_IPS[@]}"; do
    EXPECTED_IP="${EXPECTED_IPS[$POD]}"
    
    if kubectl get pod "$POD" -n open5gs &>/dev/null; then
        ACTUAL_IP=$(kubectl get pod "$POD" -n open5gs -o jsonpath='{.status.podIP}' 2>/dev/null)
        STATUS=$(kubectl get pod "$POD" -n open5gs -o jsonpath='{.status.phase}' 2>/dev/null)
        
        if [ "$ACTUAL_IP" == "$EXPECTED_IP" ]; then
            if [ "$STATUS" == "Running" ]; then
                echo -e "${GREEN}✓ $POD${NC}: $ACTUAL_IP (Running)"
            else
                echo -e "${YELLOW}⚠ $POD${NC}: $ACTUAL_IP ($STATUS)"
                ALL_OK=false
            fi
        elif [ -z "$ACTUAL_IP" ]; then
            echo -e "${YELLOW}⚠ $POD${NC}: No IP assigned yet ($STATUS)"
            ALL_OK=false
        else
            echo -e "${RED}✗ $POD${NC}: Expected $EXPECTED_IP, got $ACTUAL_IP"
            ALL_OK=false
        fi
    else
        echo -e "${RED}✗ $POD${NC}: Pod not found"
        ALL_OK=false
    fi
done

# Check ConfigMaps
echo ""
echo -e "${YELLOW}Checking ConfigMaps...${NC}"
CONFIGMAPS=("amf-config" "ausf-config" "nrf-config" "nssf-config" "pcf-config" "scp-config" "smf-config" "udm-config" "udr-config" "upf-config")
CM_COUNT=0
for CM in "${CONFIGMAPS[@]}"; do
    if kubectl get configmap "$CM" -n open5gs &>/dev/null; then
        ((CM_COUNT++))
    fi
done

if [ $CM_COUNT -eq ${#CONFIGMAPS[@]} ]; then
    echo -e "${GREEN}✓ All $CM_COUNT ConfigMaps present${NC}"
else
    echo -e "${YELLOW}⚠ Only $CM_COUNT/${#CONFIGMAPS[@]} ConfigMaps found${NC}"
fi

# Check static IP references in configs
echo ""
echo -e "${YELLOW}Verifying static IP usage in configs...${NC}"
if kubectl get configmap nrf-config -n open5gs &>/dev/null; then
    if kubectl get configmap nrf-config -n open5gs -o yaml | grep -q "10.10.0.10"; then
        echo -e "${GREEN}✓ NRF config uses static IP (10.10.0.10)${NC}"
    else
        echo -e "${RED}✗ NRF config doesn't use static IP${NC}"
    fi
fi

if kubectl get configmap amf-config -n open5gs &>/dev/null; then
    if kubectl get configmap amf-config -n open5gs -o yaml | grep -q "10.10.0.5"; then
        echo -e "${GREEN}✓ AMF config uses static IP (10.10.0.5)${NC}"
    else
        echo -e "${RED}✗ AMF config doesn't use static IP${NC}"
    fi
fi

# Test connectivity (if pods are running)
echo ""
echo -e "${YELLOW}Testing pod connectivity...${NC}"
if kubectl get pod nrf-0 -n open5gs &>/dev/null && kubectl get pod scp-0 -n open5gs &>/dev/null; then
    NRF_STATUS=$(kubectl get pod nrf-0 -n open5gs -o jsonpath='{.status.phase}')
    SCP_STATUS=$(kubectl get pod scp-0 -n open5gs -o jsonpath='{.status.phase}')
    
    if [ "$NRF_STATUS" == "Running" ] && [ "$SCP_STATUS" == "Running" ]; then
        if kubectl exec -n open5gs scp-0 -- ping -c 2 -W 2 10.10.0.10 &>/dev/null; then
            echo -e "${GREEN}✓ SCP can ping NRF (10.10.0.10)${NC}"
        else
            echo -e "${RED}✗ SCP cannot ping NRF${NC}"
            ALL_OK=false
        fi
        
        # Test HTTP connectivity
        if kubectl exec -n open5gs scp-0 -- timeout 5 curl -s http://10.10.0.10:7777 &>/dev/null; then
            echo -e "${GREEN}✓ SCP can reach NRF HTTP (10.10.0.10:7777)${NC}"
        else
            echo -e "${YELLOW}⚠ SCP cannot reach NRF HTTP (may not be ready)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Pods not ready for connectivity tests${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Required pods not deployed yet${NC}"
fi

# Check NF registrations (if NRF is running)
echo ""
echo -e "${YELLOW}Checking NF registrations...${NC}"
if kubectl get pod nrf-0 -n open5gs &>/dev/null; then
    NRF_STATUS=$(kubectl get pod nrf-0 -n open5gs -o jsonpath='{.status.phase}')
    if [ "$NRF_STATUS" == "Running" ]; then
        REGISTRATIONS=$(kubectl logs -n open5gs nrf-0 2>/dev/null | grep -c "NF registered" || echo "0")
        if [ "$REGISTRATIONS" -gt 0 ]; then
            echo -e "${GREEN}✓ $REGISTRATIONS NF(s) registered with NRF${NC}"
        else
            echo -e "${YELLOW}⚠ No NF registrations found yet${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ NRF pod not running${NC}"
    fi
else
    echo -e "${YELLOW}⚠ NRF pod not deployed${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}================================================${NC}"
if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo -e "${GREEN}  Static IP deployment is ready${NC}"
else
    echo -e "${YELLOW}⚠ Some issues found${NC}"
    echo -e "${YELLOW}  Review the output above${NC}"
fi
echo -e "${BLUE}================================================${NC}"

# Provide useful commands
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  View all pods:     ${YELLOW}kubectl get pods -n open5gs -o wide${NC}"
echo -e "  Check NRF logs:    ${YELLOW}kubectl logs -n open5gs nrf-0${NC}"
echo -e "  Test NRF API:      ${YELLOW}kubectl exec -n open5gs nrf-0 -- curl http://10.10.0.10:7777/nnrf-nfm/v1/nf-instances${NC}"
echo -e "  View IPPool:       ${YELLOW}kubectl get ippool open5gs-pool -o yaml${NC}"
echo ""
