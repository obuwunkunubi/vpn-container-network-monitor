#!/bin/bash
#
# Docker VPN Container Network Monitor
# This script monitors a VPN container and dependent services,
# checking connectivity and restarting services when necessary.
# Specifically designed for Docker container networks where
# dependent containers are connected to a VPN container's network.
# 
# Author: Marko Bakan [obuwunkunubi] - https://github.com/obuwunkunubi
# License: MIT

# ===================== CONFIGURATION =====================
# VPN container name
VPN_CONTAINER="vpn-container"

# Dependent services in the format "ContainerName:Port"
DEPENDENTS=(
  "container1:7412"
  "container2:6217"
  "container3:9145"
  "container4:8320"
  "container5:5619"
)

# Base IP for service checks
BASE_IP="192.168.1.100"

# Timeout for URL connection checks (seconds)
CHECK_URL_TIMEOUT=5

# Wait time after container restart (seconds)
RESTART_WAIT=10

# ===================== HELPER FUNCTIONS =====================
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${2:-INFO}] $1"
}

log_info() {
  log "$1" "INFO"
}

log_warn() {
  log "$1" "WARN"
}

log_error() {
  log "$1" "ERROR"
}

log_success() {
  log "$1" "SUCCESS"
}

# Check if a container is running
# Returns 0 if running, 1 if not
is_running() {
  docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null | grep -q true
}

# Check VPN connection status using external IP service
check_vpn_connection() {
  if ip_info=$(docker exec "$VPN_CONTAINER" wget -qO- ipinfo.io 2>/dev/null); then
    ip=$(echo "$ip_info" | grep -o '"ip": *"[^"]*"' | cut -d'"' -f4)
    country=$(echo "$ip_info" | grep -o '"country": *"[^"]*"' | cut -d'"' -f4)
    log_info "VPN Connection: IP=$ip Country=$country"
    return 0
  else
    log_error "VPN has no external connection"
    return 1
  fi
}

# Check if a service is responding on its HTTP port
check_service() {
  local name=$1
  local port=$2
  curl -s -f --max-time $CHECK_URL_TIMEOUT "http://${BASE_IP}:${port}/" >/dev/null
}

# ===================== MAIN SCRIPT =====================
log_info "VPN monitor started"

# Check if VPN container is running
if ! is_running "$VPN_CONTAINER"; then
  log_error "VPN container '$VPN_CONTAINER' is not running. Exiting."
  log_info "VPN monitor finished"
  exit 1
fi

# Check VPN connectivity and restart if needed
if ! check_vpn_connection; then
  log_warn "Restarting VPN container..."
  docker restart "$VPN_CONTAINER" >/dev/null
  sleep $RESTART_WAIT
  
  if ! check_vpn_connection; then
    log_error "VPN still not connected after restart. Exiting."
    log_info "VPN monitor finished"
    exit 1
  fi
fi

# Check dependent services
to_restart=()
for entry in "${DEPENDENTS[@]}"; do
  name=${entry%%:*}
  port=${entry#*:}

  # Skip if service is not running
  if ! is_running "$name"; then
    log_warn "SKIP: $name is not running"
    continue
  fi

  # Check HTTP accessibility
  if check_service "$name" "$port"; then
    log_success "$name is accessible on port $port"
  else
    log_warn "$name not accessible on port $port - marking for restart"
    to_restart+=("$name")
  fi
done

# Restart failed services if any
if (( ${#to_restart[@]} > 0 )); then
  for container in "${to_restart[@]}"; do
    log_info "Restarting $container..."
    docker restart "$container" >/dev/null
  done

  sleep $RESTART_WAIT

  # Recheck services after restart
  for entry in "${DEPENDENTS[@]}"; do
    name=${entry%%:*}
    port=${entry#*:}
    
    if [[ " ${to_restart[*]} " =~ " $name " ]]; then
      if check_service "$name" "$port"; then
        log_success "$name is now accessible after restart"
      else
        log_error "$name still not accessible on port $port after restart"
      fi
    fi
  done
else
  log_success "All dependent services are healthy"
fi

# Final message before exiting
log_info "VPN monitor finished"