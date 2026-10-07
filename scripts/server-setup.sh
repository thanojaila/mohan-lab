#!/usr/bin/env bash
#
# server-setup.sh - ONE-TIME setup of the Mohan Lab website server.
#
# Run on a fresh Ubuntu 24.04 EC2 instance, as the "ubuntu" user:
#
#   curl -fsSLo setup.sh https://raw.githubusercontent.com/thanojaila/mohan-lab/main/scripts/server-setup.sh
#   bash setup.sh
#
# Safe to re-run: every step checks whether it is already done.
#
# Optional overrides (environment variables):
#   REPO_URL   git repo to clone         (default: the public mohan-lab repo)
#   DOMAIN     public hostname           (default: mohanlab.bme.uh.edu)
#   APP_PORT   internal port of the app  (default: 3000)

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/thanojaila/mohan-lab.git}"
DOMAIN="${DOMAIN:-mohanlab.bme.uh.edu}"
APP_DIR="${APP_DIR:-$HOME/mohan-lab}"
APP_PORT="${APP_PORT:-3000}"
SERVICE="mohanlab"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
  echo "Please run this as the normal 'ubuntu' user, not root (it uses sudo when needed)."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
step "1/9  Installing system packages"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y nginx git curl ca-certificates fail2ban unattended-upgrades

# ---------------------------------------------------------------------------
step "2/9  Turning on automatic security updates"
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

# ---------------------------------------------------------------------------
step "3/9  Adding 2 GB of swap (so the website build cannot run out of memory)"
if ! swapon --show | grep -q .; then
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
else
  echo "Swap already present - skipping."
fi

# ---------------------------------------------------------------------------
step "4/9  Installing Node.js 22"
NODE_MAJOR=0
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
fi
if [ "$NODE_MAJOR" -lt 22 ]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node $(node -v) already installed - skipping."
fi
echo "Node $(node -v), npm $(npm -v)"

# ---------------------------------------------------------------------------
step "5/9  Downloading the website code"
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" fetch origin main
  git -C "$APP_DIR" reset --hard origin/main
else
  git clone "$REPO_URL" "$APP_DIR"
fi

# ---------------------------------------------------------------------------
step "6/9  Building the website (this takes a few minutes)"
cd "$APP_DIR"
npm ci --no-audit --no-fund || npm install --no-audit --no-fund
npm run build

# ---------------------------------------------------------------------------
step "7/9  Installing the background service (starts automatically on reboot)"
NPM_BIN="$(command -v npm)"
sudo tee "/etc/systemd/system/${SERVICE}.service" >/dev/null <<EOF
[Unit]
Description=Mohan Lab website
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=$APP_PORT
ExecStart=$NPM_BIN start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE"

# ---------------------------------------------------------------------------
step "8/9  Configuring the web server (nginx)"
sed -e "s/__DOMAIN__/$DOMAIN/g" -e "s/__PORT__/$APP_PORT/g" <<'EOF' | sudo tee /etc/nginx/sites-available/mohanlab >/dev/null
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name __DOMAIN__ _;

    server_tokens off;
    client_max_body_size 10m;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml image/svg+xml;

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;

    location / {
        proxy_pass http://127.0.0.1:__PORT__;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/mohanlab /etc/nginx/sites-enabled/mohanlab
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl reload nginx

# ---------------------------------------------------------------------------
step "9/9  Checking that the site responds"
OK=0
for _ in $(seq 1 30); do
  if curl -fsS -o /dev/null "http://127.0.0.1:${APP_PORT}/"; then OK=1; break; fi
  sleep 2
done

if [ "$OK" -ne 1 ]; then
  echo
  echo "The site did NOT respond on port ${APP_PORT}. Recent logs:"
  sudo journalctl -u "$SERVICE" -n 40 --no-pager || true
  echo
  echo "See the Troubleshooting section of docs/aws-hosting.md."
  exit 1
fi

PUBLIC_IP="$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]' || echo '<unknown>')"
cat <<EOF

============================================================
 Setup complete. The website is running.

 Test it in a browser:   http://${PUBLIC_IP}

 Next steps (see docs/aws-hosting.md):
   - Add the GitHub deploy key + secrets (automatic updates)
   - Ask UH IT to point ${DOMAIN} at ${PUBLIC_IP}
   - Once DNS works, run:  ~/mohan-lab/scripts/enable-https.sh you@uh.edu
============================================================
EOF
