# Deployment Hardening Guide - Catalytic Customer

**Purpose:** Production-grade deployment checklist covering infrastructure, security, monitoring, and operational best practices.

---

## Overview

This guide covers hardening steps beyond the base alpha implementation to ensure the system is production-ready for deployment to `catalytic.learnstream.tech`.

**Deployment Environment:**
- Server: Ubuntu/Debian VPS or cloud instance
- Domain: catalytic.learnstream.tech
- TLS: Automatic via Caddy Let's Encrypt
- Authentication: Caddy basic auth + Google OAuth

---

## Part 1: Infrastructure Setup

### Server Requirements

**Minimum Specs:**
- 2 CPU cores
- 4 GB RAM
- 20 GB storage (includes database, logs, backups)
- Ubuntu 20.04 LTS or later

**Recommended Specs:**
- 4 CPU cores
- 8 GB RAM
- 50 GB storage
- Ubuntu 22.04 LTS

### Initial Server Configuration

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose v2
sudo apt install docker-compose-plugin

# Verify installation
docker --version
docker compose version

# Install UFW firewall
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable
```

### DNS Configuration

Point domain to server IP:

```
# A record
catalytic.learnstream.tech → <SERVER_IP>

# Optional: Add CAA record for Let's Encrypt
catalytic.learnstream.tech CAA 0 issue "letsencrypt.org"
```

**Verification:**
```bash
dig +short catalytic.learnstream.tech
# Should return your server IP
```

---

## Part 2: Environment Configuration

### Step 1: Generate Caddy Password Hashes

```bash
# Install Caddy locally to generate hashes
# (or use Docker)
docker run --rm caddy:2-alpine caddy hash-password --plaintext "apolo-password"
docker run --rm caddy:2-alpine caddy hash-password --plaintext "paul-password"
docker run --rm caddy:2-alpine caddy hash-password --plaintext "curtis-password"
```

Copy the bcrypt hashes (start with `$2a$14$...`).

### Step 2: Create Production .env File

Create `.env.prod` with production values:

```bash
# Domain
DOMAIN=catalytic.learnstream.tech

# Caddy Admin Credentials (bcrypt hashes)
APOLO_HASH='$2a$14$...'
PAUL_HASH='$2a$14$...'
CURTIS_HASH='$2a$14$...'

# Google OAuth (production)
GOOGLE_CLIENT_ID=prod-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=prod-secret
GOOGLE_REDIRECT_URI=https://catalytic.learnstream.tech/api/auth/callback

# Database
DATABASE_PATH=/data/catalytic.db

# Email (production)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=noreply@learnstream.tech
MAIL_PASSWORD=<gmail-app-password>
MAIL_FROM=noreply@learnstream.tech

# Security
SESSION_SECRET=$(openssl rand -hex 32)
ADMIN_SESSION_EXPIRY=86400  # 24 hours

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60
REGISTRATION_COOLDOWN_MINUTES=5
```

### Step 3: Validate Environment Variables

Create validation script:

```bash
#!/bin/bash
# scripts/validate-env.sh

check_var() {
    if [ -z "${!1}" ]; then
        echo "❌ Missing: $1"
        return 1
    else
        echo "✅ Set: $1"
        return 0
    fi
}

source .env.prod

check_var DOMAIN
check_var APOLO_HASH
check_var PAUL_HASH
check_var CURTIS_HASH
check_var GOOGLE_CLIENT_ID
check_var GOOGLE_CLIENT_SECRET
check_var MAIL_USERNAME
check_var MAIL_PASSWORD

echo ""
echo "Environment validation complete."
```

Run before deployment:
```bash
chmod +x scripts/validate-env.sh
./scripts/validate-env.sh
```

---

## Part 3: Caddy Configuration Hardening

### Enhanced Caddyfile for Production

```caddyfile
# Caddyfile (production)

{
    # Global options
    email admin@learnstream.tech

    # Security headers
    servers {
        protocols h1 h2 h3
    }
}

