#!/bin/bash
# Verify MongoDB connectivity and configuration

echo "=== MongoDB Connectivity Test ==="
echo ""

MONGO_IP="192.168.50.200"
MONGO_PORT="27017"
MONGO_DB="open5gs"

echo "Testing connection to: mongodb://${MONGO_IP}:${MONGO_PORT}/${MONGO_DB}"
echo ""

# Test 1: Basic network connectivity
echo "Test 1: Network connectivity to ${MONGO_IP}:${MONGO_PORT}"
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${MONGO_IP}/${MONGO_PORT}" 2>/dev/null; then
    echo "✓ Port ${MONGO_PORT} is reachable"
else
    echo "✗ Cannot reach ${MONGO_IP}:${MONGO_PORT}"
    echo "  Check if MongoDB is running and firewall allows connections"
    exit 1
fi
echo ""

# Test 2: MongoDB authentication
echo "Test 2: MongoDB authentication"
if command -v mongo &> /dev/null; then
    echo "Using 'mongo' client..."
    mongo "mongodb://${MONGO_IP}:${MONGO_PORT}/${MONGO_DB}" --eval "db.stats()" --quiet
elif command -v mongosh &> /dev/null; then
    echo "Using 'mongosh' client..."
    mongosh "mongodb://${MONGO_IP}:${MONGO_PORT}/${MONGO_DB}" --eval "db.stats()" --quiet
else
    echo "⚠ No MongoDB client found (mongo or mongosh)"
    echo "  Install MongoDB client to test authentication"
    echo ""
    echo "  To install:"
    echo "    sudo apt-get install -y mongodb-clients  # Ubuntu/Debian"
    echo "    # or"
    echo "    sudo apt-get install -y mongodb-mongosh   # For mongosh"
fi
echo ""

# Test 3: Check from within cluster
echo "Test 3: Testing from within K3s cluster..."
kubectl run mongodb-test --image=mongo:5.0 --rm -i --restart=Never -n open5gs -- \
  mongo "mongodb://mongodb:27017/${MONGO_DB}" \
  --eval "print('MongoDB connection successful!'); db.stats()" \
  --quiet 2>&1

if [ $? -eq 0 ]; then
    echo "✓ MongoDB is accessible from within K3s cluster"
else
    echo "✗ MongoDB connection failed from K3s cluster"
    echo ""
    echo "Possible issues:"
    echo "  1. MongoDB is not running at ${MONGO_IP}:${MONGO_PORT}"
    echo "  2. Credentials are incorrect (current: ${MONGO_USER}:${MONGO_PASS})"
    echo "  3. Authentication source is wrong (current: admin)"
    echo "  4. Database '${MONGO_DB}' doesn't exist or user lacks permissions"
fi
echo ""

echo "=== Checking pod logs for MongoDB errors ==="
echo ""
echo "PCF pod logs:"
kubectl logs pcf-0 -n open5gs --tail=5 2>/dev/null | grep -i "mongo\|auth\|failed" || echo "No errors found or pod not ready"
echo ""
echo "UDR pod logs:"
kubectl logs udr-0 -n open5gs --tail=5 2>/dev/null | grep -i "mongo\|auth\|failed" || echo "No errors found or pod not ready"
