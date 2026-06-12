#!/bin/bash
set -e

# Redirect stdout and stderr to a log file
exec > >(tee -a /var/log/bootstrap.log) 2>&1
echo "========================================="
echo "MediShift Frontend Bootstrap Started"
echo "Date: $(date)"
echo "========================================="

# ─────────────────────────────────────────────
# CONFIGURATION PASSED FROM TERRAFORM
# ─────────────────────────────────────────────
APP_USER="${admin_username}"
APP_HOME="/home/$APP_USER"
APP_DIR="$APP_HOME/MediShift"

# ─────────────────────────────────────────────
# [1/6] SYSTEM UPDATE & DEPENDENCIES
# ─────────────────────────────────────────────
echo "[1/6] Updating system..."
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
# [2/6] IMMEDIATE NGINX BOOTSTRAP (For instant AppGW Health)
# ─────────────────────────────────────────────
echo "[2/6] Performing immediate Nginx configuration..."
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html

# Write a gorgeous provisioning status page so the Application Gateway probe is immediately healthy!
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>MediShift - Provisioning</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 80px 20px; background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: #fff; min-height: 100vh; box-sizing: border-box; display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; }
        .card { background: rgba(255, 255, 255, 0.1); backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); border-radius: 16px; padding: 40px; box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.3); border: 1px solid rgba(255, 255, 255, 0.2); max-width: 500px; }
        .spinner { border: 4px solid rgba(255, 255, 255, 0.1); width: 50px; height: 50px; border-radius: 50%; border-left-color: #00ffcc; animation: spin 1s linear infinite; display: inline-block; margin-bottom: 20px; }
        h1 { margin: 0 0 15px 0; font-size: 28px; font-weight: 600; letter-spacing: 0.5px; }
        p { margin: 0; font-size: 16px; line-height: 1.6; color: #e0e6ed; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <div class="card">
        <div class="spinner"></div>
        <h1>MediShift is Provisioning...</h1>
        <p>Our automated pipelines are currently cloning the latest codebase and compiling React production assets. This process completes in 5-7 minutes. Please stand by!</p>
    </div>
</body>
</html>
EOF

cat > /etc/nginx/sites-available/medishift-frontend << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    access_log /var/log/nginx/medishift-frontend-access.log;
    error_log  /var/log/nginx/medishift-frontend-error.log;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/medishift-frontend /etc/nginx/sites-enabled/medishift-frontend
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx
systemctl enable nginx
echo "Nginx configured and launched with loading page."

# ─────────────────────────────────────────────
# [3/6] CLONE LATEST CODEBASE FROM GITHUB
# ─────────────────────────────────────────────
echo "[3/6] Cloning MediShift codebase..."
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
# [4/6] INSTALL NODE.JS 20.x
# ─────────────────────────────────────────────
echo "[4/6] Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# ─────────────────────────────────────────────
# [5/6] INSTALL DEPENDENCIES & BUILD REACT APP
# ─────────────────────────────────────────────
echo "[5/6] Building React Production Assets..."
cd "$APP_DIR/frontend"

# We must ensure that REACT_APP_API_URL is empty so that it makes relative API calls.
cat > "$APP_DIR/frontend/.env" << 'EOF'
REACT_APP_API_URL=
EOF

# Install and build reliably inside the user context
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
sudo -u "$APP_USER" -i sh -c "cd $APP_DIR/frontend && npm install && npm run build"

# ─────────────────────────────────────────────
# [6/6] SWAP AND ACTIVATE PRODUCTION ENVIRONMENT
# ─────────────────────────────────────────────
echo "[6/6] Swapping build files..."
rm -rf /var/www/html/*
cp -r "$APP_DIR/frontend/build/"* /var/www/html/
chown -R www-data:www-data /var/www/html

nginx -t
systemctl restart nginx

echo "========================================="
echo "MediShift Frontend Bootstrap Complete!"
echo "========================================="
