# Open5GS Containerized Deployment

This directory contains a complete containerized deployment of Open5GS with individual containers for each Network Function (NF).

## 🏗️ Hybrid Architecture

This deployment uses a **hybrid architecture** combining containerized and native services:

### Containerized Components (Docker)
- All 5G Core Network Functions run as individual Docker containers
- Each NF has its own container with dedicated configuration
- Network Functions communicate over Docker bridge network (10.10.0.0/24)

### Native Components (Systemd Services)
- **MongoDB**: Runs as native systemd service (not containerized)
  - Better performance and reliability
  - Direct file system access
  - Standard backup/restore procedures
- **Open5GS WebUI**: Runs as native Node.js application
  - Easier access and management
  - No container overhead
  - Direct MongoDB connection

This hybrid approach provides: containerized NFs for easy deployment and scaling, while keeping database and management interface native for optimal performance.

## 📋 Architecture Overview

### Containerized 5G Core Network Functions

All NFs run as separate containers on a Docker bridge network (10.10.0.0/24) with static IP assignments:

### Containerized 5G Core Network Functions

All NFs run as separate containers on a Docker bridge network (10.10.0.0/24) with static IP assignments:

| Network Function | Container IP | Port(s) | Purpose |
|-----------------|--------------|---------|---------|
| **NRF** | 10.10.0.10 | 7777 | Network Repository Function - Service discovery |
| **SCP** | 10.10.0.200 | 7777 | Service Communication Proxy - SBI routing |
| **AUSF** | 10.10.0.11 | 7777 | Authentication Server Function |
| **UDM** | 10.10.0.12 | 7777 | Unified Data Management |
| **UDR** | 10.10.0.20 | 7777 | Unified Data Repository |
| **PCF** | 10.10.0.13 | 7777 | Policy Control Function |
| **BSF** | 10.10.0.15 | 7777 | Binding Support Function |
| **NSSF** | 10.10.0.14 | 7777 | Network Slice Selection Function |
| **AMF** | 10.10.0.5 | 7777, 38412 | Access and Mobility Management (N2/NGAP) |
| **SMF** | 10.10.0.4 | 7777, 8805 | Session Management Function |
| **UPF** | 10.10.0.7 | 2152, 2153 | User Plane Function - Data forwarding |

### Native Services (Non-Containerized)

| Service | Connection | Purpose |
|---------|------------|---------|
| **MongoDB** | localhost:27017 | Subscriber database (systemd service) |
| **Open5GS WebUI** | http://localhost:9999 | Web management interface (Node.js app) |

### Multi-DNN Network Slices

This deployment supports **3 Data Network Names (DNNs)** with separate TUN interfaces for different 5G network slices:

| Slice | SST | DNN | Subnet | Gateway | TUN Interface | Use Case |
|-------|-----|-----|--------|---------|---------------|----------|
| **eMBB** | 1 | embb.testbed | 10.45.0.0/24 | 10.45.0.1 | ogstun | Enhanced Mobile Broadband - High bandwidth |
| **URLLC** | 2 | urllc.v2x | 10.45.1.0/24 | 10.45.1.1 | ogstun2 | Ultra-Reliable Low Latency - V2X, critical comms |
| **mMTC** | 3 | mmtc.testbed | 10.45.2.0/24 | 10.45.2.1 | ogstun3 | Massive Machine Type - IoT devices, sensors |

**TUN Interface Location**: All three TUN interfaces (ogstun, ogstun2, ogstun3) are created **inside the UPF container** during startup, not on the host system.

### Network Architecture Diagram

