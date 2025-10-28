# Open5GS Kubernetes (K3s) Deployment with Calico

This directory contains a production-ready Kubernetes deployment of Open5GS 5G Core Network using **K3s** (lightweight Kubernetes) and **Calico CNI** for advanced networking features including static IP assignment.

## 🎯 Features

- **K3s Orchestration**: Lightweight Kubernetes optimized for resource efficiency
- **Calico CNI**: Advanced networking with static IP support and network policies
- **Parallel Deployment**: Fast deployment (~60-90 seconds) with intelligent dependency management
- **Static IP Assignment**: Predictable IP addresses for all Network Functions (10.10.0.0/24)
- **Automated Scripts**: Helper scripts for environment setup, deployment, and verification
- **Production Ready**: StatefulSets, persistent storage, health checks, and monitoring
- **3 Network Slices**: eMBB, URLLC, and mMTC support
- **Deployment Metrics**: Detailed timing and registration tracking

## 📋 Architecture Overview

### Network Functions Deployed

| Network Function | StatefulSet | Static IP | Port(s) | Purpose |
|-----------------|-------------|-----------|---------|---------|
| **NRF** (Network Repository Function) | nrf-0 | 10.10.0.10 | 7777 | Service discovery |
| **SCP** (Service Communication Proxy) | scp-0 | 10.10.0.200 | 7777 | SBI routing |
| **UDR** (Unified Data Repository) | udr-0 | 10.10.0.20 | 7777 | Data repository |
| **UDM** (Unified Data Management) | udm-0 | 10.10.0.12 | 7777 | Subscription data |
| **AUSF** (Authentication Server Function) | ausf-0 | 10.10.0.11 | 7777 | Authentication |
| **PCF** (Policy Control Function) | pcf-0 | 10.10.0.13 | 7777 | Policy control |
| **NSSF** (Network Slice Selection) | nssf-0 | 10.10.0.14 | 7777 | Slice selection |
| **AMF** (Access and Mobility Mgmt) | amf-0 | 10.10.0.5 | 7777, 38412 | UE registration |
| **SMF** (Session Management Function) | smf-0 | 10.10.0.4 | 7777 | Session mgmt |
| **UPF** (User Plane Function) | upf-0 | 10.10.0.7 | 2152 | User traffic |

### Network Slices Configuration

| Slice | SST | DNN | Subnet | Gateway | Interface |
|-------|-----|-----|--------|---------|-----------|
| **eMBB** | 1 | embb.testbed | 10.45.0.0/24 | 10.45.0.1 | ogstun |
| **URLLC** | 2 | urllc.v2x | 10.45.1.0/24 | 10.45.1.1 | ogstun2 |
| **mMTC** | 3 | mmtc.testbed | 10.45.2.0/24 | 10.45.2.1 | ogstun3 |

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         K3s Cluster                             │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │              Calico CNI (10.10.0.0/24)                │    │
│  │                                                         │    │
│  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐   │    │
│  │  │ NRF  │  │ SCP  │  │ UDR  │  │ UDM  │  │ AUSF │   │    │
│  │  │ .10  │  │ .200 │  │ .20  │  │ .12  │  │ .11  │   │    │
│  │  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘   │    │
│  │                                                         │    │
│  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐   │    │
│  │  │ PCF  │  │ NSSF │  │ AMF  │  │ SMF  │  │ UPF  │   │    │
│  │  │ .13  │  │ .14  │  │ .5   │  │ .4   │  │ .7   │   │    │
│  │  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘   │    │
│  │                                                         │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │           External MongoDB Service                     │    │
│  │           (mongod-external: 192.168.50.251)           │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │           Persistent Storage                           │    │
│  │           (/mnt/data/open5gs-logs)                     │    │
│  └───────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ NodePort 38412 (NGAP)
                            ▼
                    ┌──────────────┐
                    │  gNB/UERANSIM│
                    └──────────────┘
