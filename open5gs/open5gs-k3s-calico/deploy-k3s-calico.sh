#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Get timestamp in milliseconds
get_timestamp_ms() {
    echo $(($(date +%s%N)/1000000))
}

# Calculate duration in ms
calc_duration() {
    local start=$1
    local end=$2
    echo $((end - start))
}

# Verify kubectl works
if ! kubectl get nodes &>/dev/null; then
    print_error "kubectl not configured properly"
    exit 1
fi

# Create deployment summary directory
SUMMARY_DIR="$(pwd)/deployment-summary"
mkdir -p "$SUMMARY_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SUMMARY_FILE="$SUMMARY_DIR/deployment_${TIMESTAMP}.txt"

print_info "Starting Open5GS deployment..."
DEPLOYMENT_START=$(get_timestamp_ms)

# =============================================================================
# STOP BARE-METAL OPEN5GS SERVICES
# =============================================================================
print_info "Stopping bare-metal Open5GS services..."
STOP_SERVICES_START=$(get_timestamp_ms)

# Get list of open5gs services (exclude webui)
OPEN5GS_SERVICES=$(systemctl list-units --type=service --state=running | grep "open5gs-" | grep -v "open5gs-webui" | awk '{print $1}')

if [ -n "$OPEN5GS_SERVICES" ]; then
    print_info "Found running Open5GS services to stop:"
    echo "$OPEN5GS_SERVICES" | while read service; do
        echo "  - $service"
    done
    
    # Stop all Open5GS services except webui
    echo "$OPEN5GS_SERVICES" | while read service; do
        print_info "Stopping $service..."
        systemctl stop "$service" || print_warn "Failed to stop $service"
    done
    
    print_success "Bare-metal Open5GS services stopped"
else
    print_info "No running bare-metal Open5GS services found"
fi

STOP_SERVICES_END=$(get_timestamp_ms)
STOP_SERVICES_DURATION=$(calc_duration $STOP_SERVICES_START $STOP_SERVICES_END)

# =============================================================================
# CLEANUP PHASE
# =============================================================================
print_info "Cleaning up previous deployment..."
CLEANUP_START=$(get_timestamp_ms)

# Delete namespace and all resources
if kubectl get namespace open5gs &>/dev/null; then
    print_info "Deleting existing namespace..."
    kubectl delete namespace open5gs --timeout=60s || true
    # Wait for complete deletion
    while kubectl get namespace open5gs &>/dev/null 2>&1; do
        sleep 1
    done
    print_success "Namespace deleted"
fi

