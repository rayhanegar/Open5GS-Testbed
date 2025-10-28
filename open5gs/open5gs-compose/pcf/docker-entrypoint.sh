#!/usr/bin/env bash
set -euo pipefail

NF_USER=${NF_USER:-open5gs}
NF_GROUP=${NF_GROUP:-open5gs}
LOG_DIR=${NF_LOG_DIR:-/var/log/open5gs}
RUN_DIR=${NF_RUN_DIR:-/var/run/open5gs}
CONFIG_SRC=${NF_CONFIG_SRC:-/etc/open5gs/custom/pcf.yaml}
CONFIG_DST=${NF_CONFIG_DST:-/etc/open5gs/pcf.yaml}

mkdir -p "${LOG_DIR}" "${RUN_DIR}" "$(dirname "${CONFIG_DST}")"
chown -R "${NF_USER}:${NF_GROUP}" "${LOG_DIR}" "${RUN_DIR}"

if [ -f "${CONFIG_SRC}" ]; then
  cp "${CONFIG_SRC}" "${CONFIG_DST}"
  chown "${NF_USER}:${NF_GROUP}" "${CONFIG_DST}"
fi

exec gosu "${NF_USER}:${NF_GROUP}" "$@"
