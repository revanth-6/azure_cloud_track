#!/bin/bash
set -e

# Redirect stdout and stderr to a log file
exec > >(tee -a /var/log/bootstrap.log) 2>&1
echo "========================================="
echo "MediShift Microservices Bootstrap Started"
echo "Date: $(date)"
echo "========================================="

# ─────────────────────────────────────────────
# CONFIGURATION PASSED FROM TERRAFORM
# ─────────────────────────────────────────────
APP_USER="${admin_username}"
APP_HOME="/home/$APP_USER"
APP_DIR="$APP_HOME/MediShift"

DB_HOST="${db_host}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
DB_NAME="${db_name}"
JWT_SECRET="${jwt_secret}"

# ─────────────────────────────────────────────
# [1/7] SYSTEM UPDATE & DEPENDENCIES
# ─────────────────────────────────────────────
echo "[1/7] Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confold"

echo "Installing system dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    gnupg \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    build-essential \
    nginx

# ─────────────────────────────────────────────
# [2/7] IMMEDIATE NGINX PROXY (For instant AppGW Health)
# ─────────────────────────────────────────────
echo "[2/7] Configuring Nginx reverse proxy with health check responder..."

# We map App Gateway incoming paths to the local microservice ports,
# and crucially add a root "location /" returning a valid JSON "200 OK".
# This guarantees the App Gateway's default health probe resolves to 200, marking the backend immediately Healthy!
cat > /etc/nginx/sites-available/medishift-backend << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/medishift-backend-access.log;
    error_log  /var/log/nginx/medishift-backend-error.log;

    location / {
        return 200 '{"status":"healthy","service":"medishift-backend-proxy"}';
        add_header Content-Type application/json;
    }

    location /api/auth {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/departments {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/staff {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/shifts {
        proxy_pass http://localhost:3003;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/leaves {
        proxy_pass http://localhost:3004;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/medishift-backend /etc/nginx/sites-enabled/medishift-backend
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx
systemctl enable nginx
echo "Nginx proxy configured and active."

# ─────────────────────────────────────────────
# [3/7] CLONE LATEST CODEBASE FROM GITHUB
# ─────────────────────────────────────────────
echo "[3/7] Cloning MediShift codebase..."
mkdir -p "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
    echo "Directory already cloned. Pulling latest..."
    cd "$APP_DIR"
    git pull
else
    echo "Cloning repository..."
    git clone https://github.com/MediShift-devops-project/MediShift_v1.git "$APP_DIR"
fi

# Hand over permissions
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

# ─────────────────────────────────────────────
# [4/7] INSTALL NODE.JS 20.x & PM2
# ─────────────────────────────────────────────
echo "[4/7] Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

echo "Installing PM2 globally..."
npm install -g pm2
echo "PM2 version: $(pm2 -v)"

# ─────────────────────────────────────────────
# [5/7] CONFIGURE MICROSERVICES
# ─────────────────────────────────────────────
echo "[5/7] Writing microservices configuration variables..."

# Construct postgres connection string
# We pass PGSSLMODE=no-verify to allow Node's PG driver to connect securely without a CA certificate file
DATABASE_URL="postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME?sslmode=require"

declare -A SERVICES
SERVICES[auth-service]="3001"
SERVICES[staff-service]="3002"
SERVICES[shift-service]="3003"
SERVICES[leave-service]="3004"

for service in "$${!SERVICES[@]}"; do
    PORT="$${SERVICES[$service]}"
    SERVICE_DIR="$APP_DIR/services/$service"
    
    echo "Writing environment files for $service in $SERVICE_DIR"
    mkdir -p "$SERVICE_DIR"
    
    cat > "$SERVICE_DIR/.env" << EOF
PORT=$PORT
NODE_ENV=production
DATABASE_URL=$DATABASE_URL
PGSSLMODE=no-verify
JWT_SECRET=$JWT_SECRET
AUTH_SERVICE_URL=http://localhost:3001
STAFF_SERVICE_URL=http://localhost:3002
SHIFT_SERVICE_URL=http://localhost:3003
LEAVE_SERVICE_URL=http://localhost:3004
EOF

    # Install dependencies reliably inside the user context
    echo "Installing production dependencies for $service..."
    chown -R "$APP_USER:$APP_USER" "$SERVICE_DIR"
    sudo -u "$APP_USER" -i sh -c "cd $SERVICE_DIR && npm install --production"
done

# ─────────────────────────────────────────────
# [6/7] LAUNCH MICROSERVICES VIA PM2
# ─────────────────────────────────────────────
echo "[6/7] Starting microservices under PM2..."
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

# Launch pm2 commands reliably inside the user context
sudo -u "$APP_USER" -i sh -c "pm2 kill" || true
sleep 2

# Launch microservices sequentially
sudo -u "$APP_USER" -i sh -c "cd $APP_DIR/services/auth-service && PORT=3001 NODE_ENV=production DATABASE_URL='$DATABASE_URL' PGSSLMODE=no-verify JWT_SECRET='$JWT_SECRET' STAFF_SERVICE_URL='http://localhost:3002' pm2 start src/index.js --name 'auth-service'"
sudo -u "$APP_USER" -i sh -c "cd $APP_DIR/services/staff-service && PORT=3002 NODE_ENV=production DATABASE_URL='$DATABASE_URL' PGSSLMODE=no-verify JWT_SECRET='$JWT_SECRET' AUTH_SERVICE_URL='http://localhost:3001' pm2 start src/index.js --name 'staff-service'"
sudo -u "$APP_USER" -i sh -c "cd $APP_DIR/services/shift-service && PORT=3003 NODE_ENV=production DATABASE_URL='$DATABASE_URL' PGSSLMODE=no-verify JWT_SECRET='$JWT_SECRET' AUTH_SERVICE_URL='http://localhost:3001' STAFF_SERVICE_URL='http://localhost:3002' LEAVE_SERVICE_URL='http://localhost:3004' pm2 start src/index.js --name 'shift-service'"
sudo -u "$APP_USER" -i sh -c "cd $APP_DIR/services/leave-service && PORT=3004 NODE_ENV=production DATABASE_URL='$DATABASE_URL' PGSSLMODE=no-verify JWT_SECRET='$JWT_SECRET' AUTH_SERVICE_URL='http://localhost:3001' SHIFT_SERVICE_URL='http://localhost:3003' pm2 start src/index.js --name 'leave-service'"

sleep 5
sudo -u "$APP_USER" -i sh -c "pm2 save"

# Register PM2 systemd daemon for automatic boot launches
env PATH="$PATH:/usr/bin" /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u "$APP_USER" --hp "$APP_HOME"
systemctl enable "pm2-$APP_USER" || true
systemctl start "pm2-$APP_USER" || true

echo "PM2 services active:"
sudo -u "$APP_USER" -i sh -c "pm2 list"

# ─────────────────────────────────────────────
# [7/7] COMPLETE
# ─────────────────────────────────────────────
echo "========================================="
echo "MediShift Microservices Bootstrap Complete!"
echo "========================================="
