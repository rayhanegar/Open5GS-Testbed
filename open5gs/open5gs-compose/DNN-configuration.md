# Open5GS Multi-DNN Configuration with Docker

## Overview

Your Open5GS setup now supports multiple Data Network Names (DNNs) with separate TUN interfaces for different 5G network slices:

1. **embb.testbed** - Enhanced Mobile Broadband (eMBB)
   - Subnet: 10.45.0.0/24
   - Gateway: 10.45.0.1
   - TUN Interface: ogstun
   - Use case: High bandwidth applications

2. **urllc.v2x** - Ultra-Reliable Low Latency Communications (URLLC)
   - Subnet: 10.45.1.0/24
   - Gateway: 10.45.1.1
   - TUN Interface: ogstun2
   - Use case: Vehicle-to-Everything, critical communications

3. **mmtc.testbed** - Massive Machine Type Communications (mMTC)
   - Subnet: 10.45.2.0/24
   - Gateway: 10.45.2.1
   - TUN Interface: ogstun3
   - Use case: IoT devices, sensors

## Configuration Changes Made

### 1. UPF Configuration (upf.yaml)
- Updated to define separate subnets for each DNN
- Each subnet mapped to a specific TUN interface (ogstun, ogstun2, ogstun3)
- Matches the SMF configuration for DNNs

### 2. UPF Dockerfile
- Modified to run as root (required for TUN interface creation)
- Added startup script to handle interface creation
- Health checks remain in place

### 3. UPF Startup Script (startup.sh)
- Creates three TUN interfaces automatically inside the container
- Configures IP addresses and routing
- Sets up NAT rules for each subnet
- Starts the UPF daemon with proper configuration

## Network Architecture

```
Internet
    |
    ├── ogstun  (10.45.0.1/24) - eMBB traffic
    ├── ogstun2 (10.45.1.1/24) - URLLC traffic
    └── ogstun3 (10.45.2.1/24) - mMTC traffic
    
UPF Container (10.10.0.7)
    |
Docker Network (10.10.0.0/24)
    |
    ├── SMF (10.10.0.4) - Manages sessions for all DNNs
    ├── AMF (10.10.0.5) - Handles gNB connections
    └── Other NFs
```

## Key Points

1. **TUN Interfaces in Container**: Unlike the external context where ogstun interfaces are created on the host, in the containerized setup, these interfaces are created inside the UPF container.

2. **Network Isolation**: Each DNN has its own subnet, allowing for:
   - Traffic segregation
   - Different QoS policies
   - Separate routing rules

3. **Compatibility**: The configuration matches the SMF's DNN definitions, ensuring proper PDU session establishment.

## Starting the System

1. **Run the host network setup** (still needed for container networking):
   ```bash
   sudo ./setup-host-network.sh
   ```

2. **Start containers**:
   ```bash
   sudo docker compose up -d
   ```

3. **Verify TUN interfaces in UPF container**:
   ```bash
   sudo docker exec open5gs-upf ip addr show
   ```
   You should see ogstun, ogstun2, and ogstun3 interfaces.

4. **Check logs**:
   ```bash
   docker compose logs upf
   ```

## Testing Different DNNs

When UEs connect, they can request different DNNs based on their requirements:
- High-speed data: embb.testbed
- Low-latency critical: urllc.v2x  
- IoT devices: mmtc.testbed

The SMF will assign IP addresses from the corresponding subnet based on the requested DNN.