{$DOMAIN} {
    # Enable automatic HTTPS
    # Caddy automatically obtains Let's Encrypt certificate

    # Security headers (applied to all routes)
    header {
        # Prevent clickjacking
        X-Frame-Options "DENY"

        # Prevent MIME type sniffing
        X-Content-Type-Options "nosniff"

        # Enable XSS protection
        X-XSS-Protection "1; mode=block"

        # HSTS (HTTPS only, 1 year)
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

        # Referrer policy
        Referrer-Policy "strict-origin-when-cross-origin"

        # Content Security Policy (adjust as needed)
        Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' wss://{$DOMAIN}"

        # Remove server header
        -Server
    }

    # Request logging
    log {
        output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
        }
        format json
    }

    # Rate limiting (requires caddy-rate-limit plugin - optional)
    # rate_limit {
    #     zone requests {
    #         key {remote_host}
    #         events 100
    #         window 1m
    #     }
    # }

    # Admin routes - double authentication
    handle /admin* {
        basicauth {
            apolo {$APOLO_HASH}
            paul {$PAUL_HASH}
            curtis {$CURTIS_HASH}
        }
        reverse_proxy frontend-admin:3001
    }

    # Admin API - double authentication
    handle /api/admin/* {
        basicauth {
            apolo {$APOLO_HASH}
            paul {$PAUL_HASH}
            curtis {$CURTIS_HASH}
        }
        reverse_proxy backend:8000
    }

    # Backend API - public routes
    handle /api/* {
        reverse_proxy backend:8000
    }

    # Session interface
    handle /session* {
        reverse_proxy placeholder-agent:3002
    }

    # Public frontend
    handle /* {
        reverse_proxy frontend-public:3000
    }
}
```

### Verify Caddy Configuration

```bash
# Before deployment, test Caddyfile syntax
docker run --rm -v $(pwd)/Caddyfile:/etc/caddy/Caddyfile caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile
```

---

## Part 4: Docker Compose Hardening

### Production docker-compose.yml

```yaml
services:
  caddy:
    image: caddy:2-alpine
    container_name: catalytic-caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"  # HTTP/3 support
    environment:
      - DOMAIN=${DOMAIN}
      - APOLO_HASH=${APOLO_HASH}
      - PAUL_HASH=${PAUL_HASH}
      - CURTIS_HASH=${CURTIS_HASH}
    env_file:
      - .env.${ENV:-dev}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
      - caddy_logs:/var/log/caddy
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:2019/config/"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: catalytic-backend
    restart: unless-stopped
    env_file:
      - .env.${ENV:-dev}
    volumes:
      - ./data:/data
      - ./logs/backend:/app/logs
    networks:
      - app_network
    depends_on:
      - caddy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

  frontend-public:
    build: ./frontend-public
    container_name: catalytic-frontend-public
    restart: unless-stopped
    env_file:
      - .env.${ENV:-dev}
    networks:
      - app_network
    depends_on:
      - backend
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  frontend-admin:
    build: ./frontend-admin
    container_name: catalytic-frontend-admin
    restart: unless-stopped
    env_file:
      - .env.${ENV:-dev}
    networks:
      - app_network
    depends_on:
      - backend
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

volumes:
  caddy_data:
    driver: local
  caddy_config:
    driver: local
  caddy_logs:
    driver: local

networks:
  app_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.25.0.0/16
```

### Key Hardening Features

1. **Health Checks:** Automatic container restart on failure
2. **Resource Limits:** Prevent single container from consuming all resources
3. **Restart Policy:** `unless-stopped` ensures containers restart on boot
4. **Read-Only Volumes:** Caddyfile mounted as `:ro` (read-only)
5. **Named Containers:** Easier to identify in logs
6. **Isolated Network:** Custom subnet for app isolation

---

## Part 5: Database Security & Backup

### Enable WAL Mode (Performance + Concurrency)

```python
# backend/services/db.py
import sqlite3

conn = sqlite3.connect(DATABASE_PATH)
conn.execute("PRAGMA journal_mode=WAL")
conn.execute("PRAGMA synchronous=NORMAL")  # Balance between speed and safety
conn.execute("PRAGMA cache_size=-64000")   # 64MB cache
conn.execute("PRAGMA temp_store=MEMORY")   # Faster temp operations
conn.commit()
```

### Automated Backup Strategy

#### Option 1: Host Cron Job

```bash
# /etc/cron.d/catalytic-backup
0 2 * * * root docker exec catalytic-backend sqlite3 /data/catalytic.db ".backup /data/backups/catalytic_$(date +\%Y\%m\%d_\%H\%M\%S).db"

# Keep only last 30 days of backups
0 3 * * * root find /path/to/data/backups/ -name "catalytic_*.db" -mtime +30 -delete
```

#### Option 2: Container-Based Backup Service

Add to `docker-compose.yml`:

```yaml
services:
  backup:
    image: alpine:latest
    container_name: catalytic-backup
    restart: unless-stopped
    volumes:
      - ./data:/data
      - ./backups:/backups
    networks:
      - app_network
    entrypoint: |
      /bin/sh -c "
      apk add --no-cache sqlite
      while true; do
        echo 'Running backup...'
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        sqlite3 /data/catalytic.db \".backup /backups/catalytic_$TIMESTAMP.db\"
        echo 'Backup complete: catalytic_$TIMESTAMP.db'
        # Keep only last 30 backups
        ls -t /backups/catalytic_*.db | tail -n +31 | xargs rm -f
        sleep 86400  # Run daily
      done
      "
```

### Off-Site Backup (Recommended)

```bash
#!/bin/bash
# scripts/offsite-backup.sh

# Sync to S3 (requires aws-cli configured)
aws s3 sync ./backups/ s3://catalytic-backups/ --delete

# Or rsync to remote server
rsync -avz --delete ./backups/ user@backup-server:/backups/catalytic/
```

---

## Part 6: Monitoring & Logging

### Application Logging

```python
# backend/main.py
import logging
from logging.handlers import RotatingFileHandler

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        RotatingFileHandler(
            '/app/logs/app.log',
            maxBytes=10485760,  # 10MB
            backupCount=5
        ),
        logging.StreamHandler()  # Also log to console
    ]
)

logger = logging.getLogger("catalytic")
```

### Docker Logs

```bash
# View live logs
docker compose logs -f

# View specific service
docker compose logs -f backend

# Save logs to file
docker compose logs > logs/docker-$(date +%Y%m%d).log
```

### Monitoring Script

```bash
#!/bin/bash
# scripts/monitor.sh

echo "=== Catalytic Customer Health Check ==="
echo ""

# Check if containers are running
echo "Containers:"
docker compose ps

echo ""

# Check disk usage
echo "Disk Usage:"
df -h /data

echo ""

# Check database size
echo "Database Size:"
du -h /data/catalytic.db

echo ""

# Check recent errors in logs
echo "Recent Errors (last 10):"
docker compose logs --tail=100 | grep -i error | tail -10

echo ""

# Check WebSocket connections
echo "Active WebSocket Connections:"
docker exec catalytic-backend netstat -tn | grep :8000 | wc -l
```

Run via cron:
```bash
# /etc/cron.d/catalytic-monitor
*/15 * * * * root /path/to/scripts/monitor.sh >> /var/log/catalytic-health.log
```

---

## Part 7: Security Hardening

### SSL/TLS Configuration

Caddy handles this automatically, but verify:

```bash
# Test SSL configuration
curl -vI https://catalytic.learnstream.tech 2>&1 | grep -E "SSL|TLS"