```
Internet
    │
    ├── ogstun  (10.45.0.1/24) - eMBB traffic
    ├── ogstun2 (10.45.1.1/24) - URLLC traffic
    └── ogstun3 (10.45.2.1/24) - mMTC traffic
    
┌────────────────────────────────────────────────────┐
│  UPF Container (10.10.0.7)                         │
│  - TUN Interfaces created at startup               │
│  - NAT rules for each subnet                       │
└────────────────────────────────────────────────────┘
                      │
┌────────────────────────────────────────────────────┐
│  Docker Network (10.10.0.0/24)                     │
│                                                     │
│  SMF (10.10.0.4) ─── Manages all DNN sessions     │
│  AMF (10.10.0.5) ─── Handles gNB connections      │
│  NRF (10.10.0.10) ── Service discovery            │
│  SCP (10.10.0.200) ─ SBI routing                  │
│  ... other NFs ...                                 │
└────────────────────────────────────────────────────┘
                      │
┌────────────────────────────────────────────────────┐
│  Native Services (Host)                            │
│                                                     │
│  MongoDB (localhost:27017)                         │
│  Open5GS WebUI (localhost:9999)                    │
└────────────────────────────────────────────────────┘
```

## Port Mappings

### 5G Core Ports
| Service | Internal Port | External Port | Protocol | Description |
|---------|--------------|---------------|----------|-------------|
| AMF | 38412 | 38412 | SCTP | NGAP (N2 interface) |
| AMF | 7777 | 7705 | TCP | SBI interface |
| AMF | 9090 | 9005 | TCP | Metrics |
| SMF | 7777 | 7704 | TCP | SBI interface |
| SMF | 8805 | 8804 | UDP | PFCP (N4) |
| SMF | 2123 | 2123 | UDP | GTP-C |
| SMF | 9090 | 9004 | TCP | Metrics |
| UPF | 8805 | 8807 | UDP | PFCP (N4) |
| UPF | 2152 | 2152 | UDP | GTP-U (N3) |
| UPF | 2153 | 2153 | UDP | GTP-U (N3 alt) |
| UPF | 9090 | 9007 | TCP | Metrics |
| NRF | 7777 | 7710 | TCP | SBI interface |
| Other NFs | 7777 | 77xx | TCP | SBI interfaces |

## Prerequisites

### System Requirements
1. **Docker and Docker Compose** installed
2. **Ubuntu 20.04/22.04** or similar Linux distribution
3. **Root/sudo access** for network configuration
4. **SCTP kernel module** support
   ```bash
   # Verify SCTP is available
   lsmod | grep sctp
   # If not loaded, enable it
   sudo modprobe sctp
   ```

### Native Services (Required)
These services must be running **on the host** (not in containers):

#### 1. MongoDB Database
```bash
# Install MongoDB
sudo apt-get install mongodb

# Start MongoDB service
sudo systemctl start mongodb
sudo systemctl enable mongodb

# Verify it's running
sudo systemctl status mongodb
```

#### 2. Open5GS WebUI
```bash
# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Open5GS WebUI
git clone https://github.com/open5gs/open5gs.git
cd open5gs/webui
npm install
npm run build

# Start WebUI (will run on port 9999)
npm run start
```

**Access WebUI**: http://localhost:9999  
**Default Credentials**: admin / 1423

### Network Configuration Files
All NF configuration files are mounted from the host into containers. Refer to the YAML files in each NF directory (e.g., `amf/amf.yaml`, `smf/smf.yaml`).

For detailed configuration reference, see: `/home/rayhan/Open5GS-Testbed/open5gs/configs-reference/`

## Quick Start

### 1. Setup Host Network for gNB Connectivity

Right now, we are using EduVPN-based network connectivity that allows your gNB and UE to reach this core network thru EduVPN tunnel:

#### EduVPN Tunnel (Recommended for Remote Access)
```bash
# Configure EduVPN tunnel for remote gNB connections
cd /home/rayhan/Open5GS-Testbed/open5gs/open5gs-compose
sudo bash setup-host-network-eduvpn.sh

# Note the displayed tunnel IP (e.g., 10.147.18.x)
# Configure your gNB to connect to: <tunnel-ip>:38412
```

**When to use:** Remote gNB access through VPN, lab environment with distributed setup

**Important:** 
- These scripts configure Docker networking for AMF N2 interface exposure
- Run **only once** at system boot or after network changes
- To switch options, run a different script and restart containers with `docker compose restart`

### 2. Build and Start the Containers

```bash
# Navigate to the compose directory
cd /home/rayhan/Open5GS-Testbed/open5gs/open5gs-compose

# Build all container images
docker compose build

# Start all 5G Core NFs in the background
docker compose up -d

# Or start specific services
docker compose up -d nrf scp udr udm ausf pcf nssf amf smf upf
```

