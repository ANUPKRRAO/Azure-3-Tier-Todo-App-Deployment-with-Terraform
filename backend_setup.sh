#!/bin/bash

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Python and pip
sudo apt-get install -y python3 python3-pip

# Install SQL Server ODBC driver
sudo su <<EOF
apt-get update && apt-get install -y unixodbc unixodbc-dev
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql17
EOF

# Clone backend repository
git clone https://github.com/devopsinsiders/PyTodoBackendMonolith.git /home/anupkrrao/backend
cd /home/anupkrrao/backend

# Install Python dependencies
pip3 install -r requirements.txt

# Update connection string
SQL_SERVER="${azurerm_mssql_server.todo_sql.name}.database.windows.net"
sed -i "s|'DRIVER=.*'|'DRIVER=ODBC Driver 17 for SQL Server;SERVER=${SQL_SERVER};DATABASE=akr-todoappdb;UID=anupkrrao;PWD=Anup@Secure2025'|g" app.py

# Create systemd service
sudo tee /etc/systemd/system/todoapi.service > /dev/null <<EOF
[Unit]
Description=Todo API Service
After=network.target

[Service]
User=anupkrrao
WorkingDirectory=/home/anupkrrao/backend
ExecStart=/usr/bin/uvicorn app:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl enable todoapi
sudo systemctl start todoapi