# Open5GS K3s Deployment Scripts

## Scripts Overview

### 1. `deploy-k3s.sh`
**Purpose:** Initial deployment of Open5GS on K3s

**What it does:**
- Creates namespace and foundation resources
- Creates ConfigMaps for all NFs
- Deploys NFs in proper order:
  1. NRF (Network Repository Function) - must be first
  2. Control Plane NFs (SCP, UDR, UDM, AUSF, PCF, NSSF)
  3. Session Management (AMF, SMF)
  4. User Plane (UPF)
- Waits for each component to be ready before proceeding

**Usage:**
```bash
./deploy-k3s.sh
```

**Prerequisites:**
- K3s cluster running
- `kubectl` configured
- MongoDB running (host-based or external)
- Container images imported to K3s containerd

---

### 2. `redeploy-k3s.sh`
**Purpose:** Complete cleanup and redeployment of all Open5GS components

**What it does:**
- Removes ALL existing Open5GS deployments:
  - Control Plane: StatefulSets (NRF, SCP, UDR, UDM, AUSF, PCF, NSSF)
  - Session Management: Deployments (AMF, SMF)
  - User Plane: DaemonSets (UPF)
- Waits for pods to terminate completely
- Calls `deploy-k3s.sh` to redeploy everything fresh

**Usage:**
```bash
./redeploy-k3s.sh
```

**When to use:**
- After updating container images
- After modifying NF configurations
- When pods are stuck with old resource references (e.g., PVC issues)
- To apply deployment manifest changes
- For troubleshooting deployment issues

**Interactive confirmation:**
The script will ask for confirmation before proceeding:
```
This will delete all Open5GS pods and redeploy. Continue? (y/n):
```

---

### 3. `build-import-containers.sh`
**Purpose:** Build Docker images and import them to K3s containerd

**What it does:**
- Checks for existing container images
- Builds images if missing (or with `--force` flag)
- Imports all NF images to K3s containerd runtime
- Shows imported images

**Usage:**
```bash
# Smart mode: builds only if images are missing
./build-import-containers.sh

# Force rebuild all images
./build-import-containers.sh --force
```

---

### 4. `setup-k3s-environment.sh`
**Purpose:** Initial K3s environment setup

**What it does:**
- Installs/configures K3s if needed
- Sets up networking requirements
- Configures system parameters for 5G core

**Usage:**
```bash
./setup-k3s-environment.sh
```

---

## Typical Workflows

### Initial Deployment
```bash
# 1. Build and import container images
./build-import-containers.sh

# 2. Deploy Open5GS
./deploy-k3s.sh

# 3. Verify deployment
kubectl get pods -n open5gs
```

### Update and Redeploy
```bash
# 1. Rebuild containers with changes
./build-import-containers.sh --force

# 2. Clean up and redeploy
./redeploy-k3s.sh

# 3. Check status
kubectl get pods -n open5gs -w
```

### Troubleshooting Stuck Pods
```bash
# Check what's wrong
kubectl describe pod <pod-name> -n open5gs

# Force cleanup and redeploy
./redeploy-k3s.sh
```

### Configuration Changes Only
```bash
# 1. Update ConfigMaps
kubectl apply -f 01-configmaps/

# 2. Redeploy to pick up new configs
./redeploy-k3s.sh
```

---

## Storage Configuration

**Current Setup:** hostPath volumes (K3s compatible)
- **Host directory:** `/mnt/data/open5gs-logs`
- **Access mode:** Direct hostPath (not PVC)
- **Shared:** All pods write to subdirectories

**Why hostPath?**
K3s's `local-path` provisioner doesn't support `ReadWriteMany` access mode, which is required for multiple pods to write logs to the same volume. Using hostPath bypasses this limitation.

---

## Common Issues

### Issue: Pods stuck in "Pending" state
**Cause:** Old PVC references or missing resources

**Solution:**
```bash
./redeploy-k3s.sh
```

### Issue: "Image not found" errors
**Cause:** Container images not imported to K3s

**Solution:**
```bash
./build-import-containers.sh
```

### Issue: NRF not starting
**Cause:** MongoDB connection issues or NRF must start first

**Solution:**
1. Check MongoDB connectivity
2. Ensure NRF deploys before other NFs
3. Check logs: `kubectl logs nrf-0 -n open5gs`

---

## Monitoring Commands

```bash
# Watch all pods
kubectl get pods -n open5gs -w

# Check specific pod logs
kubectl logs <pod-name> -n open5gs --tail=50 -f

# Describe pod for troubleshooting
kubectl describe pod <pod-name> -n open5gs

# Check all services
kubectl get svc -n open5gs

# View ConfigMaps
kubectl get cm -n open5gs

# Check host logs directly
ls -lh /mnt/data/open5gs-logs/
tail -f /mnt/data/open5gs-logs/<nf-name>/<nf-name>.log
```
