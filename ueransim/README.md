# UERANSIM - Open5GS Testbed

UERANSIM is an open-source 5G UE (User Equipment) and RAN (Radio Access Network) simulator that provides gNB (5G base station) and UE functionality for testing 5G Core networks.

## 📁 Directory Structure

```
ueransim/
├── build/               # Pre-compiled UERANSIM binaries
│   ├── nr-gnb          # gNB (base station) simulator
│   ├── nr-ue           # UE (user equipment) simulator
│   ├── nr-cli          # Command-line interface for runtime control
│   └── nr-binder       # Network namespace binding utility
├── configs/             # Configuration files
│   ├── open5gs-gnb-local.yaml    # gNB configuration
│   └── open5gs-ue-embb.yaml      # UE configuration (eMBB slice)
└── README.md           # This file
```

---

## 🔧 UERANSIM Binaries

### 1. `nr-gnb` - gNB Simulator

**Purpose**: Simulates a 5G base station (gNodeB) that connects to the Open5GS AMF via N2 interface and forwards user plane traffic to UPF via N3 interface.

**Usage**:
```bash
./build/nr-gnb -c configs/open5gs-gnb-local.yaml
```

**What it does**:
- Establishes SCTP connection to AMF on N2 interface (NGAP protocol)
- Manages UE registrations and handovers
- Forwards GTP-U tunneled user plane traffic to UPF (N3 interface)
- Supports multiple network slices (eMBB, URLLC, mMTC)

**Expected Output**:
```
[2025-10-28 10:00:00.000] [sctp] [info] Trying to establish SCTP connection... (127.0.0.5:38412)
[2025-10-28 10:00:00.100] [sctp] [info] SCTP connection established
[2025-10-28 10:00:00.150] [ngap] [info] NG Setup procedure is successful
```

**Common Options**:
```bash
# Run with specific config
./build/nr-gnb -c configs/open5gs-gnb-local.yaml

# Run in foreground with logs
./build/nr-gnb -c configs/open5gs-gnb-local.yaml 2>&1 | tee gnb.log
```

### 2. `nr-ue` - UE Simulator

**Purpose**: Simulates 5G user equipment (smartphone/device) that connects to the gNB and establishes PDU sessions to access data networks.

**Usage**:
```bash
./build/nr-ue -c configs/open5gs-ue-embb.yaml
```

**What it does**:
- Performs 5G NAS registration with AMF (authentication, security)
- Establishes PDU sessions with configured DNNs
- Creates `uesimtun0` TUN interface for data connectivity
- Supports multiple network slices per UE

**Expected Output**:
```
[2025-10-28 10:00:01.000] [nas] [info] UE switches to state [MM-DEREGISTERED/PLMN-SEARCH]
[2025-10-28 10:00:01.100] [nas] [info] UE switches to state [MM-DEREGISTERED/NORMAL-SERVICE]
[2025-10-28 10:00:01.200] [nas] [info] UE switches to state [MM-REGISTERED/NORMAL-SERVICE]
[2025-10-28 10:00:01.300] [nas] [info] PDU Session establishment is successful PSI[1]
[2025-10-28 10:00:01.350] [app] [info] Connection setup for PDU session[1] is successful, TUN interface[uesimtun0, 10.45.0.2] is up.
```

**TUN Interface**: The UE creates a virtual network interface (`uesimtun0`) that can be used like a real network interface for testing.

### 3. `nr-cli` - Command-Line Interface

**Purpose**: Interactive CLI for runtime control and monitoring of running gNB/UE instances.

**Usage**:
```bash
# Connect to gNB
./build/nr-cli imsi-001010000000001

# Or connect to UE
./build/nr-cli UERANSIM-gnb-001-01-1
```

**Common Commands**:
```bash
# Check UE status
status

# List active PDU sessions
ps-list

# Establish new PDU session
ps-establish <slice-sst> <dnn>

# Release PDU session
ps-release <psi>

# Send test data
ping <destination-ip>

# Exit CLI
quit
```

### 4. `nr-binder` - Network Namespace Binder

**Purpose**: Binds applications to use specific UE's TUN interface for testing network slice isolation.

**Usage**:
```bash
# Run command using UE's network interface
./build/nr-binder 10.45.0.2 <command>

# Example: Ping using UE interface
./build/nr-binder 10.45.0.2 ping 8.8.8.8

# Example: Run curl using UE interface
./build/nr-binder 10.45.0.2 curl http://example.com
```

