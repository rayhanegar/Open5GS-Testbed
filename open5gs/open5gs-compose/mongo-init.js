// MongoDB initialization script for Open5GS
db = db.getSiblingDB('open5gs');

// Create user for Open5GS
db.createUser({
  user: "open5gs",
  pwd: "open5gs123",
  roles: [
    {
      role: "readWrite",
      db: "open5gs"
    }
  ]
});

// Create collections for different NFs
db.createCollection("subscribers");
db.createCollection("profiles");
db.createCollection("sessions");
db.createCollection("policies");

// Insert a sample subscriber for testing
db.subscribers.insertOne({
  imsi: "001010000000001",
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
  slice: [
    {
      sst: 1,
      default_indicator: true,
      session: [
        {
          name: "internet",
          type: 3,
          qos: {
            index: 9,
            arp: {
              priority_level: 8,
              pre_emption_capability: 1,
              pre_emption_vulnerability: 1
            }
          },
          ambr: {
            downlink: { value: 1, unit: 3 },
            uplink: { value: 1, unit: 3 }
          }
        }
      ]
    }
  ]
});

print("Open5GS database initialized successfully!");