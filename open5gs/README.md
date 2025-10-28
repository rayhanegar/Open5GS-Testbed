# Open5GS 5G Core Network Deployment

This directory provides **three complementary deployment methods** for standing up a complete **Open5GS 5G Core Network** with **3 Network Slices** (eMBB, URLLC, mMTC) and **UERANSIM integration** support:

1. **Native/Bare-metal Deployment**: Direct installation on Ubuntu Linux using systemd services
2. **Docker Compose Deployment**: Containerized deployment with individual containers for each Network Function
3. **Kubernetes (K3s) Deployment**: Production-grade orchestrated deployment using K3s with Calico networking

## 🎯 Features

- **Multiple Deployment Options**: Choose between native, containerized, or orchestrated deployments
- **3 Network Slices**: Enhanced Mobile Broadband (eMBB), Ultra-Reliable Low-Latency Communication (URLLC), and Massive Machine-Type Communication (mMTC)
- **UERANSIM Ready**: Pre-configured for UERANSIM gNB and UE integration
- **Production Ready**: Includes logging, error handling, and service management
- **Network Isolation**: Complete network slice separation with dedicated TUN interfaces
- **Helper Scripts**: Utility scripts for network setup, iptables configuration, and service management

## 📋 Network Slices Configuration

All deployment methods support the same 3-slice configuration:

| Slice | SST | DNN | Subnet | Gateway | Interface | Description |
|-------|-----|-----|--------|---------|-----------|-------------|
| eMBB | 1 | embb.testbed | 10.45.0.0/24 | 10.45.0.1 | ogstun | Enhanced Mobile Broadband |
| URLLC | 2 | urllc.v2x | 10.45.1.0/24 | 10.45.1.1 | ogstun2 | Ultra-Reliable Low-Latency |
| mMTC | 3 | mmtc.testbed | 10.45.2.0/24 | 10.45.2.1 | ogstun3 | Massive Machine-Type Communication |

## 🚀 Quick Start

Choose your preferred deployment method:

### Option A – Native/Bare-metal Installation

This method installs Open5GS directly on Ubuntu Linux using systemd services.

#### Prerequisites
- Ubuntu 20.04 LTS or later
- Root/sudo access
- Internet connection
- Minimum 4GB RAM, 20GB free disk space

#### Installation Steps

**Step 1: Install Open5GS and Dependencies**

Follow the comprehensive installation guide:
```bash
# See detailed instructions in:
cat "Open5GS Setup and Configuration.md"
```

This guide covers:
- MongoDB 8.0 installation
- Node.js 20 installation
- Open5GS installation from PPA
- Open5GS WebUI setup
- Complete YAML configuration for all Network Functions

**Step 2: Setup Network Interfaces**

Create TUN interfaces for each network slice:
```bash
cd scripts
sudo chmod +x open5gs-create-tun-interfaces.sh
sudo ./open5gs-create-tun-interfaces.sh --add
```

**Step 3: Configure IP Tables and Routing**

Enable internet access for UEs through NAT:
```bash
sudo chmod +x open5gs-iptables-setup.sh
sudo ./open5gs-iptables-setup.sh --add
```

**Step 4: Start Open5GS Services**

Restart all services with proper dependency order:
```bash
sudo chmod +x open5gs-restart-services.sh
sudo ./open5gs-restart-services.sh
```

**Step 5: Verify Installation**

```bash
# Check service status
sudo systemctl status open5gs-*

# Verify network interfaces
ip addr show | grep ogstun

# View logs
sudo journalctl -f -u open5gs-amfd
```

#### Helper Scripts

The `scripts/` directory contains three essential utilities for native deployment:

1. **`open5gs-create-tun-interfaces.sh`**: Manages TUN interfaces
   ```bash
   sudo ./open5gs-create-tun-interfaces.sh --add     # Create interfaces
   sudo ./open5gs-create-tun-interfaces.sh --remove  # Remove interfaces
   ```

2. **`open5gs-iptables-setup.sh`**: Manages firewall rules and NAT
   ```bash
   sudo ./open5gs-iptables-setup.sh --add           # Add rules
   sudo ./open5gs-iptables-setup.sh --remove        # Remove rules
   sudo ./open5gs-iptables-setup.sh --status        # Check status
   sudo ./open5gs-iptables-setup.sh --list-backups  # Show backups
   ```

