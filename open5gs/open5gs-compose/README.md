# Open5GS Containerized Deployment

This directory contains a complete containerized deployment of Open5GS with individual containers for each Network Function (NF).

## Architecture Overview

All NFs run as separate containers on a Docker bridge network (10.10.0.0/24) with the following IP assignments:

### 5G Core Network Functions
- **MongoDB**: 10.10.0.250 (Database backend)
- **NRF** (Network Repository Function): 10.10.0.10
- **SCP** (Service Communication Proxy): 10.10.0.200
- **AUSF** (Authentication Server Function): 10.10.0.11
- **UDM** (Unified Data Management): 10.10.0.12
- **UDR** (Unified Data Repository): 10.10.0.20
- **PCF** (Policy Control Function): 10.10.0.13
- **BSF** (Binding Support Function): 10.10.0.15
- **NSSF** (Network Slice Selection Function): 10.10.0.14
- **AMF** (Access and Mobility Management Function): 10.10.0.5
- **SMF** (Session Management Function): 10.10.0.4
- **UPF** (User Plane Function): 10.10.0.7

### 4G/EPC Network Functions (Optional)
- **HSS** (Home Subscriber Server): 10.10.0.8
- **MME** (Mobility Management Entity): 10.10.0.2
- **SGW-C** (Serving Gateway Control Plane): 10.10.0.3
- **SGW-U** (Serving Gateway User Plane): 10.10.0.6
- **PCRF** (Policy and Charging Rules Function): 10.10.0.9

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

1. Docker and Docker Compose installed
2. Ubuntu 20.04/22.04 or similar Linux distribution
3. Root/sudo access for network configuration
4. SCTP kernel module support

## Quick Start

### 1. Prepare host networking (run when the machine boots)

```bash
# Make the script executable
chmod +x setup-host-network.sh

# Configure host-side routing (uses tailscale0 for the tunnel address)
sudo ./setup-host-network.sh

# Optionally persist the iptables rules across reboots
sudo SAVE_RULES=true ./setup-host-network.sh
```

The script now discovers the Tailscale tunnel address from `tailscale0` and configures
all forwarding/NAT rules against that IP. Persistence is disabled by default—setting
`SAVE_RULES=true` mirrors the old behaviour if you want the rules saved to disk.

### 2. Seed the shared log directories

Each NF writes logs to a bind-mounted directory under `./logs/<nf-name>`. Create them
before bringing up the stack so they have the right ownership on the host:

```bash
mkdir -p logs/{nrf,scp,ausf,udr,udm,pcf,nssf,amf,smf,upf}
```

### 3. Build and start the containers

```bash
# Build all container images (Docker Compose v2 syntax)
docker compose build

# Start all services in the background
docker compose up -d

# Or launch only the 5GC essentials
docker compose up -d mongodb nrf scp udr udm ausf pcf nssf amf smf upf
```

### 3. Verify Services

```bash
# Check if all containers are running
docker compose ps

# Tail logs for a service
docker compose logs -f amf
docker compose logs smf

# Check network connectivity between NFs
docker exec open5gs-amf ping -c 1 10.10.0.10
```

## Connecting External gNB/UE

### For gNB (e.g., srsRAN, UERANSIM)

Configure your gNB with:
- **AMF Address**: `<host-ip>:38412` (SCTP for N2/NGAP)
- **UPF Address**: `<host-ip>:2152` (UDP for N3/GTP-U)

Example gNB configuration:
```yaml
amf:
  addr: 192.168.1.100  # Your host's IP
  port: 38412
  bind_addr: 10.34.4.245  # gNB's IP
```

### For UERANSIM

```yaml
# In ue-config.yaml
gnbSearchList:
  - 192.168.1.100  # Your host's IP

# In gnb-config.yaml
amfConfigs:
  - address: 192.168.1.100
    port: 38412
```

## Managing Subscribers

### Access MongoDB

```bash
# Connect to MongoDB container
docker exec -it open5gs-mongodb mongosh

# Switch to open5gs database
use open5gs

# View subscribers
db.subscribers.find()

# Add a new subscriber
db.subscribers.insertOne({
  imsi: "001010000000002",
  security: {
    k: "465b5ce8b199b49faa5f0a2ee238a6bc",
    opc: "e8ed289deba952e4283b54e88e6183ca",
    amf: "8000",
    sqn: NumberLong(0)
  },
  ambr: {
    downlink: { value: 1, unit: 3 },
    uplink: { value: 1, unit: 3 }
  },
  slice: [{
    sst: 1,
    default_indicator: true,
    session: [{
      name: "internet",
      type: 3,
      qos: { index: 9 }
    }]
  }]
})
```

## Troubleshooting

### Check Service Health

```bash
# Check if services are healthy
docker compose ps

# Restart a specific service
docker compose restart amf

# Check detailed logs
docker compose logs --tail=100 amf
```

### Common Issues

1. **SCTP Connection Failed**
   - Ensure SCTP module is loaded: `lsmod | grep sctp`
   - Check firewall rules: `sudo iptables -L -n`

2. **UPF Not Creating TUN Device**
   - Container needs privileged mode (already configured)
   - Check: `docker exec open5gs-upf ip addr show ogstun`

3. **MongoDB Connection Issues**
  - Ensure MongoDB is healthy: `docker compose ps mongodb`
  - Check logs: `docker compose logs mongodb`

4. **Port Already in Use**
   - Check port usage: `sudo netstat -tlnp | grep 38412`
   - Modify port mappings in docker-compose.yml if needed

## Advanced Configuration

### Custom YAML Configurations

Each NF's configuration can be customized by editing the YAML files in their respective directories:

Each NF image ships with an embedded baseline config plus an entrypoint that copies a
bind-mounted override from `./<nf>/<nf>.yaml` into `/etc/open5gs/<nf>.yaml` on startup.
Edit the file under this directory structure, then restart the service to apply the
changes:

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
- hss
- mme
- sgwc
- sgwu
- pcrf

## Monitoring

### Metrics

Metrics are exposed on port 90xx for services that support it:
- AMF: http://localhost:9005/metrics
- SMF: http://localhost:9004/metrics
- UPF: http://localhost:9007/metrics
- PCF: http://localhost:9013/metrics

### Logs

All logs are stored in the `./logs` directory, organized by service:
```
logs/
├── amf/
├── smf/
├── upf/
└── ...
```

## Cleanup

```bash
# Stop all containers
docker compose down

# Stop and remove volumes (WARNING: deletes MongoDB data)
docker compose down -v

# Remove all images built in this project
docker compose down --rmi all
```

## Security Notes

1. Default MongoDB credentials are set in docker-compose.yml - change for production
2. Inter-NF communication is not encrypted by default
3. Consider implementing TLS for SBI interfaces in production
4. Firewall rules should be adjusted based on your security requirements

## Support

For issues or questions:
1. Check Open5GS documentation: https://open5gs.org/
2. Review container logs: `docker compose logs [service]`
3. Verify network configuration: `docker network inspect open5gs-containers_5gcore`