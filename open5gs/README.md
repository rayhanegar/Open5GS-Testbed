# Open5GS Installation and Configuration Script

This directory provides two complementary ways to stand up an **Open5GS 5G Core Network** with **3 Network Slices** (eMBB, URLLC, mMTC) and **UERANSIM integration** support:

1. A fully automated **bare-metal installer script** (`install_open5gs.sh`) for native deployments on Ubuntu.
2. A **Docker Compose stack** under `open5gs-containers/` that runs each Network Function in its own container with pre-wired configs, log volumes, and Tailscale-friendly networking.

## 🎯 Features

- **Complete Automation**: One-script installation and configuration
- **3 Network Slices**: Enhanced Mobile Broadband (eMBB), Ultra-Reliable Low-Latency Communication (URLLC), and Massive Machine-Type Communication (mMTC)
- **UERANSIM Ready**: Pre-configured for UERANSIM integration
- **Production Ready**: Includes logging, error handling, and service management
- **Modular Design**: Install, configure, and launch components separately or all at once
- **Containerized Option**: Prebuilt Dockerfiles and Compose stack mirroring the native layout

## 📋 Network Slices Configuration

| Slice | SST | DNN | Subnet | Gateway | Interface | Description |
|-------|-----|-----|--------|---------|-----------|-------------|
| eMBB | 1 | embb.testbed | 10.45.0.0/24 | 10.45.0.1 | ogstun | Enhanced Mobile Broadband |
| URLLC | 2 | urllc.v2x | 10.45.1.0/24 | 10.45.1.1 | ogstun2 | Ultra-Reliable Low-Latency |
| mMTC | 3 | mmtc.testbed | 10.45.2.0/24 | 10.45.2.1 | ogstun3 | Massive Machine-Type Communication |

## 🚀 Quick Start

### Prerequisites

- Ubuntu 20.04 LTS or later
- Root/sudo access
- Internet connection
- Minimum 4GB RAM, 20GB free disk space

### Option A – Native installation script

This path uses `install_open5gs.sh` to provision everything directly on the host.

#### One-Command Installation

```bash
sudo ./install_open5gs.sh --all
```

This will:
1. Install all required packages (MongoDB, Node.js, Open5GS)
2. Configure all Open5GS services with 3-slice setup
3. Create network interfaces and setup routing
4. Start all services and validate installation

## 📖 Usage Options

*(Native installation script; see below for container workflow)*

### Basic Commands

```bash
# Complete installation (recommended for first time)
sudo ./install_open5gs.sh --all

# Install packages only
sudo ./install_open5gs.sh --install

# Configure services only (after installation)
sudo ./install_open5gs.sh --configure

# Launch services and setup networking
sudo ./install_open5gs.sh --launch

# Check current status
sudo ./install_open5gs.sh --status

# Clean installation (remove everything)
sudo ./install_open5gs.sh --clean

# Show help
./install_open5gs.sh --help
```

### Step-by-Step Installation

If you prefer to install components separately:

```bash
# Step 1: Install required packages
sudo ./install_open5gs.sh --install

# Step 2: Configure Open5GS services
sudo ./install_open5gs.sh --configure

# Step 3: Launch services and setup networking
sudo ./install_open5gs.sh --launch
```

### Option B – Docker Compose deployment

If you prefer to run each Network Function in its own container (with log bind-mounts,
runtime permission fixes, and a Tailscale-aware host setup), head into the
`open5gs-containers/` directory. A detailed guide lives in
[`open5gs-containers/README.md`](../open5gs-containers/README.md), but the high-level
flow is:

```bash
cd open5gs-containers

# Prepare host networking (reads the tailscale0 address and configures forwarding)
chmod +x setup-host-network.sh
sudo ./setup-host-network.sh

# Create log directories before Compose bind-mounts them
mkdir -p logs/{nrf,scp,ausf,udr,udm,pcf,nssf,amf,smf,upf}

# Build and launch the 5GC stack
docker compose build
docker compose up -d
```

Each container copies its mounted YAML config into place at startup, so edit the files
under `open5gs-containers/<nf>/<nf>.yaml` and restart the matching service with
`docker compose restart <nf>` whenever you need to tweak parameters.

## 🛠️ What Gets Installed

### Core Components
- **MongoDB 8.0**: Database backend for subscriber information
- **Node.js 20**: Runtime for WebUI
- **Open5GS**: Complete 5G Core Network implementation
- **Open5GS WebUI**: Web-based management interface

### Network Functions Configured
- **AMF** (Access and Mobility Management Function)
- **SMF** (Session Management Function) 
- **UPF** (User Plane Function)
- **AUSF** (Authentication Server Function)
- **UDM** (Unified Data Management)
- **UDR** (Unified Data Repository)
- **PCF** (Policy Control Function)
- **NRF** (Network Repository Function)
- **NSSF** (Network Slice Selection Function)
- **BSF** (Binding Support Function)
- **SCP** (Service Communication Proxy)

### Legacy 4G Support
- **MME** (Mobility Management Entity)
- **HSS** (Home Subscriber Server)
- **SGWC/SGWU** (Serving Gateway Control/User Plane)
- **PCRF** (Policy Charging Rules Function)

## 🔧 Management Tools

After installation, you'll have access to several utility scripts:

### TUN Interface Management
```bash
# Create network interfaces for all slices
sudo /etc/open5gs/utils/create-tun-interfaces.sh --add

# Remove network interfaces
sudo /etc/open5gs/utils/create-tun-interfaces.sh --remove
```

