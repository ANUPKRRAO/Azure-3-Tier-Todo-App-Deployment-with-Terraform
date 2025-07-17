#!/bin/bash

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Node.js 16.x
curl -s https://deb.nodesource.com/setup_16.x | sudo bash
sudo apt-get install -y nodejs

# Install Nginx
sudo apt-get install -y nginx

# Clone frontend repository
git clone https://github.com/devopsinsiders/ReactTodoUIMonolith.git /home/anupkrrao/frontend
cd /home/anupkrrao/frontend

# Install dependencies and build
npm install
npm run build

# Configure Nginx
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        root /home/anupkrrao/frontend/build;
        try_files \$uri /index.html;
    }

    location /api {
        proxy_pass http://10.0.2.4:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Set permissions
sudo chown -R anupkrrao:anupkrrao /home/anupkrrao/frontend
sudo chmod -R 755 /home/anupkrrao/frontend/build

# Restart Nginx
sudo systemctl restart nginx