# Check SSL rating (external tool)
# https://www.ssllabs.com/ssltest/analyze.html?d=catalytic.learnstream.tech
```

**Target:** A+ rating on SSL Labs

### Rate Limiting (Application Level)

```python
# backend/middleware/rate_limit.py
from fastapi import Request, HTTPException
from datetime import datetime, timedelta
from collections import defaultdict

# Simple in-memory rate limiter (use Redis in production for multi-instance)
request_counts = defaultdict(list)

async def rate_limit_middleware(request: Request, call_next):
    """Limit requests per IP address"""
    client_ip = request.client.host
    now = datetime.now()
    minute_ago = now - timedelta(minutes=1)

    # Clean old requests
    request_counts[client_ip] = [
        req_time for req_time in request_counts[client_ip]
        if req_time > minute_ago
    ]

    # Check limit
    if len(request_counts[client_ip]) >= 60:  # 60 requests per minute
        raise HTTPException(status_code=429, detail="Too many requests")

    # Record this request
    request_counts[client_ip].append(now)

    response = await call_next(request)
    return response

# Add to FastAPI app
app.middleware("http")(rate_limit_middleware)
```

### Firewall Rules (UFW)

```bash
# Additional security rules
sudo ufw deny from <suspicious-ip>

# Allow only specific IPs to access SSH (optional)
sudo ufw delete allow 22/tcp
sudo ufw allow from <your-ip> to any port 22