### 3. Verify Services

```bash
# Check if all containers are running
docker compose ps

# Expected output: All containers should show "Up" status
# Example:
# NAME           IMAGE          STATUS    PORTS
# nrf            open5gs-nrf    Up        0.0.0.0:7710->7777/tcp
# scp            open5gs-scp    Up        0.0.0.0:7720->7777/tcp
# amf            open5gs-amf    Up        0.0.0.0:38412->38412/sctp
# smf            open5gs-smf    Up        0.0.0.0:8804->8805/udp
# upf            open5gs-upf    Up        0.0.0.0:2152->2152/udp

# Tail logs for a service
docker compose logs -f amf
docker compose logs smf

# Verify NRF is responding (service discovery)
curl http://localhost:7710/nnrf-nfm/v1/nf-instances

# Check network connectivity between NFs
docker exec open5gs-amf ping -c 1 10.10.0.10  # Ping NRF from AMF
```

### 4. Verify Native Services

```bash
# Check MongoDB is running
sudo systemctl status mongodb
mongo --eval "db.runCommand({ connectionStatus: 1 })"

# Check WebUI is accessible
curl http://localhost:9999
# Or open in browser: http://localhost:9999
# Login: admin / 1423
```

### 5. Verify TUN Interfaces (Inside UPF Container)

```bash
# Check TUN interfaces inside UPF container
docker exec open5gs-upf ip addr show

# Expected output should include:
# ogstun: 10.45.0.1/24  - eMBB slice
# ogstun2: 10.45.1.1/24 - URLLC slice  
# ogstun3: 10.45.2.1/24 - mMTC slice

# Verify NAT rules for UE traffic forwarding
docker exec open5gs-upf iptables -t nat -L POSTROUTING -v
```

## Connecting External gNB

### Getting Your AMF IP Address

Depending on which host network setup you used:

```bash
# For EduVPN:
ip addr show tun0 | grep inet
# Example output: inet 10.147.18.25/24

# For Tailscale:
tailscale ip -4
# Example output: 100.64.15.42

# For Direct Ethernet (ICN):
ip addr show eth1 | grep inet
# Example output: inet 192.168.100.10/24
```

### Configure Your gNB

Use the appropriate IP from above in your gNB configuration:

#### srsRAN gNB Configuration
```yaml
# In gnb.conf or enb.conf
amf_addr = 10.147.18.25  # Your tunnel/interface IP
bind_addr =   # Your gNB's IP

# N2 (NGAP) parameters
n2_bind_addr = 10.34.4.245
n2_bind_port = 38412
```

#### UERANSIM gNB Configuration
```yaml
# In config/open5gs-gnb.yaml
mcc: '001'
mnc: '01'
nci: '0x000000010'
idLength: 32
tac: 1

linkIp: 10.34.4.245   # gNB's IP address
ngapIp: 10.34.4.245   # gNB's N2 interface IP
gtpIp: 10.34.4.245    # gNB's N3 interface IP

# AMF Configuration
amfConfigs:
  - address: 10.147.18.25  # Your tunnel/interface IP from above
    port: 38412

# Supported S-NSSAIs
slices:
  - sst: 1     # eMBB slice
    sd: 0x000001
  - sst: 2     # URLLC slice
    sd: 0x000002
  - sst: 3     # mMTC slice
    sd: 0x000003
```

### Testing gNB Connection

```bash
# From gNB machine, verify AMF is reachable
ping -c 3 10.147.18.25  # Use your AMF IP

# Check if SCTP port 38412 is open
nc -zv 10.147.18.25 38412

# Start your gNB and monitor AMF logs
docker compose logs -f amf

# Successful connection shows:
# [amf] INFO: gNB-N2 accepted[10.34.4.245]:43210
# [amf] INFO: [Added] Number of gNBs is now 1
```

## Managing Subscribers

### Option 1: Using Open5GS WebUI (Recommended)