**Why it's useful**: Ensures traffic goes through the 5G network (gNB → UPF → Internet) rather than the host's default interface.

---

## ⚙️ Configuration Files

### 1. gNB Configuration (`open5gs-gnb-local.yaml`)

#### Key Parameters to Modify

| Parameter | Description | Example Values |
|-----------|-------------|----------------|
| `mcc` | Mobile Country Code | `'001'` (test network) |
| `mnc` | Mobile Network Code | `'01'` |
| `nci` | NR Cell Identity (36-bit hex) | `'0x000000010'` |
| `tac` | Tracking Area Code | `1` |
| `linkIp` | gNB's local IP for radio simulation | `127.0.0.1` (local), `10.34.4.130` (remote) |
| `ngapIp` | gNB's IP for N2 (NGAP) to AMF | `127.0.0.1` (local), `10.34.4.130` (remote) |
| `gtpIp` | gNB's IP for N3 (GTP-U) to UPF | `127.0.0.1` (local), `10.34.4.130` (remote) |
| `gtpAdvertiseIp` | Public IP advertised to UPF | `10.34.4.130` (if behind NAT) |
| `amfConfigs[].address` | AMF IP address | `127.0.0.5` (native), `10.10.0.5` (docker), `10.147.18.25` (VPN) |
| `amfConfigs[].port` | AMF NGAP port | `38412` |
| `slices[]` | Supported network slices | SST 1 (eMBB), SST 2 (URLLC), SST 3 (mMTC) |

#### Deployment-Specific Configuration

##### **Scenario 1: Local Testing (gNB on same host as Open5GS)**

```yaml
linkIp: 127.0.0.1
ngapIp: 127.0.0.1
gtpIp: 127.0.0.1

amfConfigs:
  # For native Open5GS deployment
  - address: 127.0.0.5
    port: 38412
  
  # OR for Docker Compose deployment
  # - address: 10.10.0.5
  #   port: 38412
```

##### **Scenario 2: Remote gNB (Different Machine)**

```yaml
linkIp: 10.34.4.130      # gNB machine's IP
ngapIp: 10.34.4.130      # gNB machine's IP
gtpIp: 10.34.4.130       # gNB machine's IP
gtpAdvertiseIp: 10.34.4.130  # If gNB behind NAT

amfConfigs:
  # Open5GS host IP (EduVPN/Tailscale/Direct)
  - address: 10.147.18.25  # Use tunnel/interface IP from setup script
    port: 38412
```

##### **Scenario 3: Kubernetes (K3s) Deployment**

```yaml
linkIp: 10.34.4.130      # gNB machine's IP
ngapIp: 10.34.4.130      # gNB machine's IP
gtpIp: 10.34.4.130       # gNB machine's IP

amfConfigs:
  - address: 10.10.0.5   # AMF static IP in K3s
    port: 38412
```

#### Network Slice Configuration

Add or remove slices based on your subscribers:

```yaml
slices:
  - sst: 1               # eMBB slice (high bandwidth)
    # sd: 0x000001       # Optional Slice Differentiator
  - sst: 2               # URLLC slice (low latency)
  - sst: 3               # mMTC slice (IoT)
```

**Note**: The `dnn` field is commented out in gNB config - DNNs are specified in UE config.

---

### 2. UE Configuration (`open5gs-ue-embb.yaml`)

#### Key Parameters to Modify

| Parameter | Description | Example Values |
|-----------|-------------|----------------|
| `supi` | IMSI (must match subscriber in MongoDB) | `'imsi-001010000000001'` |
| `mcc` | Mobile Country Code | `'001'` |
| `mnc` | Mobile Network Code | `'01'` |
| `key` | Permanent subscription key (K) | Must match WebUI/MongoDB |
| `op` | Operator code (OPc) | Must match WebUI/MongoDB |
| `opType` | OP type | `'OPC'` or `'OP'` |
| `gnbSearchList[]` | List of gNB IPs to connect to | `127.0.0.1`, `10.34.4.130` |
| `sessions[]` | PDU sessions to establish | Multiple allowed |
| `sessions[].apn` | Data Network Name (DNN) | `embb.testbed`, `urllc.v2x`, `mmtc.testbed` |
| `sessions[].slice.sst` | Slice type | `1` (eMBB), `2` (URLLC), `3` (mMTC) |
| `configured-nssai[]` | Configured slices | Must match gNB and AMF |