```

## 📂 Directory Structure

```
open5gs-k3s-calico/
├── README.md                              # This comprehensive guide
├── DEPLOYMENT_GUIDE.md                    # Detailed deployment documentation
├── MIGRATION-SUMMARY.md                   # Migration notes from compose
├── SCRIPTS-README.md                      # Individual script documentation
├── CALICO-STATIC-IP-README.md            # Calico configuration details
│
├── Helper Scripts (Deployment Workflow)
├── setup-k3s-environment-calico.sh       # 1. Environment setup
├── build-import-containers.sh            # 2. Build and import images
├── deploy-k3s-calico.sh                  # 3. Deploy Open5GS
├── verify-static-ips.sh                  # 4. Verify deployment
├── verify-mongodb.sh                     # 5. Verify MongoDB connectivity
├── redeploy-k3s.sh                       # Quick redeploy script
│
├── Kubernetes Manifests
├── 00-foundation/                        # Foundation resources
│   ├── namespace.yaml                    # open5gs namespace
│   ├── calico-ippool.yaml               # Calico IPPool (10.10.0.0/24)
│   ├── mongod-external.yaml             # External MongoDB service
│   └── storage.yaml                      # Persistent volume configs
│
├── 01-configmaps/                        # NF configurations
│   ├── amf-config.yaml
│   ├── ausf-config.yaml
│   ├── nrf-config.yaml
│   ├── nssf-config.yaml
│   ├── pcf-config.yaml
│   ├── scp-config.yaml
│   ├── smf-config.yaml
│   ├── udm-config.yaml
│   ├── udr-config.yaml
│   └── upf-config.yaml
│
├── 02-control-plane/                     # Control plane NFs
│   ├── nrf.yaml                          # StatefulSet: nrf-0
│   ├── scp.yaml                          # StatefulSet: scp-0
│   ├── udr.yaml                          # StatefulSet: udr-0
│   ├── udm.yaml                          # StatefulSet: udm-0
│   ├── ausf.yaml                         # StatefulSet: ausf-0
│   ├── pcf.yaml                          # StatefulSet: pcf-0
│   └── nssf.yaml                         # StatefulSet: nssf-0
│
├── 03-session-mgmt/                      # Session management NFs
│   ├── amf.yaml                          # StatefulSet: amf-0
│   └── smf.yaml                          # StatefulSet: smf-0
│
├── 04-user-plane/                        # User plane NFs
│   └── upf.yaml                          # StatefulSet: upf-0
│
└── deployment-summary/                    # Auto-generated reports
    └── deployment_YYYYMMDD_HHMMSS.txt   # Deployment metrics
```

## 🚀 Quick Start Guide

### Prerequisites

- **Operating System**: Ubuntu 20.04/22.04 LTS or similar
- **Hardware**: Minimum 4GB RAM, 20GB disk space, 2 CPU cores
- **Network**: Internet connection for package installation
- **Privileges**: Root/sudo access
- **External MongoDB**: Running MongoDB instance (default: 192.168.50.251:27017)

### Step-by-Step Deployment

#### Step 1: Setup K3s Environment with Calico

This script prepares your system by installing K3s without default CNI and configuring Calico for static IP support.

```bash
cd /path/to/open5gs-k3s-calico

# Make script executable
chmod +x setup-k3s-environment-calico.sh

# Run environment setup (requires sudo)
sudo ./setup-k3s-environment-calico.sh
```

**What this script does:**
- Installs required packages (curl, git, iptables, etc.)
- Loads kernel modules (sctp, br_netfilter, ip_tables)
- Enables IP forwarding (IPv4/IPv6)
- Creates log directories (/mnt/data/open5gs-logs)
- Installs K3s with CNI disabled
- Installs Calico CNI (v3.27.0)
- Configures Calico IPPool for Open5GS
- Sets up kubectl access

**Verification:**
```bash
# Check K3s status
sudo systemctl status k3s

# Check Calico pods
kubectl get pods -n kube-system -l k8s-app=calico-node

# Verify kubectl access
kubectl get nodes
```

#### Step 2: Build and Import Container Images

This script builds Open5GS container images from the compose directory and imports them into K3s containerd.

```bash
# Make script executable
chmod +x build-import-containers.sh

# Run build and import (checks for existing images)
sudo ./build-import-containers.sh

# Force rebuild all images
sudo ./build-import-containers.sh --force
```

**What this script does:**
- Checks for existing container images
- Builds missing images using docker compose
- Imports all images to K3s containerd
- Verifies imported images

**Verification:**
```bash
# List imported images in K3s
sudo k3s ctr images ls | grep open5gs