3. **`open5gs-restart-services.sh`**: Restarts all services in correct order
   ```bash
   sudo ./open5gs-restart-services.sh
   ```

### Option B – Docker Compose Deployment

This method runs each Network Function in its own container with pre-configured networking.

#### Prerequisites
- Docker and Docker Compose installed
- Ubuntu 20.04/22.04 or similar Linux distribution
- Root/sudo access for network configuration

#### Deployment Steps

```bash
cd open5gs-compose

# Step 1: Prepare host networking
chmod +x setup-host-network-*.sh

# Choose your networking setup:
# For Tailscale users:
sudo ./setup-host-network-tailscale.sh

# For EduVPN users:
sudo ./setup-host-network-eduvpn.sh

# For Ethernet (ICN) users:
sudo ./setup-host-network-ethernet-icn.sh

# Step 2: Create log directories
mkdir -p logs/{nrf,scp,ausf,udr,udm,pcf,nssf,amf,smf,upf}

# Step 3: Build and launch containers
docker compose build
docker compose up -d

# Step 4: Verify deployment
docker compose ps
docker compose logs -f amf
```

#### Key Features
- Individual containers for each Network Function
- Persistent log volumes under `./logs/`
- Static IP assignments on Docker bridge network (10.10.0.0/24)
- Easy configuration updates (edit YAML, restart service)
- Tailscale/EduVPN/Ethernet network integration

For detailed information, see [`open5gs-compose/README.md`](open5gs-compose/README.md)

### Option C – Kubernetes (K3s) Deployment

This method provides a production-grade orchestrated deployment using K3s with Calico networking.

#### Prerequisites
- K3s cluster (single-node or multi-node)
- Calico CNI for network policy support
- External MongoDB instance
- Root/sudo access

#### Deployment Steps

```bash
cd open5gs-k3s-calico

# Step 1: Setup K3s environment with Calico
sudo ./setup-k3s-environment-calico.sh

# Step 2: Build and import container images (optional)
sudo ./build-import-containers.sh

# Step 3: Deploy Open5GS with parallel deployment
sudo ./deploy-k3s-calico.sh

# Step 4: Verify deployment
kubectl get pods -n open5gs
kubectl get svc -n open5gs

# Check deployment summary
cat deployment-summary/deployment_*.txt
```

#### Key Features
- **Parallel deployment**: ~60-70% faster than sequential (60-90s total)
- **Static IP assignment**: Using Calico IPPool annotations
- **Automated cleanup**: Previous deployments automatically removed
- **Deployment metrics**: Per-pod timing and NRF registration tracking
- **Production-ready**: StatefulSets, persistent volumes, node affinity
- **Network isolation**: Using Calico NetworkPolicy

#### Performance
- Total deployment time: 60-90 seconds (vs 180-240s sequential)
- Parallel NF deployment: 30-45 seconds
- Automatic summary reports in `deployment-summary/`

For detailed information, see:
- [`open5gs-k3s-calico/DEPLOYMENT_GUIDE.md`](open5gs-k3s-calico/DEPLOYMENT_GUIDE.md)
- [`open5gs-k3s-calico/MIGRATION-SUMMARY.md`](open5gs-k3s-calico/MIGRATION-SUMMARY.md)
- [`open5gs-k3s-calico/SCRIPTS-README.md`](open5gs-k3s-calico/SCRIPTS-README.md)

## 🛠️ Core Components (All Deployment Methods)

### Software Stack
- **MongoDB 8.0**: Database backend for subscriber information
- **Node.js 20+**: Runtime for WebUI
- **Open5GS**: Complete 5G Core Network implementation
- **Open5GS WebUI**: Web-based management interface (native/compose)

### 5G Core Network Functions
- **NRF** (Network Repository Function): Service discovery and registration
- **SCP** (Service Communication Proxy): Service-based interface routing
- **AMF** (Access and Mobility Management Function): UE registration and mobility
- **SMF** (Session Management Function): PDU session management
- **UPF** (User Plane Function): User plane traffic forwarding
- **AUSF** (Authentication Server Function): Authentication services
- **UDM** (Unified Data Management): Subscription data management
- **UDR** (Unified Data Repository): Data repository
- **PCF** (Policy Control Function): Policy management
- **NSSF** (Network Slice Selection Function): Slice selection
- **BSF** (Binding Support Function): Binding support

