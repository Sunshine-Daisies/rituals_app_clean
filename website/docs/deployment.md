---
sidebar_position: 4
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Deployment Guide

This guide explains how to deploy the Rituals App backend server. It covers both **Local Development Hosting** (for testing with friends) and **Cloud Deployment** (for production).

## Option 1: Local Machine as Server (Self-Hosting)

If you want to host the backend on your own computer and access it from a mobile device or the internet, follow these steps.

<FullscreenDiagram definition={`
flowchart LR
    Mobile["Mobile App (4G/WiFi)"] -->|Internet| Router["Home Router"]
    
    subgraph LocalMachine ["Your PC (Local Machine)"]
        direction TB
        Docker["Docker Container"]
        Node["Node.js Server"]
    end
    
    Router -->|"Port Forwarding :3000"| Docker
    Docker --> Node
    
    style Router fill:#ffcc80,stroke:#e65100
    style LocalMachine fill:#e1f5fe,stroke:#01579b
`} />

### 1. Port Forwarding (Router Configuration) ⚠️ REQUIRED

To make your local server (running on port 3000) accessible from the outside world, you need to configure Port Forwarding on your router.

1.  Access your Router Admin Panel (usually `192.168.1.1` or `192.168.0.1`).
2.  Navigate to **Port Forwarding** / **Virtual Server** / **NAT**.
3.  Add a new rule:
    *   **External Port:** 3000
    *   **Internal IP:** Your computer's local IP (e.g., `192.168.1.128`)
    *   **Internal Port:** 3000
    *   **Protocol:** TCP
    *   **Service Name:** Rituals API

### 2. Find Your Public IP

You need to know your public IP address to connect from outside.

```powershell
# Get Public IP via PowerShell
$publicIp = Invoke-RestMethod -Uri "https://api.ipify.org"
Write-Host "Public IP: $publicIp"
```

### 3. DNS Configuration (Cloudflare)

If you have a domain name, you can point it to your public IP.

*   **Type:** A Record
*   **Name:** api (e.g., `api.yourdomain.com`)
*   **Content:** Your PUBLIC_IP_ADDRESS
*   **Proxy Status:** DNS Only (Gray Cloud) - *Initially keep proxy off for direct connection testing*
*   **TTL:** Auto

### 4. Testing the Connection

**Test Port Forwarding (from mobile network):**
```bash
curl http://YOUR_PUBLIC_IP:3000/api/badges
```

---

## Option 2: Cloud Deployment (VPS) ☁️

For a production-ready environment, we recommend using a Virtual Private Server (VPS) like DigitalOcean, AWS EC2, or Hetzner.

### Recommended Stack
*   **OS:** Ubuntu 22.04 LTS
*   **Runtime:** Docker & Docker Compose
*   **Reverse Proxy:** Nginx (for SSL/HTTPS)

### Deployment Steps

1.  **Provision Server:** Buy a VPS (e.g., $5/mo droplet).
2.  **Install Docker:**
    ```bash
    apt update && apt install docker.io docker-compose
    ```
3.  **Clone Repository:**
    ```bash
    git clone https://github.com/your-repo/rituals-backend.git
    cd rituals-backend
    ```
4.  **Configure Environment:**
    Create `.env` file with production values.
5.  **Run with Docker Compose:**
    ```bash
    docker-compose -f docker-compose.prod.yml up -d
    ```


**Test Domain:**
```bash
curl https://api.yourdomain.com/api/badges
```

### 5. Update Flutter App Configuration

Update the API URL in your Flutter application to point to the production server.

File: `lib/services/api_service.dart`

```dart
// api_service.dart
static const String _productionUrl = 'https://api.yourdomain.com/api';

// Use this URL when building for release
static String get baseUrl {
  if (kReleaseMode) return _productionUrl;
  return _localUrl;
}
```