# Should show:
# docker.io/library/open5gs-amf:latest
# docker.io/library/open5gs-ausf:latest
# docker.io/library/open5gs-nrf:latest
# ... (all NF images)
```

#### Step 3: Deploy Open5GS with Parallel Deployment

This is the main deployment script that orchestrates the entire Open5GS deployment with parallel execution.

```bash
# Make script executable
chmod +x deploy-k3s-calico.sh

# Run deployment (requires sudo)
sudo ./deploy-k3s-calico.sh
```

**What this script does:**
1. **Cleanup Phase**: Removes previous deployment and logs
2. **Foundation Phase**: Creates namespace, MongoDB endpoint, Calico IPPool
3. **ConfigMap Phase**: Deploys all NF configurations
4. **Parallel Deployment**:
   - Deploys NRF first (service discovery foundation)
   - Deploys SCP second (SBI routing)
   - Deploys remaining NFs in parallel (UDR, UDM, AUSF, PCF, NSSF, AMF, SMF, UPF)
5. **Metrics Collection**: Gathers NRF registrations and timing data
6. **Summary Generation**: Creates detailed deployment report

**Expected Output:**
```
[INFO] Starting Open5GS deployment...
[INFO] Stopping bare-metal Open5GS services...
[INFO] Cleaning up previous deployment...
[SUCCESS] Cleanup completed in 15234ms
[INFO] Setting up foundation...
[SUCCESS] Foundation setup completed in 4567ms
[INFO] Creating ConfigMaps...
[SUCCESS] ConfigMaps created in 5123ms
[INFO] Deploying Network Functions in parallel...
[INFO] Deploying nrf...
[SUCCESS] nrf ready in 12345ms
[INFO] Deploying scp...
[SUCCESS] scp ready in 13456ms
[INFO] Deploying remaining NFs in parallel...
[SUCCESS] All NFs deployed in 32456ms
[SUCCESS] Deployment summary saved to: deployment-summary/deployment_20251028_153045.txt

Total Deployment Time: 72456ms (72.45s)
```

#### Step 4: Verify Static IP Assignment

This script comprehensively verifies that all pods have correct static IPs and are functioning properly.

```bash
# Make script executable
chmod +x verify-static-ips.sh

# Run verification
./verify-static-ips.sh
```

**What this script checks:**
- Calico installation and node status
- Open5GS namespace existence
- Calico IPPool configuration (10.10.0.0/24)
- Pod static IP assignments vs expected IPs
- ConfigMap presence
- Pod connectivity (ping and HTTP tests)
- NF registrations with NRF
- Service endpoints

**Expected Output:**
```
================================================
  Open5GS Calico Static IP Verification
================================================

✓ Calico is installed (1 node(s))
✓ Namespace 'open5gs' exists
✓ IPPool 'open5gs-pool' exists
  CIDR: 10.10.0.0/24

Checking pod static IP assignments...
✓ nrf-0: 10.10.0.10 (Running)
✓ scp-0: 10.10.0.200 (Running)
✓ udr-0: 10.10.0.20 (Running)
✓ udm-0: 10.10.0.12 (Running)
✓ ausf-0: 10.10.0.11 (Running)
✓ pcf-0: 10.10.0.13 (Running)
✓ nssf-0: 10.10.0.14 (Running)
✓ amf-0: 10.10.0.5 (Running)
✓ smf-0: 10.10.0.4 (Running)
✓ upf-0: 10.10.0.7 (Running)

✓ All checks passed!
  Static IP deployment is ready
