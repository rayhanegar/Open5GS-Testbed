# Open5GS on K3s with Calico Static IPs

## Overview

This deployment uses **Calico CNI** with static IP addressing to replicate the Docker Compose networking model in Kubernetes. Each Network Function (NF) gets a predictable, static IP address from the `10.10.0.0/24` subnet.

## IP Address Mapping

This deployment mirrors the Docker Compose IP scheme:

| Network Function | IP Address  | Docker Compose Port Mapping |
|------------------|-------------|----------------------------|
| MongoDB (External) | 192.168.50.200 | N/A |
| **Control Plane** |
| NRF              | 10.10.0.10  | 7710:7777 |
| SCP              | 10.10.0.200 | 7722:7777 |
| UDR              | 10.10.0.20  | 7720:7777 |
| UDM              | 10.10.0.12  | 7712:7777 |
| AUSF             | 10.10.0.11  | 7711:7777 |
| PCF              | 10.10.0.13  | 7713:7777, 9013:9090 |
| NSSF             | 10.10.0.14  | 7714:7777 |
| **Session Management** |
| AMF              | 10.10.0.5   | 7705:7777, 38412:38412 (SCTP), 9005:9090 |
| SMF              | 10.10.0.4   | 7704:7777, 8804:8805 (UDP), 2123:2123 (UDP), 9004:9090 |
| **User Plane** |
| UPF              | 10.10.0.7   | 8807:8805 (UDP), 2152:2152 (UDP), 9007:9090 |

## Key Differences from Docker Compose

### 1. **No hostNetwork Mode**
- Docker Compose: Uses host network for AMF/UPF to expose NGAP/GTP-U
- K3s+Calico: Uses **Calico static IPs** with CNI networking
- Benefits: Better isolation, no port conflicts, predictable IPs

### 2. **Static IP Assignment**
- Implemented via Calico annotations: `cni.projectcalico.org/ipAddrs`
- Each pod gets its IP before startup
- IPs persist across pod restarts (StatefulSet)

### 3. **Service Discovery**
- Docker Compose: Uses container hostnames (e.g., `nrf`, `scp`)
- K3s+Calico: Uses **direct IP addressing** in configs
- No DNS resolution delays or issues

### 4. **Network Isolation**
- Docker Compose: Bridge network `br-5gcore`
- K3s+Calico: Calico IPPool `open5gs-pool` (10.10.0.0/24)

## Prerequisites

### 1. Install K3s without Flannel
```bash
curl -sfL https://get.k3s.io | sh -s - --flannel-backend=none --disable-network-policy
```

### 2. Install Calico
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```

### 3. Verify Calico Installation
```bash
kubectl get pods -n kube-system | grep calico
# Should show calico-node and calico-kube-controllers running
```

### 4. Check Default IPPool
```bash
kubectl get ippools.crd.projectcalico.org -o yaml
```

## Deployment Steps

### Step 1: Apply Foundation Resources
```bash
cd /path/to/open5gs-k3s-calico
kubectl apply -f 00-foundation/
```

This creates:
- Namespace: `open5gs`
- Calico IPPool: `10.10.0.0/24` for static IPs
- MongoDB external endpoint
- Storage resources

### Step 2: Apply ConfigMaps
```bash
kubectl apply -f 01-configmaps/
```

All configs use static IPs instead of DNS names:
- `nrf: http://10.10.0.10:7777`
- `scp: http://10.10.0.200:7777`
- `amf: 10.10.0.5:38412` (NGAP)
- etc.

### Step 3: Deploy Control Plane
```bash
kubectl apply -f 02-control-plane/
```

Pods will be assigned static IPs via Calico annotations.

### Step 4: Deploy Session Management
```bash
kubectl apply -f 03-session-mgmt/
```

### Step 5: Deploy User Plane
```bash
kubectl apply -f 04-user-plane/
```

### Step 6: Verify Deployment
```bash
kubectl get pods -n open5gs -o wide
```

Expected output:
```
NAME     READY   STATUS    IP           NODE
nrf-0    1/1     Running   10.10.0.10   node1
scp-0    1/1     Running   10.10.0.200  node1
udr-0    1/1     Running   10.10.0.20   node1
udm-0    1/1     Running   10.10.0.12   node1
ausf-0   1/1     Running   10.10.0.11   node1
pcf-0    1/1     Running   10.10.0.13   node1
nssf-0   1/1     Running   10.10.0.14   node1
amf-0    1/1     Running   10.10.0.5    node1
smf-0    1/1     Running   10.10.0.4    node1
upf-0    1/1     Running   10.10.0.7    node1
```

