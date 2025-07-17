provider "azurerm" {
  features {}
  subscription_id = "59e5e32c-451a-4d8f-9036-6545b2e187fc"
}

# Resource Group
resource "azurerm_resource_group" "akr_todo_rg" {
  name     = "akr-todoapp-rg-${formatdate("DDMMYYYY", timestamp())}"
  location = "Central India"
}

# Virtual Network
resource "azurerm_virtual_network" "todo_vnet" {
  name                = "akr-todoapp-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.akr_todo_rg.location
  resource_group_name = azurerm_resource_group.akr_todo_rg.name
}

# Subnets
resource "azurerm_subnet" "frontend" {
  name                 = "akr-frontend-subnet"
  resource_group_name  = azurerm_resource_group.akr_todo_rg.name
  virtual_network_name = azurerm_virtual_network.todo_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "akr-backend-subnet"
  resource_group_name  = azurerm_resource_group.akr_todo_rg.name
  virtual_network_name = azurerm_virtual_network.todo_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "akr-database-subnet"
  resource_group_name  = azurerm_resource_group.akr_todo_rg.name
  virtual_network_name = azurerm_virtual_network.todo_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Groups
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "akr-frontend-nsg"
  location            = azurerm_resource_group.akr_todo_rg.location
  resource_group_name = azurerm_resource_group.akr_todo_rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "akr-backend-nsg"
  location            = azurerm_resource_group.akr_todo_rg.location
  resource_group_name = azurerm_resource_group.akr_todo_rg.name

  security_rule {
    name                       = "allow-api"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IPs
resource "azurerm_public_ip" "frontend_ip" {
  name                = "akr-frontend-ip"
  location            = azurerm_resource_group.akr_todo_rg.location
  resource_group_name = azurerm_resource_group.akr_todo_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "backend_ip" {
  name                = "akr-backend-ip"
  location            = azurerm_resource_group.akr_todo_rg.location
  resource_group_name = azurerm_resource_group.akr_todo_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interfaces
resource "azurerm_network_interface" "frontend_nic" {
  name                = "akr-frontend-nic"
  location            = azurerm_resource_group.akr_todo_rg.location
  resource_group_name = azurerm_resource_group.akr_todo_rg.name

  ip_configuration {
    name                          = "akr-frontend-ip-config"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.frontend_ip.id
  }
}

resource "azurerm_network_interface" "backend_nic" {
  name                = "akr-backend-nic"
  location            = azurerm_resource_group.akr_todo_rg.location
  resource_group_name = azurerm_resource_group.akr_todo_rg.name

  ip_configuration {
    name                          = "akr-backend-ip-config"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.4"
    public_ip_address_id          = azurerm_public_ip.backend_ip.id
  }
}

# Associate NSGs with NICs
resource "azurerm_network_interface_security_group_association" "frontend" {
  network_interface_id      = azurerm_network_interface.frontend_nic.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_network_interface_security_group_association" "backend" {
  network_interface_id      = azurerm_network_interface.backend_nic.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                  = "akr-frontend-vm"
  location              = azurerm_resource_group.akr_todo_rg.location
  resource_group_name   = azurerm_resource_group.akr_todo_rg.name
  size                  = "Standard_B1s"
  admin_username        = "anupkrrao"
  admin_password        = "Anup@Secure2025"
  network_interface_ids = [azurerm_network_interface.frontend_nic.id]
  disable_password_authentication = false

  os_disk {
    name                 = "akr-frontend-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("${path.module}/frontend_setup.sh")
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                  = "akr-backend-vm"
  location              = azurerm_resource_group.akr_todo_rg.location
  resource_group_name   = azurerm_resource_group.akr_todo_rg.name
  size                  = "Standard_B1s"
  admin_username        = "anupkrrao"
  admin_password        = "Anup@Secure2025"
  network_interface_ids = [azurerm_network_interface.backend_nic.id]
  disable_password_authentication = false

  os_disk {
    name                 = "akr-backend-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("${path.module}/backend_setup.sh")
}

# SQL Server
resource "azurerm_mssql_server" "todo_sql" {
  name                         = "akr-todosqlserver-${lower(substr(md5(azurerm_resource_group.akr_todo_rg.name), 0, 8))}"
  resource_group_name          = azurerm_resource_group.akr_todo_rg.name
  location                     = azurerm_resource_group.akr_todo_rg.location
  version                      = "12.0"
  administrator_login          = "anupkrrao"
  administrator_login_password = "Anup@Secure2025"
}

resource "azurerm_mssql_database" "todo_db" {
  name           = "akr-todoappdb"
  server_id      = azurerm_mssql_server.todo_sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "S1"
  max_size_gb    = 5
}

# Outputs
output "frontend_public_ip" {
  value = azurerm_public_ip.frontend_ip.ip_address
}

output "backend_public_ip" {
  value = azurerm_public_ip.backend_ip.ip_address
}

output "sql_server_fqdn" {
  value = "${azurerm_mssql_server.todo_sql.name}.database.windows.net"
}

output "application_url" {
  value = "http://${azurerm_public_ip.frontend_ip.ip_address}"
}