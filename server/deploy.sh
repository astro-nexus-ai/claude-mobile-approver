#!/bin/bash
# Deploy Claude Mobile Approver server components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_DIR/config/server.env" ]; then
    source "$PROJECT_DIR/config/server.env"
else
    echo "Error: config/server.env not found"
    echo "Please copy config/server.env.example to config/server.env and configure it"
    exit 1
fi

# Create directories
sudo mkdir -p /opt/claude-approver/approvals
sudo mkdir -p /opt/ntfy

# Copy approval server
sudo cp "$SCRIPT_DIR/app.py" /opt/claude-approver/

# Create systemd service for approval server
sudo tee /etc/systemd/system/claude-approver.service > /dev/null << 'EOF'
[Unit]
Description=Claude Code Approval Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/claude-approver
Environment="APPROVAL_DIR=/opt/claude-approver/approvals"
Environment="NTFY_SERVER=http://localhost:2586"
Environment="NTFY_USER=claude"
Environment="NTFY_PASS=YOUR_PASSWORD_HERE"
Environment="NTFY_TOPIC=claude-approve"
Environment="PORT=2587"
ExecStart=/usr/bin/python3 /opt/claude-approver/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Update password in service file
sudo sed -i "s/YOUR_PASSWORD_HERE/$NTFY_PASS/g" /etc/systemd/system/claude-approver.service

# Setup ntfy Docker
if [ ! -f /opt/ntfy/server.yml ]; then
    sudo tee /opt/ntfy/server.yml > /dev/null << EOF
# ntfy server configuration
listen-http: ":2586"

# Auth settings
auth-file: /opt/ntfy/user.db
auth-default-access: deny-all

# Rate limiting (relaxed for personal use)
visitor-request-limit-burst: 100
visitor-request-limit-replenish: 1s
visitor-email-limit-burst: 10

# Behind proxy (if using nginx)
# behind-proxy: true
EOF
fi

# Create docker-compose for ntfy
sudo tee /opt/ntfy/docker-compose.yml > /dev/null << 'EOF'
version: '3'
services:
  ntfy:
    image: binwiederhier/ntfy
    command: serve
    ports:
      - "2586:2586"
    volumes:
      - ./server.yml:/etc/ntfy/server.yml
      - ./user.db:/opt/ntfy/user.db
    restart: unless-stopped
EOF

# Create ntfy user if not exists
if ! sudo docker ps | grep -q ntfy; then
    echo "Setting up ntfy..."
    cd /opt/ntfy
    sudo docker compose up -d
    sleep 3

    # Create user
    sudo docker exec ntfy-ntfy-1 ntfy user add --role=admin "$NTFY_USER" <<< "$NTFY_PASS"
    echo "Created ntfy user: $NTFY_USER"
fi

# Reload and start approval server
sudo systemctl daemon-reload
sudo systemctl enable claude-approver
sudo systemctl restart claude-approver

echo ""
echo "=== Deployment Complete ==="
echo "ntfy server: http://$(hostname -I | awk '{print $1}'):2586"
echo "Approval server: http://$(hostname -I | awk '{print $1}'):2587"
echo ""
echo "Make sure to open ports 2586 and 2587 in your firewall/security group"