1. **Access WebUI**: http://localhost:9999
2. **Login**: admin / 1423
3. **Add Subscriber**:
   - IMSI: 001010000000001 (increment for more UEs)
   - K: 465B5CE8B199B49FAA5F0A2EE238A6BC
   - OPc: E8ED289DEBA952E4283B54E88E6183CA
   - **Select Slice**: Choose DNN based on use case
     - `embb.testbed` (SST:1) - High bandwidth
     - `urllc.v2x` (SST:2) - Low latency V2X
     - `mmtc.testbed` (SST:3) - IoT devices

### Option 2: Using MongoDB CLI

```bash
# Connect to native MongoDB
mongo

# Switch to open5gs database
use open5gs

# View all subscribers
db.subscribers.find().pretty()

# Add subscriber with specific DNN/slice
db.subscribers.insert({
  "imsi": "001010000000001",
  "security": {
    "k": "465B5CE8B199B49FAA5F0A2EE238A6BC",
    "opc": "E8ED289DEBA952E4283B54E88E6183CA",
    "amf": "8000"
  },
  "slice": [
    {
      "sst": 1,
      "default_indicator": true,
      "session": [
        {
          "name": "embb.testbed",
          "type": 3,  # IPv4
          "ambr": {
            "downlink": {"value": 1, "unit": 3},  # 1 Gbps
            "uplink": {"value": 1, "unit": 3}     # 1 Gbps
          }
        }
      ]
    }
  ]
})

# Delete a subscriber
db.subscribers.deleteOne({"imsi": "001010000000001"})

# Exit MongoDB
exit
```

### DNN Selection for UE Configuration

When configuring UEs (e.g., UERANSIM), specify the appropriate DNN:

```yaml
# In UERANSIM ue-config.yaml
sessions:
  - type: 'IPv4'
    apn: 'embb.testbed'    # For high bandwidth applications
    slice:
      sst: 1
      sd: 0x000001

# OR for URLLC slice:
  - type: 'IPv4'
    apn: 'urllc.v2x'       # For low-latency V2X
    slice:
      sst: 2
      sd: 0x000002

# OR for mMTC slice:
  - type: 'IPv4'
    apn: 'mmtc.testbed'    # For IoT devices
    slice:
      sst: 3
      sd: 0x000003
```

## Configuration Management

### Modifying NF Configurations

All NF configuration files are in their respective directories:

```bash
# Edit SMF configuration (DNN/UPF associations)
nano smf/smf.yaml

# Edit AMF configuration (PLMN, TAC, slices)
nano amf/amf.yaml

# Edit UPF configuration (subnets, DNS)
nano upf/upf.yaml
```

**Reference Configurations**: For detailed configuration examples, refer to:
```
/home/rayhan/Open5GS-Testbed/open5gs/configs-reference/
```

### Applying Configuration Changes

```bash
# Restart specific NF after config changes
docker compose restart smf
docker compose restart amf

# Or restart all services
docker compose restart

# Rebuild if Dockerfile changed
docker compose build <service-name>
docker compose up -d <service-name>
```

### Viewing Live Logs

```bash
# Follow logs for specific NF
docker compose logs -f smf
docker compose logs -f amf upf  # Multiple services

# View last 100 lines
docker compose logs --tail=100 smf

# Show timestamps
docker compose logs -f -t amf
```

## Troubleshooting

### Service Health Checks

```bash
# Check container status
docker compose ps

# Verify all NFs are running
docker ps --filter "name=open5gs-*" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check resource usage
docker stats --no-stream

# Restart specific NF
docker compose restart amf
docker compose restart upf
```

### Common Issues

#### 1. SCTP Connection Failed (gNB can't connect to AMF)

**Symptoms**: gNB logs show "SCTP connection failed" or AMF shows no gNB registration

**Solutions**:
```bash
# Ensure SCTP kernel module is loaded
lsmod | grep sctp
# If not loaded:
sudo modprobe sctp
sudo echo "sctp" >> /etc/modules  # Persist across reboots

# Verify AMF NGAP port is listening
sudo netstat -tlnp | grep 38412
# Should show: tcp 0.0.0.0:38412 LISTEN

# Check firewall rules
sudo iptables -L -n | grep 38412
# Add rule if blocked:
sudo iptables -A INPUT -p sctp --dport 38412 -j ACCEPT

# Verify host network script was run
# Re-run the appropriate setup script:
sudo bash setup-host-network-eduvpn.sh
```

