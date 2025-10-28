# Open5GS Setup and Configuration Guide

## Version Note

For monolithic, same-host gNB and Open5GS implementation.

Supporting 3 network slices with UERANSIM integration:
1. Enhanced Mobile Broadband:
    1. SST: 1, SD:1, DNN: embb.testbed
    2. IPv4 subnet: 10.45.0.0/24
    3. Tunnel: ogstun (10.45.0.1/24)
2. Ultra-Reliable Low-Latency Communication (URLLC)
    1. SST: 2, SD: 2, DNN: urllc.v2x
    2. IPv4 subnet: 10.45.1.0/24
    3. Tunnel: ogstun2 (10.45.1.0/24)
3. Massive Machine-Type Communication (mMTC)
    1. SST: 3, SD: 3, DNN: mmtc.testbed
    2. IPv4 subnet: 10.45.2.0/24
    3. Tunnel: ogstun3 (10.45.2.0/24)

**Last modified**: Oct 28, 2025

## Quick Note on Configuration Files

All Network Function configuration files referenced in this guide are available in the **`configs-reference/`** directory of this repository. You can:

- **Copy directly** from `configs-reference/` to `/etc/open5gs/`
- **Use as templates** and customize for your environment
- **Verify your configs** against the reference files

See the [YAML Configs](#yaml-configs) section for detailed instructions on using reference configurations. 
# Reference
* [https\:\/\/open5gs\.org\/open5gs\/docs\/guide\/01\-quickstart\/](https://open5gs.org/open5gs/docs/guide/01-quickstart/)
* [https\:\/\/medium\.com\/rahasak\/5g\-core\-network\-setup\-with\-open5gs\-and\-ueransim\-cd0e77025fd7](https://medium.com/rahasak/5g-core-network-setup-with-open5gs-and-ueransim-cd0e77025fd7)
* [https\:\/\/github\.com\/s5uishida\/open5gs\_5gc\_ueransim\_sample\_config](https://github.com/s5uishida/open5gs_5gc_ueransim_sample_config)
* [https\:\/\/github\.com\/s5uishida\/open5gs\_5gc\_ueransim\_snssai\_upf\_sample\_config](https://github.com/s5uishida/open5gs_5gc_ueransim_snssai_upf_sample_config)
# Open5GS Installation
## MongoDB
Add MongoDB Repository
```warp-runnable-command
sudo apt-get install gnupg curl
```
```warp-runnable-command
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor
```
```warp-runnable-command
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.2.list
```
```warp-runnable-command
sudo apt-get update
```
```warp-runnable-command
sudo apt-get install -y mongodb-org
```
```warp-runnable-command
sudo systemctl start mongodb
sudo systemctl enable mongodb
```
## Open5GS
Add Open5GS Repository\, and then install open5gs\.
```warp-runnable-command
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install open5gs
```
## Node\.js
Install Node\.js on Ubuntu as follows
```warp-runnable-command
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
```
```warp-runnable-command
sudo apt-get install -y nodejs
```
## Open5GS WebUI
```warp-runnable-command
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
```
# YAML Configs

The configuration files for Open5GS can be found inside `/etc/open5gs` directory. For every modification, it is recommended to restart the associated service of that `.yaml` file.

**Reference configurations** for all Network Functions are available in the `configs-reference/` directory of this repository. You can use these as templates for your deployment.

## Available Reference Configurations

The following configuration files are available in `configs-reference/`:

- `amf.yaml` - Access and Mobility Management Function
- `ausf.yaml` - Authentication Server Function
- `bsf.yaml` - Binding Support Function
- `hss.yaml` - Home Subscriber Server (4G/EPC)
- `mme.yaml` - Mobility Management Entity (4G/EPC)
- `nrf.yaml` - Network Repository Function
- `nssf.yaml` - Network Slice Selection Function
- `pcf.yaml` - Policy Control Function
- `pcrf.yaml` - Policy and Charging Rules Function (4G/EPC)
- `scp.yaml` - Service Communication Proxy
- `sgwc.yaml` - Serving Gateway Control Plane (4G/EPC)
- `sgwu.yaml` - Serving Gateway User Plane (4G/EPC)
- `smf.yaml` - Session Management Function
- `smf-icn.yaml` - SMF configuration for ICN network
- `udm.yaml` - Unified Data Management
- `udr.yaml` - Unified Data Repository
- `upf.yaml` - User Plane Function

## Configuration Workflow

For each Network Function configuration:

1. **Backup the original configuration file**
2. **Copy the reference configuration** from `configs-reference/` or edit directly
3. **Customize** the configuration for your environment (if needed)
4. **Restart the service** to apply changes

### Quick Copy All Configurations

To copy all reference configurations at once:

```bash
# Ensure you're in the repository directory
cd /path/to/repo/open5gs

# Copy all configs to /etc/open5gs (with backups)
for config in configs-reference/*.yaml; do
    filename=$(basename "$config")
    sudo cp "/etc/open5gs/$filename" "/etc/open5gs/${filename}.backup" 2>/dev/null || true
    sudo cp "$config" "/etc/open5gs/$filename"
done
```

## Individual Network Function Configurations

## amf.yaml

```bash
cd /etc/open5gs
sudo cp ./amf.yaml ./amf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/amf.yaml /etc/open5gs/amf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./amf.yaml
```

Replace the content with the configuration from `configs-reference/amf.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/amf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

amf:
  sbi:
    server:
      - address: 127.0.0.5
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  ngap:
    server:
      - address: 127.0.0.5
  metrics:
    server:
      - address: 127.0.0.5
        port: 9090
  guami:
    - plmn_id:
        mcc: 001
        mnc: 01
      amf_id:
        region: 2
        set: 1
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1
  plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
      s_nssai:
        - sst: 1
          dnn: embb.testbed
        - sst: 2
          dnn: urllc.v2x
        - sst: 3
          dnn: mmtc.testbed
  security:
    integrity_order : [ NIA2, NIA1, NIA0 ]
    ciphering_order : [ NEA0, NEA1, NEA2 ]
  network_name:
    full: Digital Hugs Network
    short: DigitalHugs <3
  amf_name: open5gs-amf0
  time:
#    t3502:
#      value: 720   # 12 minutes * 60 = 720 seconds
    t3512:
      value: 540    # 9 minutes * 60 = 540 seconds

################################################################################
# SBI Server
################################################################################
#  o Bind to the address on the eth0 and advertise as open5gs-amf.svc.local
#  sbi:
#    server:
#      - dev:eth0
#        advertise: open5gs-amf.svc.local
#
#  o Specify a custom port number 7777 while binding to the given address
#  sbi:
#    server:
#      - address: amf.localdomain
#        port: 7777
#
#  o Bind to 127.0.0.5 and advertise as open5gs-amf.svc.local
#  sbi:
#    server:
#      - address: 127.0.0.5
#        port: 7777
#        advertise: open5gs-amf.svc.local
#
#  o Bind to port 7777 but advertise with a different port number 8888
#  sbi:
#    server:
#      - address: 127.0.0.5
#        port: 7777
#        advertise: open5gs-amf.svc.local:8888
#
################################################################################
# SBI Client
################################################################################
#  o Direct Communication with NRF
#  sbi:
#    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
#
#  o Indirect Communication by Delegating to SCP
#  sbi:
#    client:
#      scp:
#        - uri: http://127.0.0.200:7777
#
#  o Indirect Communication without Delegation
#  sbi:
#    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
#      scp:
#        - uri: http://127.0.0.200:7777
#      delegated:
#        nrf:
#          nfm: no    # Directly communicate NRF management functions
#          disc: no   # Directly communicate NRF discovery
#        scp:
#          next: no   # Do not delegate to SCP for next-hop
#
#  o Indirect Communication with Delegated Discovery
#  sbi:
#    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
#      scp:
#        - uri: http://127.0.0.200:7777
#      delegated:
#        nrf:
#          nfm: no    # Directly communicate NRF management functions
#          disc: yes  # Delegate discovery to SCP
#        scp:
#          next: yes  # Delegate to SCP for next-hop communications
#
#  o Default delegation: all communications are delegated to the SCP
#  sbi:
#    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
#      scp:
#        - uri: http://127.0.0.200:7777
#      # No 'delegated' section; defaults to AUTO delegation
#
################################################################################
# HTTPS scheme with TLS
################################################################################
#  o Set as default if not individually set
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/amf.key
#        cert: /etc/open5gs/tls/amf.crt
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#  sbi:
#    server:
#      - address: amf.localdomain
#    client:
#      nrf:
#        - uri: https://nrf.localdomain
#
#  o Enable SSL key logging for Wireshark
#    - This configuration allows capturing SSL/TLS session keys
#      for debugging or analysis purposes using Wireshark.
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/amf.key
#        cert: /etc/open5gs/tls/amf.crt
#        sslkeylogfile: /var/log/open5gs/tls/amf-server-sslkeylog.log
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#        client_sslkeylogfile: /var/log/open5gs/tls/amf-client-sslkeylog.log
#  sbi:
#    server:
#      - address: amf.localdomain
#    client:
#      nrf:
#        - uri: https://nrf.localdomain
#
#  o Add client TLS verification
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/amf.key
#        cert: /etc/open5gs/tls/amf.crt
#        verify_client: true
#        verify_client_cacert: /etc/open5gs/tls/ca.crt
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#        client_private_key: /etc/open5gs/tls/amf.key
#        client_cert: /etc/open5gs/tls/amf.crt
#  sbi:
#    server:
#      - address: amf.localdomain
#    client:
#      nrf:
#        - uri: https://nrf.localdomain
#
################################################################################
# NGAP Server
################################################################################
#  o Listen on address available in `eth0` interface
#  ngap:
#    server:
#      - dev: eth0
#
################################################################################
# 3GPP Specification
################################################################################
#  o GUAMI
#  guami:
#    - plmn_id:
#        mcc: 999
#        mnc: 70
#      amf_id:
#        region: 2
#        set: 1
#        pointer: 4
#    - plmn_id:
#        mcc: 001
#        mnc: 01
#      amf_id:
#        region: 5
#        set: 2
#
#  o TAI
#  tai:
#    - plmn_id:
#        mcc: 001
#        mnc: 01
#      tac: [1, 3, 5]
#  tai:
#    - plmn_id:
#        mcc: 002
#        mnc: 02
#      tac: [6-10, 15-18]
#  tai:
#    - plmn_id:
#        mcc: 003
#        mnc: 03
#      tac: 20
#    - plmn_id:
#        mcc: 004
#        mnc: 04
#      tac: 21
#  tai:
#    - plmn_id:
#        mcc: 005
#        mnc: 05
#      tac: [22, 28]
#    - plmn_id:
#        mcc: 006
#        mnc: 06
#      tac: [30-32, 34, 36-38, 40-42, 44, 46, 48]
#    - plmn_id:
#        mcc: 007
#        mnc: 07
#      tac: 50
#    - plmn_id:
#        mcc: 008
#        mnc: 08
#      tac: 60
#    - plmn_id:
#        mcc: 009
#        mnc: 09
#      tac: [70, 80]
#
#  o PLMN Support
#  plmn_support:
#    - plmn_id:
#        mcc: 999
#        mnc: 70
#      s_nssai:
#        - sst: 1
#          sd: 010000
#    - plmn_id:
#        mcc: 999
#        mnc: 70
#      s_nssai:
#        - sst: 1
#
#  o Access Control
#  access_control:
#    - default_reject_cause: 13
#    - plmn_id:
#        reject_cause: 15
#        mcc: 001
#        mnc: 01
#    - plmn_id:
#        mcc: 002
#        mnc: 02
#    - plmn_id:
#        mcc: 999
#        mnc: 70
#
#  o Relative Capacity
#  relative_capacity: 100

```
## ausf.yaml

```bash
cd /etc/open5gs
sudo cp ./ausf.yaml ./ausf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/ausf.yaml /etc/open5gs/ausf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./ausf.yaml
```

Replace the content with the configuration from `configs-reference/ausf.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/ausf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

ausf:
  sbi:
    server:
      - address: 127.0.0.11
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
```
## bsf.yaml

```bash
cd /etc/open5gs
sudo cp ./bsf.yaml ./bsf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/bsf.yaml /etc/open5gs/bsf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./bsf.yaml
```

Replace the content with the configuration from `configs-reference/bsf.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/bsf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

bsf:
  sbi:
    server:
      - address: 127.0.0.15
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
```
## hss.yaml

```bash
cd /etc/open5gs
sudo cp ./hss.yaml ./hss.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/hss.yaml /etc/open5gs/hss.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./hss.yaml
```

Replace the content with the configuration from `configs-reference/hss.yaml`, or use the following:
```yaml
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/hss.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

hss:
  freeDiameter: /etc/freeDiameter/hss.conf
  metrics:
    server:
      - address: 127.0.0.8
        port: 9090
#  sms_over_ims: "sip:smsc.mnc001.mcc001.3gppnetwork.org:7060;transport=tcp"
#  use_mongodb_change_stream: true
```
## mme.yaml

```bash
cd /etc/open5gs
sudo cp ./mme.yaml ./mme.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/mme.yaml /etc/open5gs/mme.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./mme.yaml
```

Replace the content with the configuration from `configs-reference/mme.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/mme.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    server:
      - address: 127.0.0.2
  gtpc:
    server:
      - address: 127.0.0.2
    client:
      sgwc:
        - address: 127.0.0.3
      smf:
        - address: 127.0.0.4
  metrics:
    server:
      - address: 127.0.0.2
        port: 9090
  gummei:
    - plmn_id:
        mcc: 001
        mnc: 01
      mme_gid: 2
      mme_code: 1
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1
  security:
    integrity_order : [ EIA2, EIA1, EIA0 ]
    ciphering_order : [ EEA0, EEA1, EEA2 ]
  network_name:
    full: Digital Hugs Network
    short: DigitalHugs <3
  mme_name: open5gs-mme0
  time:
#    t3402:
#      value: 720   # 12 minutes * 60 = 720 seconds
#    t3412:
#      value: 3240  # 54 minutes * 60 = 3240 seconds
#    t3423:
#      value: 720   # 12 minutes * 60 = 720 seconds

################################################################################
# S1AP Server
################################################################################
#  o Listen on address available in `eth0` interface
#  ngap:
#    server:
#      - dev: eth0
#
################################################################################
# GTP-C Server
################################################################################
#  o Listen on IPv4 and IPv6
#  gtpc:
#    server:
#      - address: 127.0.0.2
#      - address: ::1
#
################################################################################
# GTP-C Client
################################################################################
#  o SGW selection by eNodeB TAC
#   (either single TAC or multiple TACs, DECIMAL representation)
#  gtpc:
#    client:
#      sgwc:
#        - address: 127.0.0.3
#          tac: 26000
#        - address: 127.0.2.2
#          tac: [25000, 27000, 28000]
#
#  o SGW selection by e_cell_id(28bit)
#   (either single or multiple e_cell_id, HEX representation)
#  gtpc:
#    client:
#      sgwc:
#        - address: 127.0.0.3
#          e_cell_id: abcde01
#        - address: 127.0.2.2
#          e_cell_id: [12345, a9413, 98765]
#
#  o SMF selection by APN
#  gtpc:
#    client:
#      smf:
#        - address: 127.0.0.4
#          apn: internet
#        - address: 127.0.0.5
#          apn: volte
#
#  o SMF selection by eNodeB TAC
#   (either single TAC or multiple TACs, DECIMAL representation)
#  gtpc:
#    client:
#      smf:
#        - address: 127.0.0.4
#          tac: 26000
#        - address: 127.0.2.4
#          tac: [25000, 27000, 28000]
#
#  o SMF selection by e_cell_id(28bit)
#   (either single or multiple e_cell_id, HEX representation)
#  gtpc:
#    client:
#      smf:
#        - address: 127.0.0.4
#          e_cell_id: abcde01
#        - address: 127.0.2.4
#          e_cell_id: [12345, a9413, 98765]
#
#  o One SGSN is defined.
#    If prefer_ipv4 is not true, [fd69:f21d:873c:fa::2] is selected.
#  gtpc:
#    client:
#      sgsn:
#        - address:
#          - 127.0.0.3
#          - fd69:f21d:873c:fa::2
#          routes:
#          - rai:
#              lai:
#                plmn_id:
#                  mcc: 001
#                  mnc: 01
#                lac: 43690
#              rac: 187
#            ci: 1223
#
#
#  o Two SGSNs are defined. Last one is used by default if no
#    matching RAI+CI route is found.
#  gtpc:
#    client:
#      sgsn:
#        - address:
#          - 127.0.0.3
#          - fd69:f21d:873c:fa::2
#          routes:
#          - rai:
#              lai:
#                plmn_id:
#                  mcc: 001
#                  mnc: 01
#                lac: 43690
#              rac: 187
#            ci: 1223
#        - name: sgsn3.open5gs.org
#          default_route: true
#
################################################################################
# SGaAP Server
################################################################################
#  o MSC/VLR
#  sgsap:
#    client:
#      - address: msc.open5gs.org # SCTP server address configured on the MSC/VLR
#        local_address: 127.0.0.2 # SCTP local IP addresses to be bound in the MME
#        map:
#          tai:
#            plmn_id:
#              mcc: 001
#              mnc: 01
#            tac: 4131
#          lai:
#            plmn_id:
#              mcc: 001
#              mnc: 01
#            lac: 43691
#        map:
#          tai:
#            plmn_id:
#              mcc: 002
#              mnc: 02
#            tac: 4132
#          lai:
#            plmn_id:
#              mcc: 002
#              mnc: 02
#            lac: 43692
#      - address:       # SCTP server address configured on the MSC/VLR
#          - 127.0.0.88
#          - 10.0.0.88
#          - 172.16.0.88
#          - 2001:db8:babe::88
#        local_address: # SCTP local IP addresses to be bound in the MME
#          - 127.0.0.2
#          - 192.168.1.4
#          - 2001:db8:cafe::2
#        map:
#          tai:
#            plmn_id:
#              mcc: 001
#              mnc: 01
#            tac: 4133
#          lai:
#            plmn_id:
#              mcc: 002
#              mnc: 02
#            lac: 43693
#
################################################################################
# 3GPP Specification
################################################################################
#  o GUMMEI
#  gummei:
#    - plmn_id:
#        mcc: 001
#        mnc: 01
#      mme_gid: 2
#      mme_code: 1
#    - plmn_id:
#        - mcc: 002
#          mnc: 02
#        - mcc: 003
#          mnc: 03
#      mme_gid: [3, 4]
#      mme_code:
#        - 2
#        - 3
#
#  o TAI
#  tai:
#    - plmn_id:
#        mcc: 001
#        mnc: 01
#      tac: [1, 3, 5]
#  tai:
#    - plmn_id:
#        mcc: 002
#        mnc: 02
#      tac: [6-10, 15-18]
#  tai:
#    - plmn_id:
#        mcc: 003
#        mnc: 03
#      tac: 20
#    - plmn_id:
#        mcc: 004
#        mnc: 04
#      tac: 21
#  tai:
#    - plmn_id:
#        mcc: 005
#        mnc: 05
#      tac: [22, 28]
#    - plmn_id:
#        mcc: 006
#        mnc: 06
#      tac: [30-32, 34, 36-38, 40-42, 44, 46, 48]
#    - plmn_id:
#        mcc: 007
#        mnc: 07
#      tac: 50
#    - plmn_id:
#        mcc: 008
#        mnc: 08
#      tac: 60
#    - plmn_id:
#        mcc: 009
#        mnc: 09
#      tac: [70, 80]
#
#  o Access Control
#  access_control:
#    - default_reject_cause: 13
#    - plmn_id:
#        reject_cause: 15
#        mcc: 001
#        mnc: 01
#    - plmn_id:
#        mcc: 002
#        mnc: 02
#    - plmn_id:
#        mcc: 999
#        mnc: 70
#
#  o HSS Selection
#    o realm and host are optional
#    o realm will be generated from plmn_id if not provided
#    o host will not be used if not provided
#  hss_map:
#    - plmn_id:
#        mcc: 001
#        mnc: 01
#    - plmn_id:
#        mcc: 002
#        mnc: 02
#      realm: epc.mnc002.mcc002.3gppnetwork.org
#    - plmn_id:
#        mcc: 999
#        mnc: 70
#      realm: localdomain
#      host: hss.localdomain
#
#  o Relative Capacity
#  relative_capacity: 100
```
## nrf.yaml

```bash
cd /etc/open5gs
sudo cp ./nrf.yaml ./nrf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/nrf.yaml /etc/open5gs/nrf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./nrf.yaml
```

Replace the content with the configuration from `configs-reference/nrf.yaml`. Note: This configuration only modifies the logger section from default:
```yaml
logger:
  file:
    path: /var/log/open5gs/nrf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

nrf:
  serving:  # 5G roaming requires PLMN in NRF
    - plmn_id:
        mcc: 001
        mnc: 01
  sbi:
    server:
      - address: 127.0.0.10
        port: 7777

################################################################################
# SBI Server
################################################################################
#  o Bind to the address on the eth0 and advertise as open5gs-nrf.svc.local
#  sbi:
#    server:
#      - dev:eth0
#        advertise: open5gs-nrf.svc.local
#
#  o Specify a custom port number 7777 while binding to the given address
#  sbi:
#    server:
#      - address: nrf.localdomain
#        port: 7777
#
#  o Bind to 127.0.0.10 and advertise as open5gs-nrf.svc.local
#  sbi:
#    server:
#      - address: 127.0.0.10
#        port: 7777
#        advertise: open5gs-nrf.svc.local
#
#  o Bind to port 7777 but advertise with a different port number 8888
#  sbi:
#    server:
#      - address: 127.0.0.10
#        port: 7777
#        advertise: open5gs-nrf.svc.local:8888
#
################################################################################
# HTTPS scheme with TLS
################################################################################
#  o Set as default if not individually set
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/nrf.key
#        cert: /etc/open5gs/tls/nrf.crt
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#  sbi:
#    server:
#      - address: nrf.localdomain
#
#  o Enable SSL key logging for Wireshark
#    - This configuration allows capturing SSL/TLS session keys
#      for debugging or analysis purposes using Wireshark.
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/nrf.key
#        cert: /etc/open5gs/tls/nrf.crt
#        sslkeylogfile: /var/log/open5gs/tls/nrf-server-sslkeylog.log
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#        client_sslkeylogfile: /var/log/open5gs/tls/nrf-client-sslkeylog.log
#  sbi:
#    server:
#      - address: nrf.localdomain
#
#  o Add client TLS verification
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/nrf.key
#        cert: /etc/open5gs/tls/nrf.crt
#        verify_client: true
#        verify_client_cacert: /etc/open5gs/tls/ca.crt
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#        client_private_key: /etc/open5gs/tls/nrf.key
#        client_cert: /etc/open5gs/tls/nrf.crt
#  sbi:
#    server:
#      - address: nrf.localdomain

```
## nssf.yaml

```bash
cd /etc/open5gs
sudo cp ./nssf.yaml ./nssf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/nssf.yaml /etc/open5gs/nssf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./nssf.yaml
```

Replace the content with the configuration from `configs-reference/nssf.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/nssf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

nssf:
  sbi:
    server:
      - address: 127.0.0.14
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
      nsi:
        - uri: http://127.0.0.10:7777
          s_nssai:
            sst: 1
################################################################################
# SBI Server
################################################################################
#  o Bind to the address on the eth0 and advertise as open5gs-nssf.svc.local
#  sbi:
#    server:
#      - dev:eth0
#        advertise: open5gs-nssf.svc.local
#
#  o Specify a custom port number 7777 while binding to the given address
#  sbi:
#    server:
#      - address: nssf.localdomain
#        port: 7777
#
#  o Bind to 127.0.0.14 and advertise as open5gs-nssf.svc.local
#  sbi:
#    server:
#      - address: 127.0.0.14
#        port: 7777
#        advertise: open5gs-nssf.svc.local
#
#  o Bind to port 7777 but advertise with a different port number 8888
#  sbi:
#    server:
#      - address: 127.0.0.14
#        port: 7777
#        advertise: open5gs-nssf.svc.local:8888
#
################################################################################
# SBI Client
################################################################################
#  o Network Slice Instance(NSI)
#   1. NRF[http://::1:7777/nnrf-nfm/v1/nf-instances]
#      S-NSSAI[SST:1]
#   2. NRF[http://127.0.0.19:7777/nnrf-nfm/v1/nf-instances]
#      NSSAI[SST:1, SD:000080]
#   3. NRF[http://127.0.0.10:7777/nnrf-nfm/v1/nf-instances]
#      NSSAI[SST:1, SD:009000]
#
#  sbi:
#    client:
#      nsi:
#        - uri: http://[::1]:7777
#          s_nssai:
#            sst: 1
#        - uri: http://127.0.0.19:7777
#          s_nssai:
#            sst: 1
#            sd: 000080
#        - uri: http://127.0.0.10:7777
#          s_nssai:
#            sst: 1
#            sd: 009000
#
#  o Direct Communication with NRF
#  sbi:
#    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
#
#  o Indirect Communication by Delegating to SCP
#  sbi:
#    client:
#      scp:
#        - uri: http://127.0.0.200:7777
#
#  o Indirect Communication without Delegation
#  sbi:
#    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
#      scp:
#        - uri: http://127.0.0.200:7777
#      delegated:
#        nrf:
#          nfm: no    # Directly communicate NRF management functions
#          disc: no   # Directly communicate NRF discovery
#        scp:
#          next: no   # Do not delegate to SCP for next-hop
#
#  o Indirect Communication with Delegated Discovery
#  sbi:
#    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
#      scp:
#        - uri: http://127.0.0.200:7777
#      delegated:
#        nrf:
#          nfm: no    # Directly communicate NRF management functions
#          disc: yes  # Delegate discovery to SCP
#        scp:
#          next: yes  # Delegate to SCP for next-hop communications
#
#  o Default delegation: all communications are delegated to the SCP
#  sbi:
#    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
#      scp:
#        - uri: http://127.0.0.200:7777
#      # No 'delegated' section; defaults to AUTO delegation
#
#
################################################################################
# HTTPS scheme with TLS
################################################################################
#  o Set as default if not individually set
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/nssf.key
#        cert: /etc/open5gs/tls/nssf.crt
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#  sbi:
#    server:
#      - address: nssf.localdomain
#    client:
#      nrf:
#        - uri: https://nrf.localdomain
#      nsi:
#        - uri: https://nrf.localdomain
#          s_nssai:
#            sst: 1
#
#  o Enable SSL key logging for Wireshark
#    - This configuration allows capturing SSL/TLS session keys
#      for debugging or analysis purposes using Wireshark.
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/nssf.key
#        cert: /etc/open5gs/tls/nssf.crt
#        sslkeylogfile: /var/log/open5gs/tls/nssf-server-sslkeylog.log
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#        client_sslkeylogfile: /var/log/open5gs/tls/nssf-client-sslkeylog.log
#  sbi:
#    server:
#      - address: nssf.localdomain
#    client:
#      nrf:
#        - uri: https://nrf.localdomain
#      nsi:
#        - uri: https://nrf.localdomain
#          s_nssai:
#            sst: 1
#
#  o Add client TLS verification
#  default:
#    tls:
#      server:
#        scheme: https
#        private_key: /etc/open5gs/tls/nssf.key
#        cert: /etc/open5gs/tls/nssf.crt
#        verify_client: true
#        verify_client_cacert: /etc/open5gs/tls/ca.crt
#      client:
#        scheme: https
#        cacert: /etc/open5gs/tls/ca.crt
#        client_private_key: /etc/open5gs/tls/nssf.key
#        client_cert: /etc/open5gs/tls/nssf.crt
#  sbi:
#    server:
#      - address: nssf.localdomain
#    client:
#      nrf:
#        - uri: https://nrf.localdomain
#      nsi:
#        - uri: https://nrf.localdomain
#          s_nssai:
#            sst: 1
```
## pcf.yaml

```bash
cd /etc/open5gs
sudo cp ./pcf.yaml ./pcf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/pcf.yaml /etc/open5gs/pcf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./pcf.yaml
```

Replace the content with the configuration from `configs-reference/pcf.yaml`, or use the following: 
```yaml
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/pcf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

pcf:
  sbi:
    server:
      - address: 127.0.0.13
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  metrics:
    server:
      - address: 127.0.0.13
        port: 9090
```
## pcrf.yaml

```bash
cd /etc/open5gs
sudo cp ./pcrf.yaml ./pcrf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/pcrf.yaml /etc/open5gs/pcrf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./pcrf.yaml
```

Replace the content with the configuration from `configs-reference/pcrf.yaml`, or use the following:
```yaml
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/pcrf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64
pcrf:
  freeDiameter: /etc/freeDiameter/pcrf.conf
  metrics:
    server:
      - address: 127.0.0.9
        port: 9090
```
## scp.yaml

```bash
cd /etc/open5gs
sudo cp ./scp.yaml ./scp.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/scp.yaml /etc/open5gs/scp.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./scp.yaml
```

Replace the content with the configuration from `configs-reference/scp.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/scp.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

scp:
  sbi:
    server:
      - address: 127.0.0.200
        port: 7777
    client:
      nrf:
        - uri: http://127.0.0.10:7777
```
## sgwc.yaml

```bash
cd /etc/open5gs
sudo cp ./sgwc.yaml ./sgwc.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/sgwc.yaml /etc/open5gs/sgwc.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./sgwc.yaml
```

Replace the content with the configuration from `configs-reference/sgwc.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/sgwc.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

sgwc:
  gtpc:
    server:
      - address: 127.0.0.3
  pfcp:
    server:
      - address: 127.0.0.3
    client:
      sgwu:
        - address: 127.0.0.6
```
## sgwu.yaml

```bash
cd /etc/open5gs
sudo cp ./sgwu.yaml ./sgwu.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/sgwu.yaml /etc/open5gs/sgwu.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./sgwu.yaml
```

Replace the content with the configuration from `configs-reference/sgwu.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/sgwu.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

sgwu:
  pfcp:
    server:
      - address: 127.0.0.6
    client:
#      sgwc:    # SGW-U PFCP Client try to associate SGW-C PFCP Server
#        - address: 127.0.0.3
  gtpu:
    server:
      - address: 127.0.0.6
```
## smf.yaml

```bash
cd /etc/open5gs
sudo cp ./smf.yaml ./smf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/smf.yaml /etc/open5gs/smf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./smf.yaml
```

Replace the content with the configuration from `configs-reference/smf.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/smf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

smf:
  sbi:
    server:
      - address: 127.0.0.4
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  pfcp:
    server:
      - address: 127.0.0.4
    client:
      upf:
        - address: 127.0.0.7
          dnn: ['embb.testbed', 'urllc.v2x', 'mmtc.testbed']
  gtpc:
    server:
      - address: 127.0.0.4
  gtpu:
    server:
      - address: 127.0.0.4
  metrics:
    server:
      - address: 127.0.0.4
        port: 9090
  session:
    - subnet: 10.45.0.0/24
      sst: 1
      # sd: 000001
      dnn: embb.testbed
      gateway: 10.45.0.1
    - subnet: 10.45.1.0/24
      sst: 2
      # sd: 000002
      dnn: urllc.v2x
      gateway: 10.45.1.1
    - subnet: 10.45.2.0/24
      sst: 3
      # sd: 000003
      dnn: mmtc.testbed
      gateway: 10.45.2.1
  dns:
    - 8.8.8.8
    - 8.8.4.4
    - 2001:4860:4860::8888
    - 2001:4860:4860::8844
  mtu: 1400
#  p-cscf:
#    - 127.0.0.1
#    - ::1
#  ctf:
#    enabled: auto   # auto(default)|yes|no
  freeDiameter: /etc/freeDiameter/smf.conf
  info:
    - s_nssai:
        - sst: 1
          # sd: 000001
          dnn:
            - embb.testbed
        - sst: 2
          # sd: 000002
          dnn:
            - urllc.v2x
        - sst: 3
          # sd: 000003
          dnn:
            - mmtc.testbed
      tai:
        - plmn_id:
            mcc: 001
            mnc: 01
          tac: 1
```
## udm.yaml

```bash
cd /etc/open5gs
sudo cp ./udm.yaml ./udm.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/udm.yaml /etc/open5gs/udm.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./udm.yaml
```

Replace the content with the configuration from `configs-reference/udm.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/udm.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

udm:
  hnet:
    - id: 1
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-1.key
    - id: 2
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-2.key
    - id: 3
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-3.key
    - id: 4
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-4.key
    - id: 5
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-5.key
    - id: 6
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-6.key
  sbi:
    server:
      - address: 127.0.0.12
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
```
## udr.yaml

```bash
cd /etc/open5gs
sudo cp ./udr.yaml ./udr.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/udr.yaml /etc/open5gs/udr.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./udr.yaml
```

Replace the content with the configuration from `configs-reference/udr.yaml`, or use the following:
```yaml
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/udr.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

udr:
  sbi:
    server:
      - address: 127.0.0.20
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777

```
## upf.yaml

```bash
cd /etc/open5gs
sudo cp ./upf.yaml ./upf.yaml.backup
```

**Option 1: Copy from reference**
```bash
sudo cp /path/to/repo/open5gs/configs-reference/upf.yaml /etc/open5gs/upf.yaml
```

**Option 2: Edit manually**
```bash
sudo nano ./upf.yaml
```

Replace the content with the configuration from `configs-reference/upf.yaml`, or use the following:
```yaml
logger:
  file:
    path: /var/log/open5gs/upf.log
    timestamp: true
  default:
    timestamp: false
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

upf:
  pfcp:
    server:
      - address: 127.0.0.7
    client:
     smf:     #  UPF PFCP Client try to associate SMF PFCP Server
       - address: 127.0.0.4
  gtpu:
    server:
      - address: 127.0.0.7
  session:
    - subnet: 10.45.0.0/24
      sst: 1
      # sd: 000001
      dnn: embb.testbed
      gateway: 10.45.0.1
      dev: ogstun
    - subnet: 10.45.1.0/24
      sst: 2
      # sd: 000002
      dnn: urllc.v2x
      gateway: 10.45.1.1
      dev: ogstun2
    - subnet: 10.45.2.0/24
      sst: 3
      # sd: 000003
      dnn: mmtc.testbed
      gateway: 10.45.2.1
      dev: ogstun3
    # - subnet: 2001:db8:cafe::/48
    #   gateway: 2001:db8:cafe::1
  metrics:
    server:
      - address: 127.0.0.7
        port: 9090
```
# Utility Scripts
Place the following utility scripts in the same \/etc\/open5gs directory\.
## open5gs\-iptables\-setup\.sh
Add or remove IP Tables and rule chains configuration required to route UE traffic to Internet\.
```warp-runnable-command
#!/bin/bash

# Enhanced 5G Testbed Firewall Setup Script
# Usage: ./setup-iptables.sh [--add|--remove|--status]
# Author: 5G CNF Research Testbed

set -e  # Exit on any error

# Configuration variables
SCRIPT_NAME="5G Testbed Iptables Manager"
VERSION="1.0"
BACKUP_DIR="/etc/open5gs/iptables-backup"
BACKUP_FILE="$BACKUP_DIR/iptables-backup-$(date +%Y%m%d-%H%M%S).rules"

# Network configuration
declare -a TUN_INTERFACES=("ogstun" "ogstun2" "ogstun3")
declare -a SUBNETS=("10.45.0.0/24" "10.45.1.0/24" "10.45.2.0/24")
declare -a SLICE_NAMES=("eMBB" "URLLC" "mMTC")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$SCRIPT_NAME v$VERSION${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTION]

OPTIONS:
    --add       Add 5G testbed iptables rules
    --remove    Remove 5G testbed rules and restore defaults
    --status    Show current iptables status
    --help      Show this help message

EXAMPLES:
    $0 --add       # Setup 5G testbed firewall rules
    $0 --remove    # Clean up and restore original rules
    $0 --status    # Check current firewall status
EOF
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "Creating backup directory: $BACKUP_DIR"
        sudo mkdir -p "$BACKUP_DIR"
    fi
}

# Backup current iptables rules
backup_iptables() {
    log_info "Backing up current iptables rules to: $BACKUP_FILE"
    create_backup_dir
    
    echo "# Iptables backup created on $(date)" | sudo tee "$BACKUP_FILE" > /dev/null
    echo "# Filter table" | sudo tee -a "$BACKUP_FILE" > /dev/null
    sudo iptables-save | sudo tee -a "$BACKUP_FILE" > /dev/null
    
    log_info "Backup completed successfully"
}

# Get default internet interface
get_internet_interface() {
    local iface
    iface=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [[ -z "$iface" ]]; then
        log_error "Could not determine default internet interface"
        exit 1
    fi
    
    echo "$iface"
}

# Check if interface exists
interface_exists() {
    local interface=$1
    if ip link show "$interface" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Add 5G testbed iptables rules
add_rules() {
    print_header
    log_info "Setting up iptables for 5G Network Slicing testbed..."
    
    # Backup current rules
    backup_iptables
    
    # Enable IP forwarding using sysctl
    log_info "Enabling IPv4 forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=1
    
    # Make IP forwarding persistent
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        log_info "Making IPv4 forwarding persistent..."
        echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf > /dev/null
    fi
    
    # Get internet interface
    local inet_iface
    inet_iface=$(get_internet_interface)
    log_info "Using internet interface: $inet_iface"
    
    log_info "Adding INPUT rules for TUN interfaces..."
    # Accept traffic from all TUN interfaces
    for i in "${!TUN_INTERFACES[@]}"; do
        local interface="${TUN_INTERFACES[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        if interface_exists "$interface"; then
            log_debug "Adding INPUT rule for $interface ($slice_name)"
            sudo iptables -I INPUT -i "$interface" -j ACCEPT
        else
            log_warn "Interface $interface does not exist yet, rule will be added anyway"
            sudo iptables -I INPUT -i "$interface" -j ACCEPT
        fi
    done
    
    log_info "Adding FORWARD rules for TUN interfaces..."
    # Allow forwarding from and to TUN interfaces
    for i in "${!TUN_INTERFACES[@]}"; do
        local interface="${TUN_INTERFACES[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        log_debug "Adding FORWARD rules for $interface ($slice_name)"
        sudo iptables -I FORWARD -i "$interface" -j ACCEPT
        sudo iptables -I FORWARD -o "$interface" -j ACCEPT
    done
    
    log_info "Adding NAT rules for internet access..."
    # NAT rules for internet access
    for i in "${!SUBNETS[@]}"; do
        local subnet="${SUBNETS[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        log_debug "Adding NAT rule for subnet $subnet ($slice_name)"
        sudo iptables -t nat -A POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE
    done
    
    # Optional: Add slice isolation rules (commented out by default)
    log_info "Slice isolation rules available but not applied (see script for details)"
    log_info "To enable slice isolation, uncomment the relevant section in add_slice_isolation()"
    
    log_info "${GREEN}5G testbed iptables rules added successfully!${NC}"
    
    # Show summary
    show_summary
}

# Add network slice isolation rules (optional)
add_slice_isolation() {
    log_info "Adding network slice isolation rules..."
    
    # Block inter-slice communication
    # Uncomment these lines if you want complete slice isolation
    
    # eMBB ↔ URLLC isolation
    # sudo iptables -I FORWARD -s 10.45.0.0/24 -d 10.45.1.0/24 -j DROP
    # sudo iptables -I FORWARD -s 10.45.1.0/24 -d 10.45.0.0/24 -j DROP
    
    # eMBB ↔ mMTC isolation  
    # sudo iptables -I FORWARD -s 10.45.0.0/24 -d 10.45.2.0/24 -j DROP
    # sudo iptables -I FORWARD -s 10.45.2.0/24 -d 10.45.0.0/24 -j DROP
    
    # URLLC ↔ mMTC isolation
    # sudo iptables -I FORWARD -s 10.45.1.0/24 -d 10.45.2.0/24 -j DROP
    # sudo iptables -I FORWARD -s 10.45.2.0/24 -d 10.45.1.0/24 -j DROP
    
    log_debug "Slice isolation rules are commented out - enable manually if needed"
}

# Remove 5G testbed specific rules
remove_rules() {
    print_header
    log_info "Removing 5G testbed iptables rules..."
    
    # Remove INPUT rules for TUN interfaces
    log_info "Removing INPUT rules..."
    for interface in "${TUN_INTERFACES[@]}"; do
        log_debug "Removing INPUT rules for $interface"
        while sudo iptables -C INPUT -i "$interface" -j ACCEPT 2>/dev/null; do
            sudo iptables -D INPUT -i "$interface" -j ACCEPT
        done
    done
    
    # Remove FORWARD rules for TUN interfaces  
    log_info "Removing FORWARD rules..."
    for interface in "${TUN_INTERFACES[@]}"; do
        log_debug "Removing FORWARD rules for $interface"
        # Remove inbound FORWARD rules
        while sudo iptables -C FORWARD -i "$interface" -j ACCEPT 2>/dev/null; do
            sudo iptables -D FORWARD -i "$interface" -j ACCEPT
        done
        # Remove outbound FORWARD rules
        while sudo iptables -C FORWARD -o "$interface" -j ACCEPT 2>/dev/null; do
            sudo iptables -D FORWARD -o "$interface" -j ACCEPT
        done
    done
    
    # Remove NAT rules
    log_info "Removing NAT rules..."
    local inet_iface
    inet_iface=$(get_internet_interface)
    
    for subnet in "${SUBNETS[@]}"; do
        log_debug "Removing NAT rules for subnet $subnet"
        while sudo iptables -t nat -C POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE 2>/dev/null; do
            sudo iptables -t nat -D POSTROUTING -s "$subnet" -o "$inet_iface" -j MASQUERADE
        done
    done
    
    # Remove slice isolation rules if they exist
    remove_slice_isolation
    
    log_info "${GREEN}5G testbed iptables rules removed successfully!${NC}"
    
    # Show current status
    show_status
}

# Remove slice isolation rules
remove_slice_isolation() {
    log_debug "Removing any slice isolation rules..."
    
    # Remove all possible slice isolation rules
    local subnets_arr=("10.45.0.0/24" "10.45.1.0/24" "10.45.2.0/24")
    
    for src_subnet in "${subnets_arr[@]}"; do
        for dst_subnet in "${subnets_arr[@]}"; do
            if [[ "$src_subnet" != "$dst_subnet" ]]; then
                while sudo iptables -C FORWARD -s "$src_subnet" -d "$dst_subnet" -j DROP 2>/dev/null; do
                    sudo iptables -D FORWARD -s "$src_subnet" -d "$dst_subnet" -j DROP
                done
            fi
        done
    done
}

# Show current iptables status
show_status() {
    print_header
    log_info "Current iptables status for 5G testbed:"
    
    echo -e "\n${BLUE}=== FILTER TABLE - INPUT CHAIN ===${NC}"
    sudo iptables -L INPUT -n -v --line-numbers | grep -E "(ogstun|Chain|target)" || echo "No 5G testbed rules found in INPUT chain"
    
    echo -e "\n${BLUE}=== FILTER TABLE - FORWARD CHAIN ===${NC}"
    sudo iptables -L FORWARD -n -v --line-numbers | grep -E "(ogstun|Chain|target)" || echo "No 5G testbed rules found in FORWARD chain"
    
    echo -e "\n${BLUE}=== NAT TABLE - POSTROUTING CHAIN ===${NC}"
    sudo iptables -t nat -L POSTROUTING -n -v --line-numbers | grep -E "(10\.45\.|Chain|target)" || echo "No 5G testbed rules found in NAT table"
    
    echo -e "\n${BLUE}=== IP FORWARDING STATUS ===${NC}"
    if [[ $(sysctl net.ipv4.ip_forward | cut -d= -f2 | tr -d ' ') == "1" ]]; then
        echo -e "${GREEN}IP forwarding: ENABLED${NC}"
    else
        echo -e "${RED}IP forwarding: DISABLED${NC}"
    fi
    
    echo -e "\n${BLUE}=== TUN INTERFACE STATUS ===${NC}"
    for i in "${!TUN_INTERFACES[@]}"; do
        local interface="${TUN_INTERFACES[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        if interface_exists "$interface"; then
            local ip_addr
            ip_addr=$(ip addr show "$interface" | grep -oP 'inet \K[^/]+' || echo "No IP assigned")
            echo -e "${GREEN}$interface ($slice_name): UP - IP: $ip_addr${NC}"
        else
            echo -e "${YELLOW}$interface ($slice_name): DOWN/NOT EXISTS${NC}"
        fi
    done
}

# Show configuration summary
show_summary() {
    echo -e "\n${PURPLE}=== 5G TESTBED CONFIGURATION SUMMARY ===${NC}"
    echo -e "${BLUE}Network Slices:${NC}"
    
    for i in "${!TUN_INTERFACES[@]}"; do
        local interface="${TUN_INTERFACES[$i]}"
        local subnet="${SUBNETS[$i]}"
        local slice_name="${SLICE_NAMES[$i]}"
        
        echo -e "  ${GREEN}$slice_name:${NC} $subnet → $interface"
    done
    
    echo -e "\n${BLUE}Internet Interface:${NC} $(get_internet_interface)"
    echo -e "${BLUE}IP Forwarding:${NC} $(sysctl net.ipv4.ip_forward | cut -d= -f2 | tr -d ' ')"
    echo -e "${BLUE}Backup Location:${NC} $BACKUP_DIR"
}

# List available backups
list_backups() {
    log_info "Available iptables backups:"
    if [[ -d "$BACKUP_DIR" ]]; then
        ls -la "$BACKUP_DIR"/*.rules 2>/dev/null || log_warn "No backups found"
    else
        log_warn "Backup directory does not exist"
    fi
}

# Restore from specific backup
restore_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log_info "Restoring iptables from backup: $backup_file"
    log_warn "This will replace ALL current iptables rules!"
    
    read -p "Are you sure you want to continue? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo iptables-restore < "$backup_file"
        log_info "Iptables restored successfully"
    else
        log_info "Restore cancelled"
    fi
}

# Main function
main() {
    case "${1:-}" in
        --add)
            add_rules
            ;;
        --remove)
            remove_rules
            ;;
        --status)
            show_status
            ;;
        --list-backups)
            list_backups
            ;;
        --restore)
            if [[ -z "$2" ]]; then
                log_error "Backup file path required for --restore"
                print_usage
                exit 1
            fi
            restore_backup "$2"
            ;;
        --help|help|-h)
            print_usage
            ;;
        *)
            log_error "Invalid or missing option"
            print_usage
            exit 1
            ;;
    esac
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]] && [[ -z "$SUDO_USER" ]]; then
    log_error "This script requires sudo privileges"
    exit 1
fi

# Run main function with all arguments
main "$@"
```
## open5gs\-create\-tun\-interfaces\.sh
Utility scripts to create three different TUN interfaces\, each assigned the IP from each SST\/network slices\.
* SST 1 \(eMBB\) will use ogstun interface \(IP\: 10\.45\.0\.1\/24\)
* SST 2 \(URLLC\) will use ogstun2 interface \(IP\: 10\.45\.1\.1\/24\)
* SST 3 \(mMTC\) will use ogstun3 interface \(IP\: 10\.45\.2\.1\/24\)
```code
#!/bin/bash

# Open5GS TUN Interface Management Script
# This script creates or removes TUN interfaces for each DNN in Open5GS
# Usage: 
#   sudo ./open5gs-create-tun-interfaces.sh --add     (create interfaces)
#   sudo ./open5gs-create-tun-interfaces.sh --remove  (remove interfaces)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
show_usage() {
    echo "Usage: $0 [--add|--remove]"
    echo ""
    echo "Options:"
    echo "  --add     Create TUN interfaces for Open5GS DNNs"
    echo "  --remove  Remove TUN interfaces for Open5GS DNNs"
    echo ""
    echo "TUN Interfaces managed:"
    echo "  ogstun   (10.45.0.1/24)  - eMBB slice (embb.testbed)"
    echo "  ogstun2  (10.45.1.1/24)  - URLLC slice (urllc.v2x)"
    echo "  ogstun3  (10.45.2.1/24)  - mMTC slice (mmtc.testbed)"
    echo ""
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Enable IPv4 forwarding
enable_ipv4_forwarding() {
    print_status "Enabling IPv4 forwarding..."
    
    # Enable immediately
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Make it persistent across reboots
    if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        print_success "IPv4 forwarding enabled and made persistent"
    else
        print_success "IPv4 forwarding enabled (already persistent)"
    fi
}

# Function to check if interface exists
interface_exists() {
    local interface=$1
    ip link show "$interface" &> /dev/null
}

# Function to add TUN interface
add_tun_interface() {
    local interface=$1
    local ip_addr=$2
    local subnet=$3
    local description=$4
    
    print_status "Setting up $interface ($description)..."
    
    # Check if interface exists
    if interface_exists "$interface"; then
        print_warning "Interface $interface already exists, updating IP address..."
        
        # Remove existing IP addresses
        ip addr flush dev "$interface" 2>/dev/null
        
        # Assign new IP address
        if ip addr add "$ip_addr" dev "$interface"; then
            print_success "IP address $ip_addr assigned to existing $interface"
        else
            print_error "Failed to assign IP address to $interface"
            return 1
        fi
        
        # Ensure interface is up
        ip link set "$interface" up
    else
        # Create new TUN interface
        if ip tuntap add name "$interface" mode tun; then
            print_success "TUN interface $interface created"
            
            # Assign IP address
            if ip addr add "$ip_addr" dev "$interface"; then
                print_success "IP address $ip_addr assigned to $interface"
            else
                print_error "Failed to assign IP address to $interface"
                return 1
            fi
            
            # Bring interface up
            if ip link set "$interface" up; then
                print_success "Interface $interface is now up"
            else
                print_error "Failed to bring up interface $interface"
                return 1
            fi
        else
            print_error "Failed to create TUN interface $interface"
            return 1
        fi
    fi
    
    # Add NAT rule (remove existing rule if present to avoid duplicates)
    iptables -t nat -D POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE 2>/dev/null
    
    if iptables -t nat -A POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE; then
        print_success "NAT rule added for subnet $subnet via $interface"
    else
        print_error "Failed to add NAT rule for $interface"
        return 1
    fi
    
    echo "----------------------------------------"
}

# Function to remove TUN interface
remove_tun_interface() {
    local interface=$1
    local subnet=$2
    local description=$3
    
    print_status "Removing $interface ($description)..."
    
    # Remove NAT rule
    if iptables -t nat -D POSTROUTING -s "$subnet" ! -o "$interface" -j MASQUERADE 2>/dev/null; then
        print_success "NAT rule removed for subnet $subnet"
    else
        print_warning "NAT rule for $subnet not found or already removed"
    fi
    
    # Remove interface if it exists
    if interface_exists "$interface"; then
        # Bring interface down first
        ip link set "$interface" down 2>/dev/null
        
        # Remove TUN interface
        if ip tuntap del name "$interface" mode tun; then
            print_success "TUN interface $interface removed"
        else
            print_error "Failed to remove TUN interface $interface"
            return 1
        fi
    else
        print_warning "Interface $interface does not exist"
    fi
    
    echo "----------------------------------------"
}

# Function to add all interfaces
add_all_interfaces() {
    print_status "Creating Open5GS TUN interfaces..."
    echo "=========================================="
    
    # Enable IPv4 forwarding first
    enable_ipv4_forwarding
    echo "----------------------------------------"
    
    # Interface definitions: name, ip/mask, subnet, description
    add_tun_interface "ogstun"  "10.45.0.1/24" "10.45.0.0/24" "eMBB slice (embb.testbed)"
    add_tun_interface "ogstun2" "10.45.1.1/24" "10.45.1.0/24" "URLLC slice (urllc.v2x)"
    add_tun_interface "ogstun3" "10.45.2.1/24" "10.45.2.0/24" "mMTC slice (mmtc.testbed)"
    
    echo "=========================================="
    print_success "All Open5GS TUN interfaces configured!"
    print_status "You can verify interfaces with: ip addr show | grep ogstun"
    print_status "You can verify NAT rules with: iptables -t nat -L POSTROUTING -v"
}

# Function to remove all interfaces
remove_all_interfaces() {
    print_status "Removing Open5GS TUN interfaces..."
    echo "=========================================="
    
    # Interface definitions: name, subnet, description
    remove_tun_interface "ogstun"  "10.45.0.0/24" "eMBB slice (embb.testbed)"
    remove_tun_interface "ogstun2" "10.45.1.0/24" "URLLC slice (urllc.v2x)"
    remove_tun_interface "ogstun3" "10.45.2.0/24" "mMTC slice (mmtc.testbed)"
    
    echo "=========================================="
    print_success "All Open5GS TUN interfaces removed!"
}

# Main script logic
main() {
    case "$1" in
        --add)
            check_root
            add_all_interfaces
            ;;
        --remove)
            check_root
            remove_all_interfaces
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            print_error "Invalid option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
```
## open5gs\-restart\-services\.sh
Use this utility script to restart all services provided by Open5GS\, especially after modifying any \.yaml files to ensure consistencies\.
```code
#!/bin/bash

# Open5GS Services Restart Script
# This script restarts all Open5GS related services
# Usage: sudo ./open5gs-restart-services.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_status "Starting Open5GS services restart..."
echo "=========================================="

# Reload systemd daemon to pick up any unit file changes
print_status "Reloading systemd daemon..."
systemctl daemon-reload
print_success "Systemd daemon reloaded"
echo "----------------------------------------"

# List of Open5GS services based on configuration files present
# Core Network Functions
SERVICES=(
    "open5gs-nrfd"      # Network Repository Function
    "open5gs-scpd"      # Service Communication Proxy
    "open5gs-ausfd"     # Authentication Server Function
    "open5gs-udmd"      # Unified Data Management
    "open5gs-udrd"      # Unified Data Repository
    "open5gs-pcfd"      # Policy Control Function
    "open5gs-bsfd"      # Binding Support Function
    "open5gs-nssfd"     # Network Slice Selection Function
    "open5gs-amfd"      # Access and Mobility Management Function
    "open5gs-smfd"      # Session Management Function
    "open5gs-upfd"      # User Plane Function
    "open5gs-sgwcd"     # Serving Gateway Control Plane (4G)
    "open5gs-sgwud"     # Serving Gateway User Plane (4G)
    "open5gs-mmed"      # Mobility Management Entity (4G)
    "open5gs-hssd"      # Home Subscriber Server (4G)
    "open5gs-pcrfd"     # Policy Charging Rules Function (4G)
)

# Optional SEPP services (if configured for roaming)
OPTIONAL_SERVICES=(
    "open5gs-seppd"     # Security Edge Protection Proxy
)

# Counters
success_count=0
failed_count=0
not_found_count=0

# Function to restart a service
restart_service() {
    local service_name=$1
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "^${service_name}.service"; then
        print_warning "Service ${service_name}.service not found - skipping"
        ((not_found_count++))
        return 1
    fi
    
    print_status "Restarting ${service_name}.service..."
    
    # Stop the service first
    systemctl stop "${service_name}.service"
    sleep 1
    
    # Start the service
    if systemctl restart "${service_name}.service"; then
        # Check if service is active
        if systemctl is-active --quiet "${service_name}.service"; then
            print_success "${service_name}.service restarted successfully"
            ((success_count++))
        else
            print_error "${service_name}.service failed to start properly"
            systemctl status "${service_name}.service" --no-pager -l
            ((failed_count++))
        fi
    else
        print_error "Failed to restart ${service_name}.service"
        systemctl status "${service_name}.service" --no-pager -l
        ((failed_count++))
    fi
    
    echo "----------------------------------------"
}

# Restart services in dependency order
print_status "Restarting core services..."

# Start with fundamental services first
restart_service "open5gs-nrfd"
restart_service "open5gs-scpd"

# Authentication and data management
restart_service "open5gs-ausfd"
restart_service "open5gs-udrd"
restart_service "open5gs-udmd"

# Policy and support functions  
restart_service "open5gs-pcfd"
restart_service "open5gs-bsfd"
restart_service "open5gs-nssfd"

# Core network functions
restart_service "open5gs-amfd"
restart_service "open5gs-upfd"
restart_service "open5gs-smfd"

# 4G compatibility services
restart_service "open5gs-sgwcd"
restart_service "open5gs-sgwud"
restart_service "open5gs-mmed"
restart_service "open5gs-hssd"
restart_service "open5gs-pcrfd"

# Optional services
print_status "Checking optional services..."
for service in "${OPTIONAL_SERVICES[@]}"; do
    restart_service "$service"
done

# Summary
echo "=========================================="
print_status "Restart Summary:"
echo "  - Successfully restarted: $success_count services"
echo "  - Failed to restart: $failed_count services"  
echo "  - Not found/skipped: $not_found_count services"
echo "=========================================="

if [ $failed_count -gt 0 ]; then
    print_error "Some services failed to restart. Check logs with: journalctl -u <service-name> -f"
    exit 1
else
    print_success "All available Open5GS services restarted successfully!"
    print_status "You can check service status with: sudo systemctl status open5gs-*"
fi
```

# Applying Configuration Changes

After modifying any Network Function configuration files, you must restart the corresponding service for changes to take effect.

## Restart Individual Service

To restart a specific Network Function service:

```bash
# Restart a single service
sudo systemctl restart open5gs-<service>d

# Examples:
sudo systemctl restart open5gs-amfd    # AMF
sudo systemctl restart open5gs-smfd    # SMF
sudo systemctl restart open5gs-upfd    # UPF
sudo systemctl restart open5gs-nrfd    # NRF

# Check status of restarted service
sudo systemctl status open5gs-amfd
```

## Restart All Services

To restart all Open5GS services at once (recommended after multiple configuration changes):

```bash
# Using the utility script
cd /path/to/repo/open5gs/scripts
sudo chmod +x open5gs-restart-services.sh
sudo ./open5gs-restart-services.sh
```

The restart script:
- Restarts services in proper dependency order
- Checks service health after restart
- Provides a summary of success/failures
- Automatically skips services that aren't installed

## Service Dependencies

Open5GS services have dependencies and should be restarted in this order:

1. **NRF** (Network Repository Function) - Service discovery foundation
2. **SCP** (Service Communication Proxy) - SBI routing
3. **AUSF, UDR, UDM** - Authentication and data management
4. **PCF, BSF, NSSF** - Policy and support functions
5. **AMF, UPF, SMF** - Core network functions
6. **SGWC, SGWU, MME, HSS, PCRF** - 4G/EPC functions (if used)

## Verify Configuration Changes

After restarting services, verify they're running correctly:

```bash
# Check all Open5GS services status
sudo systemctl status open5gs-*

# View real-time logs for a specific service
sudo journalctl -f -u open5gs-amfd

# Check if services are active
sudo systemctl is-active open5gs-amfd open5gs-smfd open5gs-upfd
```

## Common Issues After Configuration Changes

1. **Service fails to start**: Check configuration syntax
   ```bash
   sudo journalctl -u open5gs-amfd -n 50
   ```

2. **Port conflicts**: Ensure ports in config match across services
   ```bash
   sudo netstat -tulpn | grep 7777
   ```

3. **MongoDB connection**: Verify MongoDB is running
   ```bash
   sudo systemctl status mongod
   ```

4. **Missing dependencies**: Ensure dependent services are running first
   ```bash
   # Start NRF first, then other services
   sudo systemctl restart open5gs-nrfd
   sudo systemctl restart open5gs-amfd
   ```