### Legacy 4G/EPC Support (Optional)
- **MME** (Mobility Management Entity)
- **HSS** (Home Subscriber Server)
- **SGWC/SGWU** (Serving Gateway Control/User Plane)
- **PCRF** (Policy Charging Rules Function)

## 🔧 Management and Monitoring

### WebUI Access (Native & Compose Deployments)
- **URL**: http://localhost:9999
- **Default Username**: admin
- **Default Password**: 1423
- **Purpose**: Add/manage subscriber information, monitor services

### Configuration Files

**Native Deployment:**
- **Location**: `/etc/open5gs/`
- **Backups**: `/etc/open5gs/backup/`
- **Logs**: `/var/log/open5gs/`

**Compose Deployment:**
- **Configs**: `open5gs-compose/<nf>/<nf>.yaml`
- **Logs**: `open5gs-compose/logs/<nf>/`

**K3s Deployment:**
- **ConfigMaps**: `open5gs-k3s-calico/01-configmaps/`
- **Deployments**: `open5gs-k3s-calico/02-control-plane/`, `03-session-mgmt/`, `04-user-plane/`
- **Logs**: `/mnt/data/open5gs-logs/` (on host)

### Service Management

**Native:**
```bash
# Check service status
sudo systemctl status open5gs-*

# View logs
sudo journalctl -f -u open5gs-amfd

# Restart services
sudo /path/to/scripts/open5gs-restart-services.sh
```

**Compose:**
```bash
# Check container status
docker compose ps

# View logs
docker compose logs -f amf

# Restart service
docker compose restart amf
```

**K3s:**
```bash
# Check pod status
kubectl get pods -n open5gs

# View logs
kubectl logs -f -n open5gs amf-0

# Restart pod
kubectl delete pod -n open5gs amf-0
```

## 📱 UERANSIM Integration

All deployment methods are pre-configured for UERANSIM gNB and UE integration.

### Connection Parameters

Configure your UERANSIM gNB with the appropriate AMF endpoint:

**Native Deployment:**
```yaml
# UERANSIM gNB Configuration
mcc: 001
mnc: 01
tac: 1
amfConfigs:
  - address: 127.0.0.5     # Localhost
    port: 38412
```

**Compose Deployment:**
```yaml
# UERANSIM gNB Configuration
mcc: 001
mnc: 01
tac: 1
amfConfigs:
  - address: <host-ip>     # Host machine IP
    port: 38412
```

**K3s Deployment:**
```yaml
# UERANSIM gNB Configuration
mcc: 001
mnc: 01
tac: 1
amfConfigs:
  - address: <node-ip>     # K3s node IP
    port: 30412            # NodePort for AMF NGAP
```

### UE Configuration

Configure UERANSIM UE with authentication parameters:
```yaml
# UERANSIM UE Configuration  
supi: imsi-001010000000001
key: 465B5CE8B199B49FAA5F0A2EE238A6BC
op: E8ED289DEBA952E4283B54E88E6183CA
amf: 8000
```

### Network Slice Selection

Configure UEs to request specific slices:

```yaml
# For eMBB slice (Default internet)
sessions:
  - type: 'IPv4'
    apn: 'embb.testbed'
    slice:
      sst: 1

# For URLLC slice (V2X, low latency)
sessions:
  - type: 'IPv4'
    apn: 'urllc.v2x'
    slice:
      sst: 2

# For mMTC slice (IoT, massive connectivity)
sessions:
  - type: 'IPv4'
    apn: 'mmtc.testbed'
    slice:
      sst: 3
```

## 🔧 Troubleshooting

### Native Deployment

**Check Service Status:**
```bash
sudo systemctl status open5gs-*
```

**View Service Logs:**
```bash
# View all Open5GS logs
sudo journalctl -f -u open5gs-*

# View specific service log
sudo journalctl -f -u open5gs-amfd
```

**Verify Network Interfaces:**
```bash
# Check TUN interfaces
ip addr show | grep ogstun

# Verify routing table
ip route show

# Check iptables rules
sudo iptables -L -v -n
sudo iptables -t nat -L -v -n
```

**Common Issues:**

1. **MongoDB Connection Issues**
   ```bash
   sudo systemctl restart mongod
   sudo systemctl status mongod
   ```

2. **Service Dependencies**
   ```bash
   # Services have dependencies; use the restart script:
   sudo ./scripts/open5gs-restart-services.sh
   ```

