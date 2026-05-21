#!/bin/bash
set -e

exec > >(tee -a /var/log/bootstrap.log) 2>&1
echo "========================================="
echo "FitTrack Pro Bootstrap Started"
echo "Date: $(date)"
echo "========================================="

# ─────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────
APP_USER="azureuser"
APP_HOME="/home/$APP_USER"
APP_NAME="fittrack-pro"
APP_DIR="$APP_HOME/Fitness_Tracker"
GITHUB_REPO="https://github.com/Suryaa11/Fitness_Tracker.git"
APP_PORT="5000"
MONGO_DB_NAME="fitness-tracker"

# ─────────────────────────────────────────────
# [1/10] SYSTEM UPDATE
# ─────────────────────────────────────────────
echo "[1/10] Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# ─────────────────────────────────────────────
# [2/10] INSTALL SYSTEM DEPENDENCIES
# ─────────────────────────────────────────────
echo "[2/10] Installing system dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    gnupg \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    netcat-openbsd \
    build-essential \
    nginx

# ─────────────────────────────────────────────
# [3/10] INSTALL MONGODB 7.0
# ─────────────────────────────────────────────
echo "[3/10] Installing MongoDB 7.0..."
rm -f /usr/share/keyrings/mongodb-server-7.0.gpg

curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list

apt-get update -y
apt-get install -y mongodb-org

# ─────────────────────────────────────────────
# [4/10] CONFIGURE & START MONGODB
# ─────────────────────────────────────────────
echo "[4/10] Configuring MongoDB..."
cp /etc/mongod.conf /etc/mongod.conf.backup

cat > /etc/mongod.conf << 'MONGOEOF'
storage:
  dbPath: /var/lib/mongodb

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
MONGOEOF

mkdir -p /var/lib/mongodb /var/log/mongodb
chown -R mongodb:mongodb /var/lib/mongodb /var/log/mongodb

systemctl daemon-reload
systemctl enable mongod
systemctl restart mongod

echo "Waiting for MongoDB to initialize..."
sleep 10

if systemctl is-active --quiet mongod; then
    echo "MongoDB is running"
else
    echo "MongoDB failed — checking logs..."
    journalctl -u mongod --no-pager -n 30
    exit 1
fi

# ─────────────────────────────────────────────
# [5/10] INSTALL NODE.JS 20.x
# ─────────────────────────────────────────────
echo "[5/10] Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo "Node Version : $(node -v)"
echo "NPM Version  : $(npm -v)"

# ─────────────────────────────────────────────
# [6/10] INSTALL PM2
# ─────────────────────────────────────────────
echo "[6/10] Installing PM2 globally..."
npm install -g pm2
echo "PM2 Version  : $(pm2 -v)"

# ─────────────────────────────────────────────
# [7/10] CLONE REPOSITORY
# ─────────────────────────────────────────────
echo "[7/10] Cloning Fitness_Tracker repository..."
cd "$APP_HOME"

if [ -d "$APP_DIR" ]; then
    echo "Removing existing directory..."
    rm -rf "$APP_DIR"
fi

sudo -u "$APP_USER" git clone "$GITHUB_REPO" "$APP_DIR"

if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: Clone failed!"
    exit 1
fi

echo "Cloned successfully to $APP_DIR"
echo "Directory structure:"
ls -la "$APP_DIR"

# ─────────────────────────────────────────────
# [8/10] INSTALL NPM DEPENDENCIES
# ─────────────────────────────────────────────
echo "[8/10] Installing npm dependencies..."

if [ -f "$APP_DIR/package.json" ]; then
    echo "Installing root dependencies..."
    cd "$APP_DIR"
    sudo -u "$APP_USER" npm install
    echo "Root dependencies installed"
fi

if [ -d "$APP_DIR/server" ] && [ -f "$APP_DIR/server/package.json" ]; then
    echo "Installing server/ dependencies..."
    cd "$APP_DIR/server"
    sudo -u "$APP_USER" npm install
    echo "Server dependencies installed"
fi

# ─────────────────────────────────────────────
# PATCH package.json — nodemon to node
# ─────────────────────────────────────────────
echo "Patching nodemon to node in package.json files..."

if [ -f "$APP_DIR/package.json" ]; then
    sed -i 's/nodemon/node/g' "$APP_DIR/package.json"
    echo "Root package.json patched"
fi

if [ -f "$APP_DIR/server/package.json" ]; then
    sed -i 's/nodemon/node/g' "$APP_DIR/server/package.json"
    echo "server/package.json patched"
fi

# ─────────────────────────────────────────────
# [9/10] CREATE .env FILE
# ─────────────────────────────────────────────
echo "[9/10] Creating .env files..."

JWT_SECRET=$(openssl rand -hex 32)

cat > "$APP_DIR/.env" << EOF
PORT=$APP_PORT
NODE_ENV=production
MONGODB_URI=mongodb://127.0.0.1:27017/$MONGO_DB_NAME
JWT_SECRET=$JWT_SECRET
EOF
chown "$APP_USER:$APP_USER" "$APP_DIR/.env"