```

#### Step 5 (Optional): Verify MongoDB Connectivity

Verify that Network Functions can connect to the external MongoDB instance.

```bash
chmod +x verify-mongodb.sh
./verify-mongodb.sh
```

## 📊 Static IP Assignments

All Network Functions use **static IP addresses** from the Calico IPPool (10.10.0.0/24):

| Pod Name | Static IP | Annotation | Purpose |
|----------|-----------|------------|---------|
| nrf-0 | 10.10.0.10 | `cni.projectcalico.org/ipAddrs: ["10.10.0.10"]` | Service discovery |
| scp-0 | 10.10.0.200 | `cni.projectcalico.org/ipAddrs: ["10.10.0.200"]` | SBI proxy |
| udr-0 | 10.10.0.20 | `cni.projectcalico.org/ipAddrs: ["10.10.0.20"]` | Data repository |
| udm-0 | 10.10.0.12 | `cni.projectcalico.org/ipAddrs: ["10.10.0.12"]` | Data management |
| ausf-0 | 10.10.0.11 | `cni.projectcalico.org/ipAddrs: ["10.10.0.11"]` | Authentication |
| pcf-0 | 10.10.0.13 | `cni.projectcalico.org/ipAddrs: ["10.10.0.13"]` | Policy control |
| nssf-0 | 10.10.0.14 | `cni.projectcalico.org/ipAddrs: ["10.10.0.14"]` | Slice selection |
| amf-0 | 10.10.0.5 | `cni.projectcalico.org/ipAddrs: ["10.10.0.5"]` | Access/Mobility |
| smf-0 | 10.10.0.4 | `cni.projectcalico.org/ipAddrs: ["10.10.0.4"]` | Session mgmt |
| upf-0 | 10.10.0.7 | `cni.projectcalico.org/ipAddrs: ["10.10.0.7"]` | User plane |

### How Static IPs Work

Static IPs are assigned using Calico annotations in pod specifications:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nrf-0
  annotations:
    cni.projectcalico.org/ipAddrs: '["10.10.0.10"]'
spec:
  # ... pod spec
```

The Calico IPPool reserves the 10.10.0.0/24 subnet specifically for Open5GS:

```yaml
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: open5gs-pool
spec:
  cidr: 10.10.0.0/24
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
  blockSize: 26
```

## 🎓 Essential Commands for Students

### Basic Pod Management

```bash
# List all Open5GS pods with IPs
kubectl get pods -n open5gs -o wide

# Describe a specific pod (shows events, config, status)
kubectl describe pod nrf-0 -n open5gs

# Check pod logs (follow mode)
kubectl logs -f nrf-0 -n open5gs

# Get logs from all pods (stream)
kubectl logs -f -n open5gs --all-containers=true

# Execute command inside a pod
kubectl exec -it amf-0 -n open5gs -- bash

# Check pod resource usage
kubectl top pod -n open5gs
```

### Service and Network Inspection

```bash
# List all services
kubectl get svc -n open5gs

# Describe AMF service (shows NodePort)
kubectl describe svc amf -n open5gs

# Test connectivity between pods
kubectl exec -n open5gs scp-0 -- ping -c 3 10.10.0.10

# Test NRF HTTP API from SCP
kubectl exec -n open5gs scp-0 -- curl http://10.10.0.10:7777/nnrf-nfm/v1/nf-instances

# Check UPF TUN interface
kubectl exec -n open5gs upf-0 -- ip addr show ogstun
```

### ConfigMap Management

```bash
# List all ConfigMaps
kubectl get configmap -n open5gs

# View AMF configuration
kubectl get configmap amf-config -n open5gs -o yaml

# Edit a ConfigMap (changes take effect after pod restart)
kubectl edit configmap amf-config -n open5gs

# Restart pod to apply ConfigMap changes
kubectl delete pod amf-0 -n open5gs  # StatefulSet will recreate it
```

### Calico and IPPool Management

```bash
# View Calico IPPools
kubectl get ippools.crd.projectcalico.org

# Describe Open5GS IPPool
kubectl get ippool open5gs-pool -o yaml

# Check Calico node status
kubectl get pods -n kube-system -l k8s-app=calico-node

# View Calico network policies (if any)
kubectl get networkpolicies -n open5gs
```

### Debugging and Troubleshooting

```bash
# Check pod events (useful for startup issues)
kubectl get events -n open5gs --sort-by='.lastTimestamp'

# Check if pod is ready
kubectl get pod amf-0 -n open5gs -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'

# View pod annotations (including static IP)
kubectl get pod nrf-0 -n open5gs -o jsonpath='{.metadata.annotations}'

# Check pod resource limits and requests
kubectl get pod amf-0 -n open5gs -o jsonpath='{.spec.containers[0].resources}'

# Test DNS resolution inside pod
kubectl exec -n open5gs amf-0 -- nslookup nrf.open5gs.svc.cluster.local

# Check if pod can reach MongoDB
kubectl exec -n open5gs udr-0 -- nc -zv mongod-external 27017
```

### Deployment Management