3. **TUN Interface Not Created**
   ```bash
   sudo ./scripts/open5gs-create-tun-interfaces.sh --add
   ```

### Docker Compose Deployment

**Check Container Status:**
```bash
docker compose ps
docker compose logs <service-name>
```

**Verify Networking:**
```bash
# Check container network
docker network inspect open5gs-compose_5gcore

# Test connectivity between containers
docker exec open5gs-amf ping -c 1 10.10.0.10
```

**Common Issues:**

1. **SCTP Connection Failed**
   - Ensure SCTP module is loaded: `lsmod | grep sctp`
   - Load if needed: `sudo modprobe sctp`

2. **UPF TUN Device Issues**
   - Check: `docker exec open5gs-upf ip addr show ogstun`
   - Container needs privileged mode (already configured)

3. **Port Conflicts**
   ```bash
   sudo netstat -tulpn | grep 38412
   ```

### K3s Deployment

**Check Pod Status:**
```bash
kubectl get pods -n open5gs
kubectl describe pod -n open5gs <pod-name>
```

**View Pod Logs:**
```bash
kubectl logs -f -n open5gs <pod-name>
```

**Verify Static IPs:**
```bash
# Use the verification script
./open5gs-k3s-calico/verify-static-ips.sh
```

**Check NRF Registrations:**
```bash
kubectl exec -n open5gs nrf-0 -- curl -s http://localhost:7777/nnrf-nfm/v1/nf-instances
```

**Common Issues:**

1. **Pod Not Starting**
   - Check events: `kubectl describe pod -n open5gs <pod-name>`
   - Check logs: `kubectl logs -n open5gs <pod-name>`

2. **MongoDB Connection Issues**
   - Verify external MongoDB endpoint: `kubectl get svc -n open5gs mongod-external`
   - Check MongoDB accessibility from pods

3. **Static IP Not Assigned**
   - Verify Calico IPPool: `kubectl get ippool -n open5gs`
   - Check pod annotations: `kubectl get pod -n open5gs <pod-name> -o yaml`

## 📚 Repository Structure

```
open5gs/
├── README.md                              # This file
├── Open5GS Setup and Configuration.md     # Detailed native installation guide
├── configs-reference/                     # Reference configuration files
│   ├── amf.yaml
│   ├── ausf.yaml
│   ├── smf.yaml
│   ├── upf.yaml
│   └── ... (all NF configs)
├── scripts/                               # Helper scripts for native deployment
│   ├── open5gs-create-tun-interfaces.sh   # TUN interface management
│   ├── open5gs-iptables-setup.sh          # Firewall and NAT configuration
│   └── open5gs-restart-services.sh        # Service restart utility
├── open5gs-compose/                       # Docker Compose deployment
│   ├── README.md                          # Compose deployment guide
│   ├── docker-compose.yml                 # Compose configuration
│   ├── setup-host-network-*.sh            # Host network setup scripts
│   ├── validate-config.sh                 # Configuration validator
│   ├── amf/                               # AMF Dockerfile and config
│   ├── smf/                               # SMF Dockerfile and config
│   ├── upf/                               # UPF Dockerfile and config
│   └── ... (directories for each NF)
└── open5gs-k3s-calico/                    # Kubernetes deployment
    ├── DEPLOYMENT_GUIDE.md                # K3s deployment guide
    ├── MIGRATION-SUMMARY.md               # Migration notes
    ├── SCRIPTS-README.md                  # Script documentation
    ├── deploy-k3s-calico.sh               # Main deployment script
    ├── setup-k3s-environment-calico.sh    # Environment setup
    ├── build-import-containers.sh         # Container build script
    ├── verify-static-ips.sh               # IP verification
    ├── verify-mongodb.sh                  # MongoDB verification
    ├── 00-foundation/                     # Namespace, storage, IPPool
    ├── 01-configmaps/                     # NF configurations
    ├── 02-control-plane/                  # Control plane NFs
    ├── 03-session-mgmt/                   # Session management NFs
    ├── 04-user-plane/                     # User plane NFs
    └── deployment-summary/                # Deployment reports
```

## 📈 Monitoring and Metrics

### Prometheus Metrics Endpoints

Open5GS provides Prometheus-compatible metrics:

