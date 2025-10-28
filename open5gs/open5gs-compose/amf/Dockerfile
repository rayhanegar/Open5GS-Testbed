# Dockerfile for Open5GS AMF (Access and Mobility Management Function)
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies and Open5GS AMF in a single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common gnupg && \
    add-apt-repository ppa:open5gs/latest && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        open5gs-amf \
        open5gs-common \
        gosu \
        ca-certificates \
        netbase && \
    mkdir -p /var/log/open5gs /etc/open5gs/tls /etc/open5gs/custom /var/run/open5gs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create open5gs user and group (matching systemd service) - handle case where they already exist
RUN (groupadd -r open5gs || true) && \
    (useradd -r -g open5gs -d /var/lib/open5gs -s /usr/sbin/nologin open5gs || true) && \
    chown -R open5gs:open5gs /var/log/open5gs /var/run/open5gs

# Copy AMF configuration from current directory as default
# This will be overridden by Docker Compose volume mount
COPY amf.yaml /etc/open5gs/amf.yaml

# Set proper ownership for configuration and log directories  
RUN chown -R open5gs:open5gs /etc/open5gs /var/log/open5gs

# Runtime environment defaults for entrypoint helper
ENV NF_USER=open5gs \
    NF_GROUP=open5gs \
    NF_LOG_DIR=/var/log/open5gs \
    NF_RUN_DIR=/var/run/open5gs \
    NF_CONFIG_SRC=/etc/open5gs/custom/amf.yaml \
    NF_CONFIG_DST=/etc/open5gs/amf.yaml

# Copy entrypoint helper that manages permissions when bind mounts are present
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Volumes for Docker Compose (logs will be mounted)
VOLUME ["/var/log/open5gs"]

# Expose AMF ports
# NGAP (N2 interface) - SCTP
EXPOSE 38412/sctp
# SBI (Service Based Interface) - HTTP/2  
EXPOSE 7777/tcp
# Metrics (matching systemd service)
EXPOSE 9090/tcp

# Set working directory
WORKDIR /etc/open5gs

# Health check with restart behavior similar to systemd (RestartSec=2)
HEALTHCHECK --interval=2s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep open5gs-amfd > /dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/open5gs-amfd", "-c", "/etc/open5gs/amf.yaml"]