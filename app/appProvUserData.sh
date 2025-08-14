#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo "Updating package list..."
apt-get update -y
echo "Package list updated."
echo

echo "Upgrading packages..."
apt-get upgrade -y
echo "Upgrade complete."
echo

echo "Installing Nginx..."
apt-get install nginx -y
echo "Nginx installed."
echo

# Configure Nginx reverse proxy
#sed -i '/^\s*#*\s*try_files/ {
#s/^\s*#*\s*/        # /
#a\        proxy_pass http://localhost:3000;
#}' /etc/nginx/sites-available/default

sudo sed -i 's|try_files \$uri \$uri/ =404;|proxy_pass http://localhost:3000;|' /etc/nginx/sites-available/default

systemctl restart nginx
systemctl enable nginx

echo "Installing Node.js v20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
echo "Node.js version: $(node -v)"
echo

echo "Installing PM2 globally..."
npm install -g pm2
echo "PM2 installed."
echo

echo "Cloning Sparta test app to ~/repo..."
git clone https://github.com/freeApiKeysHere/sparta-test-app.git ~/repo
echo "Repo cloned."
echo

echo "Setting up environment..."
cd ~/repo/app
export DB_HOST=mongodb://172.31.18.185:27017/posts
echo "Environment file written."
echo

echo "Installing app dependencies..."
npm install --no-fund --no-audit
echo "Dependencies installed."
echo

echo "Stopping any previous app instances (if any)..."
pm2 stop all || true
echo

echo "Starting app using PM2..."
pm2 start app.js --name sparta-app --env production
pm2 save
pm2 startup systemd -u root --hp /root | tail -n 1 | bash
echo "App started with PM2."
echo

echo "Public IP address:"
curl -s http://checkip.amazonaws.com
echo