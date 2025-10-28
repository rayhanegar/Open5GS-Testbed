#!/bin/bash
# Complete cleanup and redeployment of Open5GS
# Removes all NFs (control plane, session management, user plane) and redeploys using deploy-k3s.sh

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

# All NF components
CONTROL_PLANE_NFS="nrf scp udr udm ausf pcf nssf"
SESSION_MGMT_NFS="amf smf"
USER_PLANE_NFS="upf"

print_info "=== Open5GS Complete Cleanup and Redeployment ==="
echo ""

# Confirm with user
read -p "This will delete all Open5GS pods and redeploy. Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warn "Redeployment cancelled."
    exit 0
fi

print_info "Step 1: Cleaning up existing deployments..."
echo ""

# Delete Control Plane NFs
print_info "Removing Control Plane NFs..."
for nf in $CONTROL_PLANE_NFS; do
    echo "  - Deleting StatefulSet: $nf"
    kubectl delete statefulset $nf -n open5gs --ignore-not-found=true
done

# Delete Session Management NFs
print_info "Removing Session Management NFs..."
for nf in $SESSION_MGMT_NFS; do
    echo "  - Deleting Deployment: $nf"
    kubectl delete deployment $nf -n open5gs --ignore-not-found=true
done

# Delete User Plane NFs
print_info "Removing User Plane NFs..."
for nf in $USER_PLANE_NFS; do
    echo "  - Deleting DaemonSet: $nf"
    kubectl delete daemonset $nf -n open5gs --ignore-not-found=true
done

print_info "Waiting for pods to terminate..."
sleep 10

# Verify all pods are gone
REMAINING_PODS=$(kubectl get pods -n open5gs --no-headers 2>/dev/null | wc -l)
if [ "$REMAINING_PODS" -gt 0 ]; then
    print_warn "$REMAINING_PODS pods still terminating, waiting..."
    kubectl get pods -n open5gs
    sleep 10
fi

print_success "Cleanup complete!"
echo ""

# Redeploy using deploy-k3s.sh
print_info "Step 2: Redeploying Open5GS using deploy-k3s.sh..."
echo ""

if [ ! -f "./deploy-k3s.sh" ]; then
    print_error "deploy-k3s.sh not found in current directory!"
    exit 1
fi

# Execute deployment script
./deploy-k3s.sh

print_success "=== Redeployment Complete ==="
echo ""
print_info "Final pod status:"
kubectl get pods -n open5gs
