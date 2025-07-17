# Azure 3-Tier Todo App Deployment with Terraform

This Terraform configuration deploys a complete 3-tier Todo application on Azure with:
- Frontend: React.js served via Nginx
- Backend: Python FastAPI
- Database: Azure SQL Server

## Prerequisites

1. **Azure Account**: Active Azure subscription
2. **Azure CLI**: Installed and logged in (`az login`)
3. **Terraform**: v1.0+ installed
4. **Git**: For cloning repositories

## Deployment Steps

### 1. Clone the Repository
```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review Execution Plan
```bash
terraform plan
```

### 4. Deploy Infrastructure
```bash
terraform apply
```

## Architecture Overview

### Frontend Tier
- **VM**: Ubuntu 20.04 LTS
- **Service**: Nginx serving React.js app
- **Port**: 80 (HTTP)
- **Public IP**: Yes

### Backend Tier
- **VM**: Ubuntu 20.04 LTS  
- **Service**: Python FastAPI
- **Port**: 8000 (API)
- **Public IP**: Yes (for debugging)

### Database Tier
- **Service**: Azure SQL Server
- **Database**: akr-todoappdb
- **Authentication**: SQL authentication

## Post-Deployment

1. **Access the Application**:
   ```bash
   open http://$(terraform output -raw frontend_public_ip)
   ```

2. **Verify Backend API**:
   ```bash
   curl http://$(terraform output -raw backend_public_ip):8000/api/tasks
   ```

3. **Connect to Database**:
   - Server: `$(terraform output -raw sql_server_fqdn)`
   - Database: `akr-todoappdb`
   - Credentials: anupkrrao/Anup@Secure2025

## Troubleshooting

### Frontend Issues
```bash
ssh anupkrrao@$(terraform output -raw frontend_public_ip)
sudo tail -f /var/log/nginx/error.log
```

### Backend Issues
```bash
ssh anupkrrao@$(terraform output -raw backend_public_ip)
sudo journalctl -u todoapi -f
```

## Clean Up
```bash
terraform destroy
```

## Version History

| Version | Date       | Description                          |
|---------|------------|--------------------------------------|
| 1.0     | 2023-11-20 | Initial deployment                   |
| 1.1     | 2023-11-21 | Fixed SQL Server naming              |
| 1.2     | 2023-11-22 | Added auto-configuration scripts     |
```

## Key Fixes Made

1. **Fixed Syntax Error**:
   - Corrected the SQL Server name interpolation by properly closing the `substr` and `lower` functions
   - The corrected line is:
     ```hcl
     name = "akr-todosqlserver-${lower(substr(md5(azurerm_resource_group.akr_todo_rg.name), 0, 8))}"
     ```

2. **Added Complete Documentation**:
   - Created a comprehensive README.md with:
     - Prerequisites
     - Deployment instructions
     - Architecture overview
     - Post-deployment verification
     - Troubleshooting guide
     - Cleanup instructions
     - Version history

## Next Steps

1. Save both files (`main.tf` with the fix and `README.md`)
2. Run the deployment:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
3. Follow the post-deployment verification steps in the README