# Rate limit SSH attempts
sudo ufw limit 22/tcp
```

### Security Headers Verification

```bash
# Check security headers
curl -I https://catalytic.learnstream.tech | grep -E "X-Frame-Options|X-Content-Type-Options|Strict-Transport-Security"
```

Expected:
```
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

---

## Part 8: Pre-Launch Checklist

### Infrastructure

- [ ] Server provisioned with minimum specs (2 CPU, 4GB RAM, 20GB disk)
- [ ] Docker and Docker Compose installed
- [ ] UFW firewall configured and enabled
- [ ] DNS A record pointing to server IP
- [ ] DNS propagation verified (`dig catalytic.learnstream.tech`)

### Environment & Configuration

- [ ] `.env.prod` created with all required variables
- [ ] Caddy password hashes generated for Apolo, Paul, Curtis
- [ ] Google OAuth credentials configured (production redirect URI)
- [ ] Gmail SMTP app password generated
- [ ] SPF, DKIM, DMARC DNS records added
- [ ] Environment validation script passes

### Application

- [ ] Caddyfile validated (`caddy validate`)
- [ ] Docker Compose file configured with health checks and resource limits
- [ ] All containers built and tested locally
- [ ] Database initialized with schema
- [ ] WAL mode enabled on SQLite
- [ ] Backup script tested and cron job scheduled

### Security

- [ ] TLS certificate obtained (automatic via Caddy)
- [ ] SSL Labs rating A+ achieved
- [ ] Security headers verified
- [ ] Rate limiting implemented (application or Caddy)
- [ ] Admin routes protected with double authentication (basic auth + OAuth)
- [ ] Session tokens use cryptographically secure random generation

### Email & Deliverability

- [ ] Test email sent to Gmail, Outlook, Yahoo accounts
- [ ] All emails landing in inbox (not spam)
- [ ] Mail-Tester.com score ≥ 8/10
- [ ] Email headers show `spf=pass`, `dkim=pass`, `dmarc=pass`

### Monitoring & Logging

- [ ] Application logging configured with rotation
- [ ] Docker logs retention policy set
- [ ] Health check monitoring script scheduled
- [ ] Off-site backup configured (S3 or remote server)

### Testing

- [ ] Full user flow tested end-to-end (registration → email → session → completion)
- [ ] Admin dashboard tested with all three admin accounts
- [ ] WebSocket real-time updates verified
- [ ] Token expiration (30 days) tested
- [ ] Session expiration (1 hour) tested
- [ ] Multiple concurrent sessions tested

---

## Part 9: Deployment Commands

### Initial Deployment

```bash
# On server, clone repository
git clone https://github.com/yourusername/catalytic-customer.git
cd catalytic-customer

# Copy environment file
cp .env.example .env.prod
nano .env.prod  # Edit with production values

# Create data and backup directories
mkdir -p data backups logs/backend

# Build and start services
ENV=prod docker compose up -d

# Wait for Let's Encrypt certificate
docker compose logs -f caddy | grep -i certificate

# Verify all containers running
docker compose ps

# Check health
./scripts/monitor.sh
```

### Updates & Maintenance

```bash
# Pull latest changes
git pull origin main

# Rebuild containers
ENV=prod docker compose build

# Restart with zero downtime (depends on setup)
ENV=prod docker compose up -d --no-deps backend

# View logs
docker compose logs -f

# Manual backup
docker exec catalytic-backend sqlite3 /data/catalytic.db ".backup /data/backups/manual_$(date +%Y%m%d_%H%M%S).db"
```

### Rollback Procedure

```bash
# Restore from backup
docker compose down
cp backups/catalytic_YYYYMMDD_HHMMSS.db data/catalytic.db
ENV=prod docker compose up -d

# Verify integrity
docker exec catalytic-backend sqlite3 /data/catalytic.db "PRAGMA integrity_check"
```

---

## Part 10: Post-Launch Monitoring

### Week 1 Tasks

- [ ] Monitor email deliverability rates daily
- [ ] Check disk usage growth
- [ ] Review application logs for errors
- [ ] Test backup restoration process
- [ ] Monitor WebSocket connection stability
- [ ] Track user registration → completion funnel

### Ongoing Maintenance

- **Daily:** Review error logs
- **Weekly:** Verify backups exist and are restorable
- **Monthly:** Update Docker images and rebuild containers
- **Quarterly:** Review and rotate admin credentials

---

**Status:** Production deployment checklist complete. All hardening measures documented and ready for implementation.