```bash
# Scale a StatefulSet (if needed for testing)
kubectl scale statefulset amf -n open5gs --replicas=2

# View StatefulSet status
kubectl get statefulset -n open5gs

# Rollout restart (recreate all pods)
kubectl rollout restart statefulset/amf -n open5gs

# Check rollout status
kubectl rollout status statefulset/amf -n open5gs
```

### NRF Registration Verification

```bash
# Check NRF logs for NF registrations
kubectl logs nrf-0 -n open5gs | grep "NF registered"

# Query NRF API for registered NFs
kubectl exec -n open5gs nrf-0 -- curl -s http://10.10.0.10:7777/nnrf-nfm/v1/nf-instances | jq .

# Count registered NFs
kubectl logs nrf-0 -n open5gs | grep -c "NF registered"
```

### Monitoring and Metrics

```bash
# Check pod metrics (requires metrics-server)
kubectl top pod -n open5gs

# View pod resource usage over time
watch -n 2 'kubectl top pod -n open5gs'

# Export Prometheus metrics from AMF (if exposed)
kubectl port-forward -n open5gs amf-0 9090:9090
curl http://localhost:9090/metrics
```

### Cleanup and Redeploy

```bash
# Delete entire namespace (removes all resources)
kubectl delete namespace open5gs

# Quick redeploy using helper script
sudo ./redeploy-k3s.sh

# Force rebuild and redeploy
sudo ./build-import-containers.sh --force
sudo ./deploy-k3s-calico.sh
```

## 📈 Performance Metrics

### Deployment Speed

| Metric | Time | Description |
|--------|------|-------------|
| **Total Deployment** | 60-90s | Complete end-to-end deployment |
| **Cleanup Phase** | 10-20s | Namespace deletion and log cleanup |
| **Foundation Phase** | 4-6s | Namespace, MongoDB, IPPool setup |
| **ConfigMap Phase** | 5-7s | All NF configuration deployment |
| **Parallel NF Deploy** | 30-45s | All 10 NFs deployed in parallel |
| **Sequential (Old)** | 180-240s | For comparison (60-70% slower) |

### Resource Usage (Typical)

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| K3s Server | 200-400m | 512-1024Mi | - |
| Calico Node | 50-100m | 128-256Mi | - |
| NRF | 10-50m | 64-128Mi | - |
| SCP | 10-50m | 64-128Mi | - |
| AMF | 20-100m | 128-256Mi | - |
| SMF | 20-100m | 128-256Mi | - |
| UPF | 50-200m | 256-512Mi | - |
| Other NFs | 10-50m each | 64-128Mi each | - |
| **Total** | ~500-1000m | ~1.5-3GB | ~10GB logs |

## 🔧 Configuration Customization

### Modify Network Function Configuration

1. Edit the ConfigMap:
```bash
kubectl edit configmap amf-config -n open5gs
```

2. Restart the pod to apply changes:
```bash
kubectl delete pod amf-0 -n open5gs
```

3. Verify changes:
```bash
kubectl logs -f amf-0 -n open5gs
```

### Change Static IP Assignments

1. Edit the StatefulSet YAML file (e.g., `02-control-plane/amf.yaml`)

2. Modify the annotation:
```yaml
annotations:
  cni.projectcalico.org/ipAddrs: '["10.10.0.5"]'  # Change this
```

3. Ensure the IP is within the IPPool range (10.10.0.0/24)

4. Redeploy:
```bash
kubectl delete -f 03-session-mgmt/amf.yaml
kubectl apply -f 03-session-mgmt/amf.yaml
```

### Configure External MongoDB

Edit `00-foundation/mongod-external.yaml` to change MongoDB endpoint:

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: mongod-external
  namespace: open5gs
subsets:
  - addresses:
      - ip: 192.168.50.251  # Change this to your MongoDB IP
    ports:
      - port: 27017
```

## 🔍 Troubleshooting Guide

### Pod Stuck in Pending State

**Check:**
```bash
kubectl describe pod <pod-name> -n open5gs
```

**Common causes:**
- Insufficient resources
- Image not imported to K3s
- Node not ready

**Solution:**
```bash
# Import missing image
sudo ./build-import-containers.sh --force

# Check node status
kubectl get nodes
```

### Pod CrashLoopBackOff

**Check logs:**
```bash
kubectl logs <pod-name> -n open5gs --previous
```

**Common causes:**
- MongoDB connection failure
- Configuration error
- Missing dependencies (NRF/SCP not ready)

**Solution:**
```bash
# Check MongoDB connectivity
./verify-mongodb.sh