## Calico Configuration Details

### IPPool Specification
```yaml
apiVersion: projectcalico.org/v3
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

### Pod Annotation for Static IP
```yaml
metadata:
  annotations:
    cni.projectcalico.org/ipAddrs: "[\"10.10.0.10\"]"
```

## Troubleshooting

### Pod Not Getting Static IP
```bash
# Check Calico node status
kubectl get pods -n kube-system -l k8s-app=calico-node

# Check pod events
kubectl describe pod <pod-name> -n open5gs

# Verify IPPool
kubectl get ippool open5gs-pool -o yaml
```

### Connectivity Issues
```bash
# Test pod-to-pod connectivity
kubectl exec -n open5gs nrf-0 -- ping -c 3 10.10.0.200

# Check routing
kubectl exec -n open5gs nrf-0 -- ip route

# Verify Calico networking
kubectl exec -n open5gs nrf-0 -- ip addr show eth0
```

### NF Registration Issues
```bash
# Check NRF logs for registrations
kubectl logs -n open5gs nrf-0 | grep "NF registered"

# Test NRF API
kubectl exec -n open5gs nrf-0 -- curl http://10.10.0.10:7777/nnrf-nfm/v1/nf-instances
```

## Advantages of Calico + Static IPs

1. **Deterministic Networking**: Same IPs across restarts
2. **No DNS Dependencies**: Direct IP addressing eliminates resolution delays
3. **Docker Compose Compatibility**: Easy migration path
4. **Simplified Debugging**: Known IPs make troubleshooting easier
5. **Better Performance**: No service proxy overhead for pod-to-pod
6. **Network Policies**: Calico enables fine-grained security policies

## Migration from hostNetwork

Previous deployment used `hostNetwork: true` for AMF/UPF:
- **Problem**: Port conflicts, single pod per node limitation
- **Solution**: Calico static IPs provide predictable addressing without host networking

### Changes Made:
```yaml
# Before (hostNetwork)
spec:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet

# After (Calico Static IP)
spec:
  hostNetwork: false
  dnsPolicy: ClusterFirst
metadata:
  annotations:
    cni.projectcalico.org/ipAddrs: "[\"10.10.0.5\"]"
```

## Accessing Services from External Devices (gNB/UE)

### Option 1: NodePort (Recommended)
Expose AMF NGAP for external access:
```bash
kubectl patch svc amf -n open5gs -p '{"spec":{"type":"NodePort","ports":[{"name":"ngap","port":38412,"targetPort":38412,"protocol":"SCTP","nodePort":38412}]}}'
```

Connect gNB to: `<node-ip>:38412`

### Option 2: LoadBalancer (Cloud)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: amf-external
  namespace: open5gs
spec:
  type: LoadBalancer
  selector:
    app: amf
  ports:
  - name: ngap
    port: 38412
    targetPort: 38412
    protocol: SCTP
```

### Option 3: Host Port Binding
Add to AMF pod spec:
```yaml
ports:
- containerPort: 38412
  hostPort: 38412
  protocol: SCTP
```

## Network Policies (Optional)

Restrict traffic between NFs:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: nrf-policy
  namespace: open5gs
spec:
  podSelector:
    matchLabels:
      app: nrf
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          component: control-plane
    ports:
    - protocol: TCP
      port: 7777
```

## Comparison Matrix

| Feature | Docker Compose | K3s + Flannel | K3s + Calico (This Deployment) |
|---------|---------------|---------------|-------------------------------|
| Static IPs | ✅ Yes | ❌ No | ✅ Yes |
| Predictable IPs | ✅ Yes | ❌ Dynamic | ✅ Yes |
| Multi-node | ❌ No | ✅ Yes | ✅ Yes |
| Host Network | ✅ Possible | ✅ Required for SCTP | ❌ Not needed |
| Network Policies | ❌ Limited | ❌ Basic | ✅ Advanced |
| IP Mobility | ❌ No | ❌ No | ✅ With StatefulSet |
| DNS Resolution | ✅ Fast | ✅ Fast | ⚡ Not needed (direct IP) |

## References

- [Calico Documentation](https://docs.tigera.io/calico/latest/about/)
- [Calico IP Address Management](https://docs.tigera.io/calico/latest/networking/ipam/)
- [Open5GS Documentation](https://open5gs.org/open5gs/docs/)
- [K3s Documentation](https://docs.k3s.io/)
