#!/bin/bash

set -e  # Exit on error

# Get the script directory and navigate to open5gs-containers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINERS_DIR="${SCRIPT_DIR}/../open5gs-containers"

# Parse command line flags
FORCE_REBUILD=false
if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
    FORCE_REBUILD=true
    echo "Force rebuild mode enabled"
fi

cd "${CONTAINERS_DIR}"

# List of all NF containers
NF_CONTAINERS=(nrf scp udr udm ausf pcf nssf amf smf upf)

# Check if any images are missing
MISSING_IMAGES=()
ALL_EXIST=true

echo "Checking existing images..."
for nf in "${NF_CONTAINERS[@]}"; do
    IMAGE_NAME="open5gs-${nf}:latest"
    if docker image inspect "${IMAGE_NAME}" > /dev/null 2>&1; then
        echo "✓ ${IMAGE_NAME} exists"
    else
        echo "✗ ${IMAGE_NAME} not found"
        MISSING_IMAGES+=("${nf}")
        ALL_EXIST=false
    fi
done

# Decide whether to build
SHOULD_BUILD=false

if [ "$FORCE_REBUILD" = true ]; then
    SHOULD_BUILD=true
    echo ""
    echo "Force rebuild requested."
elif [ "$ALL_EXIST" = false ]; then
    SHOULD_BUILD=true
    echo ""
    echo "Missing images detected: ${MISSING_IMAGES[*]}"
    echo "Build is required."
else
    echo ""
    echo "All container images already exist."
    read -p "Rebuild all containers? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SHOULD_BUILD=true
    else
        echo "Skipping build."
    fi
fi

# Build containers if needed
if [ "$SHOULD_BUILD" = true ]; then
    echo ""
    echo "Found Dockerfiles:"
    ls -la */Dockerfile 2>/dev/null || echo "No Dockerfiles found!"
    
    echo ""
    echo "Building containers with docker compose..."
    docker compose build
    
    echo ""
    echo "Built Open5GS images:"
    docker images | grep open5gs
else
    echo ""
    echo "Using existing images."
fi

# Import each container to k3s containerd
echo ""
echo "Importing containers to k3s..."

for nf in "${NF_CONTAINERS[@]}"; do
    IMAGE_NAME="open5gs-${nf}:latest"
    echo "Importing ${IMAGE_NAME}..."
    if docker image inspect "${IMAGE_NAME}" > /dev/null 2>&1; then
        docker save "${IMAGE_NAME}" | sudo k3s ctr images import -
        echo "✓ Successfully imported ${IMAGE_NAME}"
    else
        echo "✗ Warning: ${IMAGE_NAME} not found, skipping..."
    fi
done

# Verify imported images in k3s
echo ""
echo "Imported images in k3s containerd:"
sudo k3s ctr images ls | grep open5gs

echo ""
echo "Build and import complete!"
echo ""
echo "Usage: $0 [--force|-f]"
echo "  --force, -f : Force rebuild all containers without prompting"