# Verify NRF is running
kubectl get pod nrf-0 -n open5gs

# Check ConfigMap
kubectl get configmap -n open5gs
```

### Static IP Not Assigned

**Verify Calico:**
```bash
kubectl get ippool open5gs-pool
kubectl get pods -n kube-system -l k8s-app=calico-node
```

**Check pod annotation:**
```bash
kubectl get pod <pod-name> -n open5gs -o yaml | grep -A 2 annotations
```

**Solution:**
```bash
# Recreate IPPool
kubectl delete ippool open5gs-pool
kubectl apply -f 00-foundation/calico-ippool.yaml

# Recreate pod
kubectl delete pod <pod-name> -n open5gs
```

### NF Not Registering with NRF

**Check NRF logs:**
```bash
kubectl logs nrf-0 -n open5gs | grep -i error
```

**Check NF logs:**
```bash
kubectl logs amf-0 -n open5gs | grep -i nrf
```

**Test connectivity:**
```bash
kubectl exec -n open5gs amf-0 -- ping -c 3 10.10.0.10
kubectl exec -n open5gs amf-0 -- curl http://10.10.0.10:7777
```

### UPF TUN Interface Not Created

**Check UPF logs:**
```bash
kubectl logs upf-0 -n open5gs | grep -i tun
```

**Verify privileged mode:**
```bash
kubectl get pod upf-0 -n open5gs -o yaml | grep privileged
```

**Check interface inside pod:**
```bash
kubectl exec -n open5gs upf-0 -- ip addr show
```

## 📚 Additional Resources

### Related Documentation

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**: Detailed deployment walkthrough with parallel deployment explanation
- **[MIGRATION-SUMMARY.md](MIGRATION-SUMMARY.md)**: Migration notes from Docker Compose to K3s
- **[SCRIPTS-README.md](SCRIPTS-README.md)**: Individual script documentation and usage
- **[CALICO-STATIC-IP-README.md](CALICO-STATIC-IP-README.md)**: In-depth Calico configuration guide

### External Resources

- [Open5GS Documentation](https://open5gs.org/open5gs/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/about/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [UERANSIM GitHub](https://github.com/aligungr/UERANSIM)

## 🎯 Next Steps

### Connect UERANSIM gNB

Configure your gNB to connect to AMF:

```yaml
# UERANSIM gNB config
mcc: 001
mnc: 01
tac: 1
amfConfigs:
  - address: <node-ip>  # K3s node IP
    port: 38412         # AMF NodePort
```

Get node IP and AMF port:
```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
AMF_PORT=$(kubectl get svc amf -n open5gs -o jsonpath='{.spec.ports[?(@.name=="ngap")].nodePort}')
echo "Connect gNB to: ${NODE_IP}:${AMF_PORT}"
```

### Add Subscribers

Use MongoDB CLI or Open5GS WebUI to add subscribers:

```bash
# Connect to MongoDB
kubectl run -it --rm mongo-client --image=mongo:latest -n open5gs -- mongosh mongodb://192.168.50.251:27017/open5gs

# Add subscriber
db.subscribers.insertOne({
  imsi: "001010000000001",
  security: {
    k: "465B5CE8B199B49FAA5F0A2EE238A6BC",
    opc: "E8ED289DEBA952E4283B54E88E6183CA",
    amf: "8000",
    sqn: NumberLong(0)
  },
  // ... additional fields
})
```

### Monitor Deployment

View deployment summary:
```bash
cat deployment-summary/deployment_$(ls -t deployment-summary/ | head -1)
```

Continuous monitoring:
```bash
watch -n 2 'kubectl get pods -n open5gs -o wide'
```

## 🤝 Contributing

Improvements and contributions are welcome! Areas for enhancement:
- Helm chart creation
- Horizontal pod autoscaling
- Enhanced network policies
- Monitoring stack integration (Prometheus/Grafana)
- CI/CD pipeline integration

## 📄 License

This deployment is based on Open5GS and follows its licensing terms. See [Open5GS License](https://github.com/open5gs/open5gs/blob/main/LICENSE) for details.

---

**Last Updated**: October 28, 2025  
**Version**: 2.0  
**Author**: Rayhan Egar (rayhanegar.sn@gmail.com)