if [ -d "$APP_DIR/server" ]; then
    cat > "$APP_DIR/server/.env" << EOF
PORT=$APP_PORT
NODE_ENV=production
MONGODB_URI=mongodb://127.0.0.1:27017/$MONGO_DB_NAME
JWT_SECRET=$JWT_SECRET
EOF
    chown "$APP_USER:$APP_USER" "$APP_DIR/server/.env"
fi

echo ".env files created"

# ─────────────────────────────────────────────
# [10/10] START APP WITH PM2
# ─────────────────────────────────────────────
echo "[10/10] Starting application with PM2..."

chown -R "$APP_USER:$APP_USER" "$APP_DIR"

cd "$APP_DIR"

sudo -u "$APP_USER" pm2 delete all 2>/dev/null || true
sudo -u "$APP_USER" pm2 kill 2>/dev/null || true
sleep 3

# Entry point detection
ENTRY_POINT=""

if [ -f "$APP_DIR/server/app.js" ]; then
    ENTRY_POINT="$APP_DIR/server/app.js"
    echo "Entry point: server/app.js"
elif [ -f "$APP_DIR/server/index.js" ]; then
    ENTRY_POINT="$APP_DIR/server/index.js"
    echo "Entry point: server/index.js"
elif [ -f "$APP_DIR/app.js" ]; then
    ENTRY_POINT="$APP_DIR/app.js"
    echo "Entry point: app.js"
elif [ -f "$APP_DIR/index.js" ]; then
    ENTRY_POINT="$APP_DIR/index.js"
    echo "Entry point: index.js"
else
    echo "ERROR: No entry point found!"
    find "$APP_DIR" -name "*.js" -not -path "*/node_modules/*"
    exit 1
fi

sudo -u "$APP_USER" pm2 start "$ENTRY_POINT" \
    --name "$APP_NAME" \
    --env production \
    --log "$APP_HOME/$APP_NAME-pm2.log" \
    --time

sleep 8

sudo -u "$APP_USER" pm2 save

env PATH="$PATH:/usr/bin" \
    /usr/lib/node_modules/pm2/bin/pm2 \
    startup systemd \
    -u "$APP_USER" \
    --hp "$APP_HOME"

systemctl enable "pm2-$APP_USER" 2>/dev/null || true

echo "PM2 Status:"
sudo -u "$APP_USER" pm2 status

# ─────────────────────────────────────────────
# CONFIGURE NGINX
# ─────────────────────────────────────────────
echo "Configuring Nginx..."

cat > /etc/nginx/sites-available/fittrack << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/fittrack-access.log;
    error_log  /var/log/nginx/fittrack-error.log;

    location /public/ {
        alias /home/azureuser/Fitness_Tracker/public/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass         http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade        $http_upgrade;
        proxy_set_header   Connection     'upgrade';
        proxy_set_header   Host           $host;
        proxy_set_header   X-Real-IP      $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout    60s;
        proxy_connect_timeout 60s;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/fittrack /etc/nginx/sites-enabled/fittrack
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx
systemctl enable nginx

echo "Nginx configured and running"

# ─────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────
echo "Running health checks..."
sleep 15

MAX_RETRIES=6
RETRY=0
APP_OK=false

while [ $RETRY -lt $MAX_RETRIES ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$APP_PORT 2>/dev/null || echo "000")

    if echo "$HTTP_CODE" | grep -qE "^[23]"; then
        echo "Health check PASSED — HTTP $HTTP_CODE"
        APP_OK=true
        break
    fi

    RETRY=$((RETRY + 1))
    echo "Attempt $RETRY/$MAX_RETRIES — HTTP $HTTP_CODE — waiting 10s..."
    sleep 10
done

if [ "$APP_OK" = false ]; then
    echo "Health check inconclusive — dumping debug info..."
    sudo -u "$APP_USER" pm2 logs "$APP_NAME" --lines 50 --nostream || true
    tail -20 /var/log/nginx/fittrack-error.log || true
    systemctl status mongod --no-pager | tail -10
    ss -tlnp | grep -E "5000|27017|80" || true
fi

# ─────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────
PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================="
echo "   FITTRACK PRO — DEPLOYMENT COMPLETE"
echo "========================================="
echo "App Name      : $APP_NAME"
echo "App Port      : $APP_PORT"
echo "Entry Point   : $ENTRY_POINT"
echo "App Directory : $APP_DIR"
echo "Private IP    : $PRIVATE_IP"
echo "MongoDB DB    : $MONGO_DB_NAME"
echo ""
echo "Access URLs:"
echo "  App (via Nginx) : http://$PRIVATE_IP"
echo "  App (direct)    : http://$PRIVATE_IP:$APP_PORT"
echo ""
echo "Useful Commands:"
echo "  pm2 status"
echo "  pm2 logs $APP_NAME"
echo "  pm2 restart $APP_NAME"
echo "  systemctl status mongod"
echo "  systemctl status nginx"
echo "  cat /var/log/bootstrap.log"
echo "  cat /var/log/nginx/fittrack-error.log"
echo "========================================="