#### 2. UPF TUN Interfaces Not Created

**Symptoms**: UE registration succeeds but PDU session fails, no data connectivity

**Solutions**:
```bash
# Check TUN interfaces inside UPF container
docker exec open5gs-upf ip addr show

# Expected output should include:
# ogstun: 10.45.0.1/24
# ogstun2: 10.45.1.1/24  
# ogstun3: 10.45.2.1/24

# If missing, check UPF logs
docker compose logs upf | grep -i "tun"

# Verify UPF has NET_ADMIN capability (required for TUN creation)
docker inspect open5gs-upf | grep -i "NET_ADMIN"
# Should show: "NET_ADMIN"

# Restart UPF to recreate interfaces
docker compose restart upf
docker compose logs -f upf  # Watch for TUN creation messages
```

#### 3. MongoDB Connection Issues

**Symptoms**: WebUI can't load subscribers, NFs log "Failed to connect to database"

**Solutions**:
```bash
# Verify MongoDB is running natively (not in container)
sudo systemctl status mongodb

# Test MongoDB connection
mongo --eval "db.runCommand({ connectionStatus: 1 })"

# If not running:
sudo systemctl start mongodb
sudo systemctl enable mongodb

# Check MongoDB logs
sudo journalctl -u mongodb -n 50

# Verify MongoDB is listening on correct port
sudo netstat -tlnp | grep 27017
# Should show: 127.0.0.1:27017

# Test from container (should reach host MongoDB)
docker exec open5gs-smf nc -zv host.docker.internal 27017
```

#### 4. Port Already in Use

**Symptoms**: `docker compose up` fails with "bind: address already in use"

**Solutions**:
```bash
# Check which process is using the port
sudo netstat -tlnp | grep 38412
sudo lsof -i :38412

# Kill the conflicting process
sudo kill -9 <PID>

# Or change port mapping in docker-compose.yml
# Edit ports section for the conflicting service

# Verify no old containers are running
docker ps -a | grep open5gs
docker rm -f $(docker ps -aq --filter "name=open5gs-")
```

#### 5. gNB Connected but UE Can't Register

**Symptoms**: gNB shows "Connected to AMF" but UE registration fails

**Solutions**:
```bash
# Check if subscriber exists in MongoDB
mongo
use open5gs
db.subscribers.find({"imsi": "001010000000001"}).pretty()

# Verify PLMN matches (MCC/MNC)
# UE IMSI: 001-01-0000000001
#          MCC-MNC-MSIN
# AMF should accept MCC=001, MNC=01

# Check AMF logs for reject cause
docker compose logs amf | grep -i "reject"

# Common reject causes:
# - PLMN not allowed: Check amf.yaml plmn_support section
# - Slice not supported: Check amf.yaml s_nssai section
# - Authentication failure: Verify K/OPc in MongoDB

# View AMF configuration
docker exec open5gs-amf cat /etc/open5gs/amf.yaml | grep -A 10 "plmn_support"
```

#### 6. UE Registered but No Internet Connectivity

**Symptoms**: UE gets IP address but can't ping external IPs

**Solutions**:
```bash
# Check UPF NAT rules
docker exec open5gs-upf iptables -t nat -L POSTROUTING -v
# Should show MASQUERADE rules for 10.45.0.0/24, 10.45.1.0/24, 10.45.2.0/24

# Verify IP forwarding is enabled in UPF container
docker exec open5gs-upf sysctl net.ipv4.ip_forward
# Should show: net.ipv4.ip_forward = 1

# Test connectivity from UPF container
docker exec open5gs-upf ping -c 3 8.8.8.8

# Check DNS configuration in UPF
docker exec open5gs-upf cat /etc/open5gs/upf.yaml | grep -A 5 "dns"

# Verify UE is getting correct DNS servers
# UPF should advertise: 8.8.8.8, 8.8.4.4 (configured in smf.yaml)
```

### Network Diagnostics