#### Matching Subscriber Credentials

**CRITICAL**: UE credentials must match the subscriber added in Open5GS WebUI or MongoDB.

Example subscriber in WebUI:
- **IMSI**: `001010000000001`
- **K**: `465B5CE8B199B49FAA5F0A2EE238A6BC`
- **OPc**: `E8ED289DEBA952E4283B54E88E6183CA`
- **AMF**: `8000`

Corresponding UE config:
```yaml
supi: 'imsi-001010000000001'
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
op: 'E8ED289DEBA952E4283B54E88E6183CA'
opType: 'OPC'
amf: '8000'
```

#### Connecting to Remote gNB

```yaml
gnbSearchList:
  - 10.34.4.130    # Remote gNB IP
  # - 127.0.0.1    # Local fallback
```

#### Multiple PDU Sessions (Multi-Slice UE)

```yaml
sessions:
  # Primary session: eMBB for general internet
  - type: 'IPv4'
    apn: 'embb.testbed'
    slice:
      sst: 1
      sd: 0x000001
  
  # Secondary session: URLLC for low-latency V2X
  - type: 'IPv4'
    apn: 'urllc.v2x'
    slice:
      sst: 2
      sd: 0x000002

configured-nssai:
  - sst: 1
  - sst: 2

default-nssai:
  - sst: 1  # Use eMBB by default
```

This creates two TUN interfaces: `uesimtun0` (eMBB) and `uesimtun1` (URLLC).

---

## 🚀 Step-by-Step Usage Guide

### Prerequisites

Before running UERANSIM, ensure:

1. **Open5GS is running** (choose one):
   ```bash
   # Native deployment
   sudo systemctl status open5gs-amfd
   sudo systemctl status open5gs-upfd
   
   # Docker Compose
   cd /home/rayhan/Open5GS-Testbed/open5gs/open5gs-compose
   docker compose ps
   
   # K3s
   kubectl get pods -n open5gs
   ```

2. **Subscriber exists in MongoDB/WebUI**:
   ```bash
   # Access WebUI: http://localhost:9999
   # Login: admin / 1423
   # Add subscriber with IMSI: 001010000000001
   ```

3. **SCTP module loaded** (for gNB):
   ```bash
   lsmod | grep sctp
   # If not loaded:
   sudo modprobe sctp
   ```

---

### Step 1: Start gNB

Open a terminal and navigate to UERANSIM directory:

```bash
cd /home/rayhan/Open5GS-Testbed/ueransim

# Run gNB with configuration
./build/nr-gnb -c configs/open5gs-gnb-local.yaml
```

**Expected Success Output**:
```
[2025-10-28 10:00:00.000] [sctp] [info] Trying to establish SCTP connection... (127.0.0.5:38412)
[2025-10-28 10:00:00.100] [sctp] [info] SCTP connection established
[2025-10-28 10:00:00.150] [ngap] [info] NG Setup procedure is successful
```

**Troubleshooting**:
- **"Connection refused"**: Check AMF is running and IP/port are correct
- **"SCTP not available"**: Run `sudo modprobe sctp`
- **"NG Setup failed"**: Verify PLMN (MCC/MNC) matches AMF configuration

**Leave this terminal running** and open a new terminal for UE.

---

### Step 2: Start UE

In a **new terminal**:

```bash
cd /home/rayhan/Open5GS-Testbed/ueransim

# Run UE with configuration
./build/nr-ue -c configs/open5gs-ue-embb.yaml
```

**Expected Success Output**:
```
[2025-10-28 10:00:01.000] [nas] [info] UE switches to state [MM-DEREGISTERED/PLMN-SEARCH]
[2025-10-28 10:00:01.100] [rrc] [info] Selected cell plmn[001/01] tac[1] category[SUITABLE]
[2025-10-28 10:00:01.200] [nas] [info] UE switches to state [MM-REGISTERED/NORMAL-SERVICE]
[2025-10-28 10:00:01.300] [nas] [info] PDU Session establishment is successful PSI[1]
[2025-10-28 10:00:01.350] [app] [info] Connection setup for PDU session[1] is successful, TUN interface[uesimtun0, 10.45.0.2] is up.
```

**Key Information**:
- **Registration State**: Should be `MM-REGISTERED/NORMAL-SERVICE`
- **PDU Session**: Successfully established
- **TUN Interface**: `uesimtun0` with IP `10.45.0.2` (eMBB subnet)