# Clean up host logs
print_info "Cleaning host logs..."
if [ -d "/mnt/data/open5gs-logs" ]; then
  rm -rf /mnt/data/open5gs-logs/*
  print_success "Host logs cleaned"
else
  print_info "Log directory does not exist, skipping cleanup"
fi

CLEANUP_END=$(get_timestamp_ms)
CLEANUP_DURATION=$(calc_duration $CLEANUP_START $CLEANUP_END)
print_success "Cleanup completed in ${CLEANUP_DURATION}ms"

# =============================================================================
# FOUNDATION PHASE
# =============================================================================
print_info "Setting up foundation..."
FOUNDATION_START=$(get_timestamp_ms)

# Step 1: Create namespace
kubectl apply -f 00-foundation/namespace.yaml
sleep 2

# Verify namespace exists
if ! kubectl get namespace open5gs &>/dev/null; then
    print_error "Failed to create namespace"
    exit 1
fi
print_success "Namespace created"

# Apply foundation resources
kubectl apply -f 00-foundation/mongod-external.yaml
sleep 2

# Apply Calico IPPool for static IPs
print_info "Configuring Calico IPPool for static IPs..."
kubectl apply -f 00-foundation/calico-ippool.yaml
sleep 3
print_success "Calico IPPool configured (10.10.0.0/24)"

# Create log directory on host
print_info "Creating log directory on host..."
mkdir -p /mnt/data/open5gs-logs
chmod 777 /mnt/data/open5gs-logs
print_success "Log directory ready"

FOUNDATION_END=$(get_timestamp_ms)
FOUNDATION_DURATION=$(calc_duration $FOUNDATION_START $FOUNDATION_END)
print_success "Foundation setup completed in ${FOUNDATION_DURATION}ms"

# =============================================================================
# CONFIGMAPS PHASE
# =============================================================================
print_info "Creating ConfigMaps..."
CONFIGMAP_START=$(get_timestamp_ms)
kubectl apply -f 01-configmaps/
sleep 5
CONFIGMAP_END=$(get_timestamp_ms)
CONFIGMAP_DURATION=$(calc_duration $CONFIGMAP_START $CONFIGMAP_END)
print_success "ConfigMaps created in ${CONFIGMAP_DURATION}ms"

# =============================================================================
# PARALLEL DEPLOYMENT PHASE
# =============================================================================
print_info "Deploying Network Functions in parallel..."
PARALLEL_START=$(get_timestamp_ms)

# Declare associative arrays for tracking
declare -A POD_DEPLOY_START
declare -A POD_DEPLOY_END
declare -A POD_READY_TIME

# Helper function to deploy a pod and track timing
deploy_pod() {
    local name=$1
    local file=$2
    local label=$3
    
    POD_DEPLOY_START[$name]=$(get_timestamp_ms)
    print_info "Deploying $name..."
    
    kubectl apply -f "$file" &>/dev/null
    
    # Wait for pod to be ready (increased timeout for image pull)
    if kubectl wait --for=condition=ready pod -l "$label" -n open5gs --timeout=180s &>/dev/null; then
        POD_DEPLOY_END[$name]=$(get_timestamp_ms)
        POD_READY_TIME[$name]=$(calc_duration ${POD_DEPLOY_START[$name]} ${POD_DEPLOY_END[$name]})
        print_success "$name ready in ${POD_READY_TIME[$name]}ms"
        return 0
    else
        POD_DEPLOY_END[$name]=$(get_timestamp_ms)
        POD_READY_TIME[$name]=$(calc_duration ${POD_DEPLOY_START[$name]} ${POD_DEPLOY_END[$name]})
        print_error "$name failed to start after ${POD_READY_TIME[$name]}ms"
        return 1
    fi
}

# Deploy NRF first (required by others)
deploy_pod "nrf" "02-control-plane/nrf.yaml" "app=nrf"
if [ $? -ne 0 ]; then
    print_error "NRF deployment failed, cannot continue"
    kubectl logs -l app=nrf -n open5gs --tail=50
    exit 1
fi

# Deploy SCP (required for service discovery)
deploy_pod "scp" "02-control-plane/scp.yaml" "app=scp"
if [ $? -ne 0 ]; then
    print_error "SCP deployment failed, cannot continue"
    kubectl logs -l app=scp -n open5gs --tail=50
    exit 1
fi

# Deploy remaining NFs in parallel
print_info "Deploying remaining NFs in parallel..."

# Launch all deployments in background
deploy_pod "udr" "02-control-plane/udr.yaml" "app=udr" &
deploy_pod "udm" "02-control-plane/udm.yaml" "app=udm" &
deploy_pod "ausf" "02-control-plane/ausf.yaml" "app=ausf" &
deploy_pod "pcf" "02-control-plane/pcf.yaml" "app=pcf" &
deploy_pod "nssf" "02-control-plane/nssf.yaml" "app=nssf" &
deploy_pod "amf" "03-session-mgmt/amf.yaml" "app=amf" &
deploy_pod "upf" "04-user-plane/upf.yaml" "app=upf" &
deploy_pod "smf" "03-session-mgmt/smf.yaml" "app=smf" &

# Wait for all background jobs to complete
wait

PARALLEL_END=$(get_timestamp_ms)
PARALLEL_DURATION=$(calc_duration $PARALLEL_START $PARALLEL_END)
print_success "All NFs deployed in ${PARALLEL_DURATION}ms"

# =============================================================================
# NRF/SCP METRICS COLLECTION
# =============================================================================
print_info "Collecting NRF/SCP metrics..."
METRICS_START=$(get_timestamp_ms)

# Give services a moment to register
sleep 5

# Query NRF for registered NFs
print_info "Querying NRF for registered NFs..."
NRF_POD=$(kubectl get pods -n open5gs -l app=nrf -o jsonpath='{.items[0].metadata.name}')
if [ -n "$NRF_POD" ]; then
    NRF_REGISTERED=$(kubectl exec -n open5gs "$NRF_POD" -- sh -c "curl -s http://localhost:7777/nnrf-nfm/v1/nf-instances 2>/dev/null | grep -o '\"nfInstanceId\"' | wc -l" 2>/dev/null || echo "0")
else
    NRF_REGISTERED="N/A"
fi

# Query SCP logs for routing info
SCP_POD=$(kubectl get pods -n open5gs -l app=scp -o jsonpath='{.items[0].metadata.name}')
if [ -n "$SCP_POD" ]; then
    SCP_ROUTES=$(kubectl logs -n open5gs "$SCP_POD" 2>/dev/null | grep -c "NF registered" || echo "0")
else
    SCP_ROUTES="N/A"
fi

METRICS_END=$(get_timestamp_ms)
METRICS_DURATION=$(calc_duration $METRICS_START $METRICS_END)

# =============================================================================
# GENERATE DEPLOYMENT SUMMARY
# =============================================================================
DEPLOYMENT_END=$(get_timestamp_ms)
TOTAL_DURATION=$(calc_duration $DEPLOYMENT_START $DEPLOYMENT_END)

print_info "Generating deployment summary..."

cat > "$SUMMARY_FILE" << EOF
================================================================================
Open5GS Deployment Summary
================================================================================
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
Deployment ID: ${TIMESTAMP}

================================================================================
OVERALL TIMING
================================================================================
Total Deployment Time: ${TOTAL_DURATION}ms ($(echo "scale=2; $TOTAL_DURATION/1000" | bc)s)

Phase Breakdown:
  - Stop Services:     ${STOP_SERVICES_DURATION}ms
  - Cleanup:           ${CLEANUP_DURATION}ms
  - Foundation:        ${FOUNDATION_DURATION}ms
  - ConfigMaps:        ${CONFIGMAP_DURATION}ms
  - Parallel Deploy:   ${PARALLEL_DURATION}ms
  - Metrics Collection: ${METRICS_DURATION}ms

================================================================================
PER-POD DEPLOYMENT TIME (ms)
================================================================================
EOF

# Sort pods by deployment time
for pod in "${!POD_READY_TIME[@]}"; do
    printf "%-15s %10d ms\n" "$pod:" "${POD_READY_TIME[$pod]}" >> "$SUMMARY_FILE"
done | sort -k2 -n >> "$SUMMARY_FILE"

cat >> "$SUMMARY_FILE" << EOF

================================================================================
NRF/SCP METRICS
================================================================================
NRF Registered NFs:   ${NRF_REGISTERED}
SCP Registration Events: ${SCP_ROUTES}

================================================================================
DEPLOYED RESOURCES
================================================================================
EOF

# Get pod status
kubectl get pods -n open5gs -o wide >> "$SUMMARY_FILE"

cat >> "$SUMMARY_FILE" << EOF

================================================================================
SERVICES
================================================================================
EOF

kubectl get svc -n open5gs >> "$SUMMARY_FILE"

cat >> "$SUMMARY_FILE" << EOF

================================================================================
NF REGISTRATION DETAILS (from NRF logs)
================================================================================
EOF

if [ -n "$NRF_POD" ]; then
    kubectl logs -n open5gs "$NRF_POD" 2>/dev/null | grep "NF registered" | tail -20 >> "$SUMMARY_FILE" || echo "No registration logs found" >> "$SUMMARY_FILE"
fi

cat >> "$SUMMARY_FILE" << EOF

================================================================================
DEPLOYMENT ENDPOINTS
================================================================================
EOF

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "AMF NGAP Endpoint: ${NODE_IP}:38412" >> "$SUMMARY_FILE"
echo "Configure your gNB to connect to: ${NODE_IP}:38412" >> "$SUMMARY_FILE"

# =============================================================================
# FINAL OUTPUT
# =============================================================================
print_success "========================================="
print_success "Open5GS Deployment Complete!"
print_success "========================================="
echo ""
print_info "Total Deployment Time: ${TOTAL_DURATION}ms ($(echo "scale=2; $TOTAL_DURATION/1000" | bc)s)"
echo ""
print_info "Pod Status:"
kubectl get pods -n open5gs -o wide

echo ""
print_info "Services:"
kubectl get svc -n open5gs

echo ""
print_info "AMF NGAP Endpoint: ${NODE_IP}:38412"
print_info "Configure your gNB to connect to: ${NODE_IP}:38412"

echo ""
print_success "Deployment summary saved to: $SUMMARY_FILE"
echo ""
print_info "Useful commands:"
echo "  View logs: kubectl logs -f <pod-name> -n open5gs"
echo "  Exec into pod: kubectl exec -it <pod-name> -n open5gs -- bash"
echo "  Check UPF TUN: kubectl exec -it upf-0 -n open5gs -- ip addr show"
echo "  View summary: cat $SUMMARY_FILE"