**Native Deployment:**
- AMF: http://127.0.0.5:9090/metrics
- SMF: http://127.0.0.4:9090/metrics  
- UPF: http://127.0.0.7:9090/metrics
- PCF: http://127.0.0.13:9090/metrics
- HSS: http://127.0.0.8:9090/metrics

**Compose Deployment:**
- AMF: http://localhost:9005/metrics
- SMF: http://localhost:9004/metrics
- UPF: http://localhost:9007/metrics
- PCF: http://localhost:9013/metrics

**K3s Deployment:**
- Access via kubectl port-forward:
  ```bash
  kubectl port-forward -n open5gs amf-0 9090:9090
  curl http://localhost:9090/metrics
  ```

### Deployment Metrics (K3s)

Each K3s deployment generates a detailed summary report including:
- Total deployment time and phase breakdown
- Per-pod deployment timing
- NRF/SCP registration metrics
- Resource allocation and status
- Service endpoints

Reports are saved to: `open5gs-k3s-calico/deployment-summary/deployment_YYYYMMDD_HHMMSS.txt`

## 🔒 Security Considerations

### Native Deployment
- Network functions use localhost addresses (127.0.0.x)
- Default authentication keys are used - **change for production**
- Firewall rules allow UE traffic through TUN interfaces
- MongoDB uses default configuration - **secure for production use**
- WebUI uses default credentials - **change immediately**

### Compose Deployment
- Inter-NF communication is not encrypted by default
- Default MongoDB credentials set in docker-compose.yml - **change for production**
- Consider implementing TLS for SBI interfaces in production
- Firewall rules should be adjusted based on security requirements

### K3s Deployment
- Network isolation using Calico NetworkPolicy
- StatefulSets with persistent storage
- Static IP assignment for predictable addressing
- MongoDB external endpoint should use authentication
- Consider using Kubernetes secrets for sensitive data

## 📊 Deployment Comparison

| Feature | Native | Compose | K3s |
|---------|--------|---------|-----|
| **Deployment Time** | Manual | 5-10 min | 60-90 sec (parallel) |
| **Resource Overhead** | Low | Medium | Medium-High |
| **Isolation** | Process-level | Container-level | Pod-level |
| **Scaling** | Manual | Limited | Automatic |
| **Production Ready** | Yes | Yes | Yes |
| **Debugging** | systemd logs | Docker logs | kubectl logs |
| **Updates** | Manual | Rebuild containers | Rolling updates |
| **Networking** | Host TUN | Docker bridge | Calico CNI |
| **Best For** | Development, Testing | Small deployments | Production, Scale |

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Additional deployment methods (Helm charts, Ansible playbooks)
- Enhanced monitoring and observability
- Network slice isolation policies
- Performance optimization
- Security hardening

## 📄 License

This project is based on Open5GS and follows its licensing terms. See [Open5GS License](https://github.com/open5gs/open5gs/blob/main/LICENSE) for details.

## 🔗 References

- [Open5GS Official Documentation](https://open5gs.org/open5gs/docs/)
- [Open5GS GitHub Repository](https://github.com/open5gs/open5gs)
- [UERANSIM GitHub Repository](https://github.com/aligungr/UERANSIM)
- [3GPP 5G Standards](https://www.3gpp.org/specifications-technologies/specifications-by-series)
- [5G Core Network Architecture](https://www.3gpp.org/technologies/5g-system-overview)
- [Calico CNI Documentation](https://docs.tigera.io/calico/latest/about/)
- [K3s Documentation](https://docs.k3s.io/)

## 📞 Support

For technical support:
1. Check the deployment-specific README:
   - Native: `Open5GS Setup and Configuration.md`
   - Compose: `open5gs-compose/README.md`
   - K3s: `open5gs-k3s-calico/DEPLOYMENT_GUIDE.md`
2. Review the troubleshooting section above
3. Check Open5GS documentation
4. Review service/container/pod logs for error messages
5. Verify network connectivity and configuration

## 🏷️ Version History

- **v2.0** (Oct 2025): Added K3s deployment with parallel deployment support
- **v1.5** (Sep 2025): Added Docker Compose deployment option
- **v1.0** (Sep 2025): Initial native deployment with 3 network slices

---

**Last Updated**: October 28, 2025  
**Repository**: Open5GS-Testbed  
**Author**: Rayhan Egar (rayhanegar.sn@gmail.com)