```bash
# Test NF connectivity within Docker network
docker exec open5gs-amf ping -c 1 10.10.0.10  # AMF -> NRF
docker exec open5gs-smf ping -c 1 10.10.0.7   # SMF -> UPF

# Check NRF service discovery
curl http://localhost:7710/nnrf-nfm/v1/nf-instances | jq

# Verify AMF SBI interface
curl http://localhost:7705/namf-comm/v1/ue-contexts

# Check SMF N4 (PFCP) connectivity to UPF
docker exec open5gs-smf cat /etc/open5gs/smf.yaml | grep -A 5 "upf:"

# Monitor GTP-U traffic (N3 interface)
docker exec open5gs-upf tcpdump -i any -n port 2152
```

### Performance Monitoring

```bash
# Check container resource usage
docker stats

# View per-NF metrics (if metrics enabled)
curl http://localhost:9005/metrics  # AMF metrics
curl http://localhost:9004/metrics  # SMF metrics
curl http://localhost:9007/metrics  # UPF metrics

# Monitor database connections
mongo
use admin
db.currentOp()
```

## Advanced Topics

### Custom YAML Configurations

Each NF configuration can be customized by editing YAML files in their directories:

```bash
# Edit AMF configuration
$EDITOR amf/amf.yaml

# Restart AMF to apply changes
docker compose restart amf
```

### Scaling Services

Some services can be scaled horizontally:

```bash
# Scale UPF instances (requires load balancing configuration)
docker compose up -d --scale upf=2
```

### Enable/Disable 4G Support

To disable 4G/EPC components, comment out the following services in docker-compose.yml:
### Adding Additional Network Slices

To add a new network slice with its own DNN:

1. **Update SMF configuration** (`smf/smf.yaml`):
```yaml
info:
  - subnet: 10.45.3.0/24  # New subnet for new slice
    gateway: 10.45.3.1
    dnn: custom.slice      # New DNN name
```

2. **Update UPF startup script** (`upf/startup.sh`):
```bash
# Add new TUN interface
ip tuntap add name ogstun4 mode tun
ip addr add 10.45.3.1/24 dev ogstun4
ip link set ogstun4 up
iptables -t nat -A POSTROUTING -s 10.45.3.0/24 -j MASQUERADE
```

3. **Update AMF configuration** (`amf/amf.yaml`):
```yaml
plmn_support:
  - plmn_id:
      mcc: 001
      mnc: 01
    s_nssai:
      - sst: 4  # New slice
        sd: 0x000004
        dnn: custom.slice
```

4. **Rebuild and restart**:
```bash
docker compose build upf
docker compose restart amf smf upf
```

### Scaling Considerations

For high-throughput or multi-cell deployments:

```yaml
# In docker-compose.yml, you can deploy multiple UPF instances
services:
  upf1:
    # Configuration for UPF serving cell 1
    networks:
      open5gs_net:
        ipv4_address: 10.10.0.7
  
  upf2:
    # Configuration for UPF serving cell 2  
    networks:
      open5gs_net:
        ipv4_address: 10.10.0.17

# Update SMF to load-balance across UPFs
```

### Enabling 4G/EPC Support

To enable legacy 4G support alongside 5G:

```bash
# Uncomment 4G NFs in docker-compose.yml
docker compose up -d hss mme sgwc sgwu pcrf

# 4G NFs:
# - HSS: Home Subscriber Server (10.10.0.8)
# - MME: Mobility Management Entity (10.10.0.2)  
# - SGW-C: Serving Gateway Control (10.10.0.3)
# - SGW-U: Serving Gateway User Plane (10.10.0.6)
# - PCRF: Policy and Charging Rules (10.10.0.9)
```

## Additional Resources

### Reference Documentation
- **Open5GS Official Docs**: https://open5gs.org/open5gs/docs/
- **3GPP 5G Specs**: https://www.3gpp.org/DynaReport/38-series.htm
- **Docker Compose Reference**: https://docs.docker.com/compose/compose-file/

