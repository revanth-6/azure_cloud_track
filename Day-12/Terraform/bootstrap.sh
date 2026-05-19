#!/bin/bash
set -e

exec > >(tee -a /var/log/bootstrap.log) 2>&1
echo "========================================="
echo "VMSS Bootstrap Started"
echo "Date: $(date)"
echo "========================================="


APP_USER="azureuser"
APP_HOME="/home/$APP_USER"
APP_NAME="organic-ghee"
APP_DIR="$APP_HOME/Organic_Ghee"
GITHUB_REPO="https://github.com/Msocial123/organic-ghee.git"
APP_PORT="5656"
MONGO_DB_NAME="restorent"


echo "[1/10] Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confold"


echo "[2/10] Installing dependencies..."
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


echo "[3/10] Installing MongoDB..."
rm -f /usr/share/keyrings/mongodb-server-7.0.gpg
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt-get update -y
apt-get install -y mongodb-org


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

sleep 8

if systemctl is-active --quiet mongod; then
    echo "MongoDB is running"
else
    echo "MongoDB failed — checking logs"
    journalctl -u mongod --no-pager -n 20
fi


echo "[5/10] Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
echo "Node Version: $(node -v)"
echo "NPM Version : $(npm -v)"


echo "[6/10] Installing PM2..."
npm install -g pm2
echo "PM2 Version: $(pm2 -v)"


echo "[7/10] Cloning application..."
mkdir -p "$APP_HOME"
chown -R "$APP_USER:$APP_USER" "$APP_HOME"
if [ -d "$APP_DIR" ]; then
    rm -rf "$APP_DIR"
fi
sudo -u "$APP_USER" git clone "$GITHUB_REPO" "$APP_DIR"
if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: Repository clone failed!"
    exit 1
fi
echo "Repository cloned to $APP_DIR"


echo "[8/10] Installing npm dependencies..."
cd "$APP_DIR"
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
sudo -u "$APP_USER" npm install
if [ -d "$APP_DIR/server" ]; then
    echo "Found server/ directory — installing server deps..."
    cd "$APP_DIR/server"
    sudo -u "$APP_USER" npm install
    cd "$APP_DIR"
fi
echo "npm dependencies installed"


echo "[9/10] Creating .env file..."
cat > "$APP_DIR/.env" << EOF
PORT=$APP_PORT
NODE_ENV=production
MONGODB_URI=mongodb://127.0.0.1:27017/$MONGO_DB_NAME
EOF
chown "$APP_USER:$APP_USER" "$APP_DIR/.env"
echo ".env file created:"
cat "$APP_DIR/.env"

echo "Fixing package.json start script (replacing nodemon with node)..."
if [ -f "$APP_DIR/package.json" ]; then
    sed -i 's/nodemon/node/g' "$APP_DIR/package.json"
    echo "package.json updated"
fi


echo "[10/10] Starting application with PM2..."
cd "$APP_DIR"
sudo -u "$APP_USER" pm2 delete all 2>/dev/null || true
sudo -u "$APP_USER" pm2 kill 2>/dev/null || true
sleep 2
sudo -u "$APP_USER" pm2 start src/app.js \
    --name "$APP_NAME" \
    --log "$APP_HOME/$APP_NAME-pm2.log"
sleep 5
sudo -u "$APP_USER" pm2 save
env PATH="$PATH:/usr/bin" \
    /usr/lib/node_modules/pm2/bin/pm2 \
    startup systemd \
    -u "$APP_USER" \
    --hp "$APP_HOME"
systemctl enable "pm2-$APP_USER" 2>/dev/null || true
echo "PM2 Status:"
sudo -u "$APP_USER" pm2 status


echo "Configuring Nginx reverse proxy..."
cat > /etc/nginx/sites-available/default << NGINXEOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINXEOF

nginx -t && systemctl restart nginx
systemctl enable nginx
echo "Nginx configured and started"


echo "Performing health check..."
sleep 15
MAX_RETRIES=5
RETRY=0
APP_OK=false
while [ $RETRY -lt $MAX_RETRIES ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        http://127.0.0.1:$APP_PORT 2>/dev/null || echo "000")

    if echo "$HTTP_CODE" | grep -qE "^[23]"; then
        echo "App health check PASSED — HTTP $HTTP_CODE"
        APP_OK=true
        break
    fi

    RETRY=$((RETRY + 1))
    echo "Health check attempt $RETRY/$MAX_RETRIES — HTTP $HTTP_CODE"
    sleep 5
done

if [ "$APP_OK" = false ]; then
    echo "WARNING: App health check inconclusive"
    echo "Check logs: pm2 logs $APP_NAME"
fi


PRIVATE_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "========================================="
echo "BOOTSTRAP COMPLETED"
echo "========================================="
echo "App Name      : $APP_NAME"
echo "App Port      : $APP_PORT"
echo "App Directory : $APP_DIR"
echo "Private IP    : $PRIVATE_IP"
echo ""
echo "Useful Commands:"
echo "  pm2 status"
echo "  pm2 logs $APP_NAME"
echo "  systemctl status mongod"
echo "  systemctl status nginx"
echo "  cat /var/log/bootstrap.log"
echo "========================================="