**Troubleshooting**:
- **"gNB not found"**: Check gNB is running and IP in `gnbSearchList` is correct
- **"Authentication failure"**: K/OPc mismatch - verify subscriber credentials
- **"PDU Session rejected"**: DNN not configured in SMF or subscriber doesn't have slice permission

---

### Step 3: Verify TUN Interface

In a **new terminal**, check the created TUN interface:

```bash
# List network interfaces
ip addr show uesimtun0

# Expected output:
# uesimtun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
#     link/none 
#     inet 10.45.0.2/24 scope global uesimtun0
#        valid_lft forever preferred_lft forever

# Check routing table
ip route | grep uesimtun0
# Expected: 10.45.0.0/24 dev uesimtun0 proto kernel scope link src 10.45.0.2
```

**Understanding the Output**:
- **Interface Name**: `uesimtun0` (first PDU session)
- **IP Address**: `10.45.0.2/24` (from eMBB subnet `10.45.0.0/24`)
- **Gateway**: `10.45.0.1` (UPF's ogstun interface)
- **State**: `UP` and `UNKNOWN` is normal for TUN devices

---

## 🧪 Basic Network Testing

### Test 1: Ping Gateway (UPF TUN Interface)

```bash
# Ping the UPF gateway
ping -I uesimtun0 -c 4 10.45.0.1
```

**Expected Output**:
```
PING 10.45.0.1 (10.45.0.1) from 10.45.0.2 uesimtun0: 56(84) bytes of data.
64 bytes from 10.45.0.1: icmp_seq=1 ttl=64 time=15.2 ms
64 bytes from 10.45.0.1: icmp_seq=2 ttl=64 time=12.8 ms
64 bytes from 10.45.0.1: icmp_seq=3 ttl=64 time=14.1 ms
64 bytes from 10.45.0.1: icmp_seq=4 ttl=64 time=13.5 ms
```

**What this tests**: UE → gNB → UPF connectivity (N3 interface)

---

### Test 2: Ping External DNS Server

```bash
# Ping Google DNS
ping -I uesimtun0 -c 4 8.8.8.8
```

**Expected Output**:
```
PING 8.8.8.8 (8.8.8.8) from 10.45.0.2 uesimtun0: 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=25.3 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=118 time=23.7 ms
```

**What this tests**: Full end-to-end connectivity (UE → gNB → UPF → Internet)

**Troubleshooting if fails**:
```bash
# Check UPF NAT rules
# For Docker Compose:
docker exec open5gs-upf iptables -t nat -L POSTROUTING -v

# For Native:
sudo iptables -t nat -L POSTROUTING -v | grep 10.45.0.0

# For K3s:
kubectl exec -n open5gs deploy/upf -- iptables -t nat -L POSTROUTING -v
```

---

### Test 3: DNS Resolution

```bash
# Test DNS resolution
nslookup -type=A google.com 8.8.8.8

# Or using dig
dig @8.8.8.8 google.com +short
```

**What this tests**: DNS functionality through the 5G network

---

### Test 4: HTTP/HTTPS Traffic

```bash
# HTTP request using curl
curl --interface uesimtun0 http://example.com

# HTTPS request
curl --interface uesimtun0 https://www.google.com

# Download speed test
curl --interface uesimtun0 -o /dev/null http://speedtest.tele2.net/10MB.zip
```

**What this tests**: Application-layer connectivity and throughput

---

### Test 5: Using nr-binder for Traffic

The `nr-binder` utility ensures all traffic from a command goes through the UE interface:

```bash
# Ping using nr-binder
./build/nr-binder 10.45.0.2 ping -c 4 8.8.8.8

# Traceroute to see path
./build/nr-binder 10.45.0.2 traceroute 8.8.8.8

# Run iperf3 client for throughput test
./build/nr-binder 10.45.0.2 iperf3 -c <iperf-server-ip> -t 10

# Run wget download test
./build/nr-binder 10.45.0.2 wget http://speedtest.tele2.net/100MB.zip
```

**Why use nr-binder?**: Some applications ignore the `-I` flag. `nr-binder` forces them to use the UE's network namespace.

---

### Test 6: Throughput Testing with iperf3

**Setup iperf3 server** (on a machine accessible via internet):
```bash
# On server machine
iperf3 -s
```

**Run iperf3 client from UE**:
```bash
# TCP throughput test (10 seconds)
./build/nr-binder 10.45.0.2 iperf3 -c <server-ip> -t 10

# UDP throughput test with 100 Mbps target
./build/nr-binder 10.45.0.2 iperf3 -c <server-ip> -u -b 100M -t 10

# Reverse mode (server sends to client)
./build/nr-binder 10.45.0.2 iperf3 -c <server-ip> -R -t 10
```

**Expected Results**:
- **Local deployment**: 500+ Mbps
- **Remote deployment**: Depends on network latency and VPN overhead

---

### Test 7: Network Slice Testing (Multi-DNN)

If you configured multiple PDU sessions (e.g., eMBB + URLLC):

```bash
# Check all TUN interfaces
ip addr show | grep uesimtun

# uesimtun0: 10.45.0.2 (eMBB - embb.testbed)
# uesimtun1: 10.45.1.2 (URLLC - urllc.v2x)

# Test eMBB slice (high bandwidth)
ping -I uesimtun0 -c 4 8.8.8.8

# Test URLLC slice (low latency)
ping -I uesimtun1 -c 4 8.8.8.8

# Compare latencies
ping -I uesimtun0 -c 20 8.8.8.8 | tail -1  # eMBB average
ping -I uesimtun1 -c 20 8.8.8.8 | tail -1  # URLLC average (should be lower)
```

**Monitoring Slice QoS**:
```bash
# Monitor traffic on each interface
# Terminal 1: eMBB
sudo tcpdump -i uesimtun0 -n

# Terminal 2: URLLC
sudo tcpdump -i uesimtun1 -n
```

---

### Test 8: Interactive CLI Testing

Use `nr-cli` to control UE at runtime:

```bash
# Connect to running UE
./build/nr-cli imsi-001010000000001

# Inside CLI:
# Check UE status
status

# List PDU sessions
ps-list

# Establish new PDU session for URLLC
ps-establish 2 urllc.v2x

# Release a PDU session
ps-release 2

# Check connection info
info

# Exit
quit
```

---

## 📊 Monitoring and Debugging

### Viewing Live Logs

```bash
# gNB logs (in gNB terminal)
# Look for:
# - SCTP connection status
# - NG Setup success/failure
# - UE context setup
# - Handover procedures

# UE logs (in UE terminal)
# Look for:
# - Registration states
# - Authentication results
# - PDU session establishment
# - TUN interface creation
```

### Using tcpdump to Capture Traffic

```bash
# Capture SCTP traffic (N2 between gNB and AMF)
sudo tcpdump -i any -n sctp -w n2-trace.pcap

# Capture GTP-U traffic (N3 between gNB and UPF)
sudo tcpdump -i any -n udp port 2152 -w n3-trace.pcap

# Capture UE data plane traffic
sudo tcpdump -i uesimtun0 -n -w ue-data.pcap

# Analyze with Wireshark
wireshark n2-trace.pcap
```

### Checking Open5GS Logs

```bash
# Native deployment
sudo journalctl -u open5gs-amfd -f
sudo journalctl -u open5gs-upfd -f

# Docker Compose
docker compose -f /home/rayhan/Open5GS-Testbed/open5gs/open5gs-compose/docker-compose.yml logs -f amf
docker compose -f /home/rayhan/Open5GS-Testbed/open5gs/open5gs-compose/docker-compose.yml logs -f upf

# K3s
kubectl logs -n open5gs -l app=amf -f
kubectl logs -n open5gs -l app=upf -f
```

---

## 🔧 Common Issues and Solutions

### Issue 1: gNB Can't Connect to AMF

**Symptoms**:
```
[sctp] [error] Connection could not be established
```

**Solutions**:
1. Verify AMF is running and IP is correct
2. Check firewall allows port 38412
3. Verify SCTP module is loaded: `sudo modprobe sctp`
4. Test connectivity: `nc -zv <amf-ip> 38412`

### Issue 2: UE Authentication Failure

**Symptoms**:
```
[nas] [error] Authentication rejected by network
```

**Solutions**:
1. Verify IMSI exists in MongoDB/WebUI
2. Check K and OPc match exactly (case-sensitive)
3. Verify MCC/MNC match (001/01)
4. Check AMF logs for reject cause

### Issue 3: PDU Session Establishment Failed

**Symptoms**:
```
[nas] [error] PDU session establishment reject
```

**Solutions**:
1. Verify DNN is configured in SMF (`smf.yaml` → `subnet` section)
2. Check subscriber has slice permission in MongoDB
3. Verify UPF is running and reachable from SMF
4. Check SMF logs for detailed reject cause

### Issue 4: TUN Interface Created but No Internet

**Symptoms**:
```
# Ping gateway works
ping -I uesimtun0 10.45.0.1  ✓

# But internet doesn't work
ping -I uesimtun0 8.8.8.8  ✗
```

**Solutions**:
```bash
# Check UPF NAT rules
docker exec open5gs-upf iptables -t nat -L POSTROUTING -v
# Should show MASQUERADE for 10.45.0.0/24

# Check IP forwarding in UPF
docker exec open5gs-upf sysctl net.ipv4.ip_forward
# Should be 1

# Check UPF can reach internet
docker exec open5gs-upf ping -c 2 8.8.8.8
```

### Issue 5: "Permission Denied" for TUN Interface

**Symptoms**:
```
[tun] [error] Cannot open TUN device: Permission denied
```

**Solutions**:
```bash
# Run with sudo
sudo ./build/nr-ue -c configs/open5gs-ue-embb.yaml

# Or set capabilities (one-time)
sudo setcap cap_net_admin=eip ./build/nr-ue
./build/nr-ue -c configs/open5gs-ue-embb.yaml
```

---

## 📚 Additional Resources

### Open5GS Deployment Guides
- **Native Installation**: `/home/rayhan/Open5GS-Testbed/open5gs/Open5GS Setup and Configuration.md`
- **Docker Compose**: `/home/rayhan/Open5GS-Testbed/open5gs/open5gs-compose/README.md`
- **Kubernetes (K3s)**: `/home/rayhan/Open5GS-Testbed/open5gs/open5gs-k3s-calico/README.md`

### Configuration References
- **Open5GS Config Files**: `/home/rayhan/Open5GS-Testbed/open5gs/configs-reference/`
- **Network Slice Setup**: `/home/rayhan/Open5GS-Testbed/open5gs/open5gs-compose/DNN-configuration.md`

### External Documentation
- **UERANSIM GitHub**: https://github.com/aligungr/UERANSIM
- **UERANSIM Wiki**: https://github.com/aligungr/UERANSIM/wiki
- **Open5GS Docs**: https://open5gs.org/open5gs/docs/
- **3GPP 5G Specs**: https://www.3gpp.org/DynaReport/38-series.htm

---

## 🎯 Quick Reference Commands

```bash
# Start gNB
./build/nr-gnb -c configs/open5gs-gnb-local.yaml

# Start UE
./build/nr-ue -c configs/open5gs-ue-embb.yaml

# Check TUN interface
ip addr show uesimtun0

# Basic connectivity test
ping -I uesimtun0 -c 4 8.8.8.8

# Using nr-binder
./build/nr-binder 10.45.0.2 ping 8.8.8.8

# Interactive CLI
./build/nr-cli imsi-001010000000001

# Capture traffic
sudo tcpdump -i uesimtun0 -n

# Stop UE/gNB
# Press Ctrl+C in respective terminals
```

---

## 🔐 Security Note

⚠️ **Testbed Environment Only**

This configuration uses test credentials and is **NOT suitable for production**:
- Test PLMN: 001/01
- Example IMSI: 001010000000001
- Public K/OPc values: Documented in configs

For production deployments:
- Use real PLMN codes assigned to your operator
- Generate unique K/OPc per subscriber
- Implement proper security (authentication, encryption)
- Use SIM cards with secure element storage

---

## 📝 Summary

UERANSIM provides a complete 5G RAN simulator for testing Open5GS deployments:

✅ **nr-gnb**: Simulates 5G base station (gNodeB)  
✅ **nr-ue**: Simulates 5G user equipment (smartphone/device)  
✅ **nr-cli**: Runtime control and monitoring  
✅ **nr-binder**: Network namespace binding for testing  

**Typical Workflow**:
1. Configure gNB with AMF IP and network slices
2. Configure UE with subscriber credentials and desired DNNs
3. Start gNB → Wait for NG Setup success
4. Start UE → Wait for registration and PDU session
5. Test connectivity via `uesimtun0` interface
6. Use `nr-binder` for advanced testing scenarios

**Perfect for**: 5G protocol testing, network slice validation, QoS experimentation, and student labs.