### Related Deployment Methods
- **Native Installation**: `/home/rayhan/Open5GS-Testbed/open5gs/Open5GS Setup and Configuration.md`
- **Kubernetes (K3s)**: `/home/rayhan/Open5GS-Testbed/open5gs/open5gs-k3s-calico/README.md`
- **Configuration References**: `/home/rayhan/Open5GS-Testbed/open5gs/configs-reference/`

### Useful Commands Quick Reference

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f amf smf upf

# Restart after config changes  
docker compose restart <service>

# Check service status
docker compose ps

# Access native MongoDB
mongo

# Stop all services
docker compose down

# View network details
docker network inspect open5gs-compose_open5gs_net

# Execute command in container
docker exec -it open5gs-amf bash
```

## Cleanup

```bash
# Stop all containers (preserves configurations)
docker compose down

# Stop containers and remove all data
docker compose down -v

# Remove all built images
docker compose down --rmi all

# Complete cleanup (containers, images, networks)
docker compose down -v --rmi all
docker network prune -f
docker volume prune -f
```

## Security Notes

⚠️ **This is a testbed deployment - NOT production-ready!**

1. **MongoDB Security**:
   - Running natively without authentication enabled
   - For production: Enable MongoDB authentication and use strong passwords
   - Consider running MongoDB with TLS/SSL

2. **Default Credentials**:
   - WebUI: admin / 1423 (should be changed)
   - Subscriber K/OPc keys are example values (use unique keys per subscriber)

3. **Network Isolation**:
   - All NFs communicate on unencrypted SBI (Service Based Interface)
   - For production: Implement TLS for all NF-to-NF communication
   - Consider network segmentation and firewall rules

4. **Host Network Exposure**:
   - AMF N2 interface exposed on host for gNB connectivity
   - UPF N3 interface exposed for user plane traffic
   - Ensure proper firewall rules: `sudo ufw allow 38412/sctp` (AMF), `sudo ufw allow 2152/udp` (UPF)

5. **Container Privileges**:
   - UPF runs with `NET_ADMIN` capability for TUN device creation
   - Necessary for 5G operation but increases attack surface

6. **Production Recommendations**:
   - Use certificate-based authentication between NFs
   - Implement IPsec for N3 (gNB-UPF) interface
   - Enable SELinux/AppArmor for container isolation
   - Use secrets management (e.g., Docker Secrets, HashiCorp Vault)
   - Monitor and log all NF activities

## Support and Troubleshooting

### Getting Help

1. **Documentation**:
   - Open5GS Official: https://open5gs.org/open5gs/docs/
   - Docker Compose Reference: https://docs.docker.com/compose/

2. **Check Logs**:
   ```bash
   # View specific NF logs
   docker compose logs -f amf
   
   # Check all NF logs with timestamps
   docker compose logs -t | grep -i error
   ```

3. **Verify Configuration**:
   ```bash
   # Run the validation script
   bash validate-config.sh
   
   # Check Docker network
   docker network inspect open5gs-compose_open5gs_net
   ```

4. **Network Diagnostics**:
   ```bash
   # Test NF connectivity
   docker exec open5gs-amf ping -c 1 10.10.0.10  # AMF -> NRF
   
   # Check NRF service registry
   curl http://localhost:7710/nnrf-nfm/v1/nf-instances | jq
   ```

### Filing Issues

When reporting problems, include:
- Output of `docker compose ps`
- Relevant logs: `docker compose logs <service> > logs.txt`
- Configuration files (sanitize sensitive data)
- gNB/UE logs if connectivity issue
- Network setup script used (EduVPN/Tailscale/Ethernet)

---

## Summary

This Docker Compose deployment provides a **hybrid architecture** 5G testbed:

✅ **Containerized**: All 5G Core Network Functions (AMF, SMF, UPF, NRF, etc.)  
✅ **Native**: MongoDB database and Open5GS WebUI for flexibility  
✅ **Multi-Slice**: 3 network slices (eMBB, URLLC, mMTC) with separate DNNs  
✅ **Flexible Connectivity**: EduVPN/Tailscale/Ethernet options for gNB access  
✅ **TUN Interfaces**: Created inside UPF container for each DNN

**Perfect for**: 5G research, protocol testing, student labs, and network slice experimentation

**Not suitable for**: Production deployments (see Security Notes above)