### Iptables Management
```bash
# Setup firewall rules for Open5GS
sudo /etc/open5gs/utils/setup-iptables.sh --add

# Remove firewall rules
sudo /etc/open5gs/utils/setup-iptables.sh --remove

# Show current firewall status
sudo /etc/open5gs/utils/setup-iptables.sh --status
```

### Service Management
```bash
# Restart all Open5GS services
sudo /etc/open5gs/utils/restart-services.sh
```

## 🌐 Access Points

### WebUI Management
- **URL**: http://localhost:9999
- **Username**: admin
- **Password**: 1423
- **Purpose**: Add/manage subscriber information, monitor services

### Configuration Files
- **Location**: `/etc/open5gs/`
- **Backup**: `/etc/open5gs/backup/`
- **Logs**: `/var/log/open5gs/`

## 📱 UERANSIM Integration

This Open5GS installation is pre-configured for UERANSIM integration:

### Connection Parameters
```yaml
# UERANSIM gNB Configuration
mcc: 001
mnc: 01
tac: 1
amfConfigs:
  - address: 127.0.0.5
    port: 38412

# UERANSIM UE Configuration  
supi: imsi-001010000000001
key: 465B5CE8B199B49FAA5F0A2EE238A6BC
op: E8ED289DEBA952E4283B54E88E6183CA
amf: 8000
```

### Network Slice Selection
Configure UEs to request specific slices:

```yaml
# For eMBB slice
sessions:
  - type: 'IPv4'
    apn: 'embb.testbed'
    slice:
      sst: 1

# For URLLC slice  
sessions:
  - type: 'IPv4'
    apn: 'urllc.v2x'
    slice:
      sst: 2

# For mMTC slice
sessions:
  - type: 'IPv4'
    apn: 'mmtc.testbed'
    slice:
      sst: 3
```

## 🔧 Troubleshooting

### Check Service Status
```bash
sudo systemctl status open5gs-*
```

### View Service Logs
```bash
# View all Open5GS logs
sudo journalctl -f -u open5gs-*

# View specific service log
sudo journalctl -f -u open5gs-amfd
```

### Verify Network Interfaces
```bash
# Check TUN interfaces
ip addr show | grep ogstun

# Verify routing table
ip route show

# Check iptables rules
sudo iptables -L -v -n
sudo iptables -t nat -L -v -n
```

### Validate Configuration Files
```bash
# Check configuration syntax
sudo /etc/open5gs/utils/restart-services.sh
```

### Common Issues

1. **MongoDB Connection Issues**
   ```bash
   sudo systemctl restart mongod
   sudo systemctl status mongod
   ```

2. **Port Conflicts**
   - Check if ports 7777, 9999 are in use
   ```bash
   sudo netstat -tulpn | grep -E "(7777|9999)"
   ```

3. **Permission Issues**
   ```bash
   sudo chown -R root:root /etc/open5gs/
   sudo chmod -R 755 /etc/open5gs/
   ```

4. **Service Startup Order**
   - Services have dependencies; use the restart script:
   ```bash
   sudo /etc/open5gs/utils/restart-services.sh
   ```

## 📚 Directory Structure

```
/etc/open5gs/
├── amf.yaml              # AMF configuration
├── ausf.yaml             # AUSF configuration  
├── bsf.yaml              # BSF configuration
├── hss.yaml              # HSS configuration
├── mme.yaml              # MME configuration
├── nrf.yaml              # NRF configuration
├── nssf.yaml             # NSSF configuration
├── pcf.yaml              # PCF configuration
├── pcrf.yaml             # PCRF configuration
├── scp.yaml              # SCP configuration
├── sgwc.yaml             # SGWC configuration
├── sgwu.yaml             # SGWU configuration
├── smf.yaml              # SMF configuration
├── udm.yaml              # UDM configuration
├── udr.yaml              # UDR configuration
├── upf.yaml              # UPF configuration
├── backup/               # Configuration backups
│   └── backup_YYYYMMDD_HHMMSS/
└── utils/                # Utility scripts
    ├── create-tun-interfaces.sh
    ├── setup-iptables.sh
    └── restart-services.sh
```

## 🔒 Security Considerations

- All network functions use localhost IP addresses (127.0.0.x)
- Default authentication keys are used - change for production
- Firewall rules allow UE traffic through TUN interfaces
- MongoDB uses default configuration - secure for production use
- WebUI uses default credentials - change immediately

## 📈 Monitoring and Metrics

Open5GS provides Prometheus metrics endpoints:

- **AMF**: http://127.0.0.5:9090/metrics
- **SMF**: http://127.0.0.4:9090/metrics  
- **UPF**: http://127.0.0.7:9090/metrics
- **PCF**: http://127.0.0.13:9090/metrics
- **HSS**: http://127.0.0.8:9090/metrics

## 🤝 Contributing

Feel free to submit issues, feature requests, or pull requests to improve this installation script.

## 📄 License

This script is based on the Open5GS project and follows its licensing terms. See [Open5GS License](https://github.com/open5gs/open5gs/blob/main/LICENSE) for details.

## 🔗 References

- [Open5GS Official Documentation](https://open5gs.org/open5gs/docs/)
- [UERANSIM GitHub Repository](https://github.com/aligungr/UERANSIM)
- [3GPP 5G Standards](https://www.3gpp.org/specifications-technologies/specifications-by-series)
- [5G Core Network Architecture](https://www.3gpp.org/technologies/5g-system-overview)

## 📞 Support

For technical support:
1. Check the troubleshooting section above
2. Review Open5GS documentation
3. Check service logs for error messages
4. Verify network connectivity and configuration

---

**Last Updated**: September 22, 2025  
**Version**: 1.0  
**Author**: Rayhan Egar - Digital Hugs