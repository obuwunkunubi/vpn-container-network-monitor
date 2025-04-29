# 🔒 Docker VPN Container Network Monitor

A robust monitoring script that ensures your VPN container and dependent services stay connected and operational when using Docker container networks.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/Technology-Docker-blue.svg)](https://www.docker.com/)

## 📋 Overview

This script monitors a VPN container and its dependent services to ensure everything stays connected and functioning properly. It's specifically designed for container setups where dependent containers are connected to a VPN container's network, with their ports being exposed through the VPN container. If a service loses connectivity, the script will automatically attempt to restart it.

### Key Features

- ✅ Checks if VPN container is running and connected
- ✅ Verifies the VPN is actually providing an external connection
- ✅ Monitors dependent services' HTTP endpoints
- ✅ Automatically restarts failed services
- ✅ Detailed logging with timestamps and status levels

## 🛠️ Configuration

Edit the configuration section at the top of the script to match your environment:

```bash
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
```

### Configuration Options Explained

| Option | Description |
|--------|-------------|
| `VPN_CONTAINER` | Name of your Docker VPN container |
| `DEPENDENTS` | Array of services to monitor in format `"ContainerName:Port"` |
| `BASE_IP` | Local static IP address where the VPN container exposes services |
| `CHECK_URL_TIMEOUT` | Timeout for HTTP checks (in seconds) |
| `RESTART_WAIT` | Wait time after restarting containers (in seconds) |

## 🚀 Usage

1. Make the script executable:
   ```bash
   chmod +x vpn-container-network-monitor.sh
   ```

2. Run the script:
   ```bash
   ./vpn-container-network-monitor.sh
   ```

3. For automatic monitoring, add to crontab:
   ```bash
   # Run every 15 minutes
   */15 * * * * /path/to/vpn-container-network-monitor.sh >> /var/log/vpn-monitor.log 2>&1
   ```

## 🔍 Container Network Architecture

This script is specifically designed for Docker setups with the following architecture:

1. A **VPN container** that handles all external traffic
2. **Dependent containers** connected to the VPN container's network
3. All ports from dependent containers are **exposed through the VPN container**

This is a common setup for scenarios where all traffic from certain containers should be routed through a VPN. The script monitors both the VPN connectivity and the accessibility of dependent services through the VPN container's network.

## 📊 How It Works

The script follows this workflow:

1. **Check VPN Container Status**
   - Verifies if the VPN container is running
   - If not running, exits with an error

2. **Verify VPN Connectivity**
   - Tests if the VPN has an external internet connection
   - If not connected, restarts the VPN container once
   - Verifies connection again after restart

3. **Service Validation**
   - For each dependent service:
     - Checks if the container is running
     - Tests if the service is responding on its HTTP port
     - Marks failed services for restart

4. **Service Recovery**
   - Restarts all failed services
   - Re-validates services after restart
   - Reports status of each service

## 📝 Logs

The script produces detailed logs with timestamps and status levels:

```
[2025-04-29 14:30:12] [INFO] VPN monitor started
[2025-04-29 14:30:13] [INFO] VPN Connection: IP=45.12.34.56 Country=NL
[2025-04-29 14:30:14] [SUCCESS] container1 is accessible on port 7412
[2025-04-29 14:30:15] [WARN] container2 not accessible on port 6217 - marking for restart
[2025-04-29 14:30:16] [INFO] Restarting container2...
[2025-04-29 14:30:27] [SUCCESS] container2 is now accessible after restart
[2025-04-29 14:30:28] [INFO] VPN monitor finished
```

## 📜 License

MIT License - See LICENSE file for details