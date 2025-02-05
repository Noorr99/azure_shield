provider "azurerm" {
  features {}
}

provider "azapi" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.45"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1.3"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-terraform-storage"
    storage_account_name = "terraformstgaks99"
    container_name       = "tfstatesheilddevv"
    key                  = "terraform.tfstate"
  }
}
}

# Base Infrastructure
resource "azurerm_resource_group" "shield_noor" {
  name     = "${var.project_name}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "shield_noor" {
  name                = "${var.project_name}-vnet"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_subnet" "ai_services" {
  name                 = "${var.project_name}-ai-services"
  resource_group_name  = azurerm_resource_group.shield_noor.name
  virtual_network_name = azurerm_virtual_network.shield_noor.name
  address_prefixes     = [var.subnet_prefixes["ai_services"]]
}

resource "azurerm_subnet" "other_services" {
  name                 = "${var.project_name}-other-services"
  resource_group_name  = azurerm_resource_group.shield_noor.name
  virtual_network_name = azurerm_virtual_network.shield_noor.name
  address_prefixes     = [var.subnet_prefixes["other_services"]]
}

resource "azurerm_subnet" "management" {
  name                 = "${var.project_name}-management"
  resource_group_name  = azurerm_resource_group.shield_noor.name
  virtual_network_name = azurerm_virtual_network.shield_noor.name
  address_prefixes     = [var.subnet_prefixes["management"]]
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "functions" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

# Add after existing DNS zones
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

resource "azurerm_private_dns_zone" "containerapps" {
  name                = "privatelink.azurecontainerapps.io"
  resource_group_name = azurerm_resource_group.shield_noor.name
}

# VNet Links
resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "openai-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  name                  = "search-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "table-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "functions" {
  name                  = "functions-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.functions.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

# Add after existing VNet links
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "containerapps" {
  name                  = "containerapps-link"
  resource_group_name   = azurerm_resource_group.shield_noor.name
  private_dns_zone_name = azurerm_private_dns_zone.containerapps.name
  virtual_network_id    = azurerm_virtual_network.shield_noor.id
}

# Azure OpenAI
resource "azapi_resource" "shield_noor_openai" {
  type      = "Microsoft.CognitiveServices/accounts@2023-05-01"
  name      = "${var.project_name}-openai"
  location  = var.location
  parent_id = azurerm_resource_group.shield_noor.id

  body = jsonencode({
    sku = {
      name = var.openai_sku
    }
    kind = "OpenAI"
    properties = {
      networkAcls = {
        defaultAction = "Deny"
        virtualNetworkRules = [
          {
            id = azurerm_subnet.ai_services.id
          }
        ]
      }
    }
  })
}

# Azure Cognitive Search
resource "azurerm_search_service" "shield_noor" {
  name                          = "${var.project_name}-search"
  resource_group_name           = azurerm_resource_group.shield_noor.name
  location                      = var.location
  sku                          = var.search_sku
  partition_count               = 1
  replica_count                = 1
  public_network_access_enabled = false
}

# Azure Storage Account
resource "azurerm_storage_account" "shield_noor" {
  name                          = "${replace(var.project_name, "-", "")}storage"
  resource_group_name           = azurerm_resource_group.shield_noor.name
  location                      = var.location
  account_tier                  = var.storage_account_tier
  account_replication_type      = var.storage_replication_type
  public_network_access_enabled = false
}

# Azure Service Plan
resource "azurerm_service_plan" "shield_noor" {
  name                = "${var.project_name}-service-plan"
  location            = var.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  os_type            = "Linux"
  sku_name           = "Y1"
}

# Azure Function App
resource "azurerm_linux_function_app" "shield_noor" {
  name                       = "shield-noor-function"
  resource_group_name        = azurerm_resource_group.shield_noor.name
  location                   = azurerm_resource_group.shield_noor.location
  service_plan_id            = azurerm_service_plan.shield_noor.id
  storage_account_name       = azurerm_storage_account.shield_noor.name
  storage_account_access_key = azurerm_storage_account.shield_noor.primary_access_key
  https_only                = true

  site_config {
    application_stack {
      node_version = "16"
    }
    
    ip_restriction {
      name       = "AllowOtherServices"
      ip_address = "10.0.2.0/24"
      action     = "Allow"
      priority   = 100
    }

    ip_restriction {
      name       = "DenyAll"
      ip_address = "0.0.0.0/0"
      action     = "Deny"
      priority   = 200
    }
  }
}

# Private Endpoints
resource "azurerm_private_endpoint" "openai" {
  name                = "shield-noor-openai-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.ai_services.id

  private_dns_zone_group {
    name                 = "openai-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai.id]
  }

  private_service_connection {
    name                           = "openai-connection"
    private_connection_resource_id = azapi_resource.shield_noor_openai.id
    is_manual_connection           = false
    subresource_names             = ["account"]
  }
}

resource "azurerm_private_endpoint" "search" {
  name                = "shield-noor-search-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.ai_services.id

  private_dns_zone_group {
    name                 = "search-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.search.id]
  }

  private_service_connection {
    name                           = "search-connection"
    private_connection_resource_id = azurerm_search_service.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["searchService"]
  }
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "shield-noor-blob-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.other_services.id

  private_dns_zone_group {
    name                 = "blob-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  private_service_connection {
    name                           = "blob-connection"
    private_connection_resource_id = azurerm_storage_account.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["blob"]
  }
}

resource "azurerm_private_endpoint" "storage_table" {
  name                = "shield-noor-table-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.other_services.id

  private_dns_zone_group {
    name                 = "table-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.table.id]
  }

  private_service_connection {
    name                           = "table-connection"
    private_connection_resource_id = azurerm_storage_account.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["table"]
  }
}

resource "azurerm_private_endpoint" "function" {
  name                = "shield-noor-function-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.other_services.id

  private_dns_zone_group {
    name                 = "function-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.functions.id]
  }

  private_service_connection {
    name                           = "function-connection"
    private_connection_resource_id = azurerm_linux_function_app.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["sites"]
  }
}

# Add Container Registry
resource "azurerm_container_registry" "shield_noor" {
  name                          = "${replace(var.project_name, "-", "")}registry"
  resource_group_name           = azurerm_resource_group.shield_noor.name
  location                      = var.location
  sku                          = var.acr_sku
  admin_enabled                = true
  public_network_access_enabled = false
}

# Add Container Registry Private Endpoint
resource "azurerm_private_endpoint" "acr" {
  name                = "shield-noor-acr-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.other_services.id

  private_dns_zone_group {
    name                 = "acr-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  private_service_connection {
    name                           = "acr-connection"
    private_connection_resource_id = azurerm_container_registry.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["registry"]
  }
}

# Add Container Apps Environment
resource "azurerm_container_app_environment" "shield_noor" {
  name                       = "shield-noor-env"
  location                   = azurerm_resource_group.shield_noor.location
  resource_group_name        = azurerm_resource_group.shield_noor.name
  infrastructure_subnet_id   = azurerm_subnet.other_services.id
}

# Add Container App
resource "azurerm_container_app" "shield_noor" {
  name                         = "shield-noor-app"
  container_app_environment_id = azurerm_container_app_environment.shield_noor.id
  resource_group_name         = azurerm_resource_group.shield_noor.name
  revision_mode               = "Single"

  template {
    container {
      name   = "shield-noor-container"
      image  = "${azurerm_container_registry.shield_noor.login_server}/sample-app:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  registry {
    server               = azurerm_container_registry.shield_noor.login_server
    username            = azurerm_container_registry.shield_noor.admin_username
    password_secret_name = "registry-password"
  }

  ingress {
    external_enabled = false
    target_port     = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# Add Container Apps Private Endpoint
resource "azurerm_private_endpoint" "containerapps" {
  name                = "shield-noor-containerapps-endpoint"
  location            = azurerm_resource_group.shield_noor.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  subnet_id           = azurerm_subnet.other_services.id

  private_dns_zone_group {
    name                 = "containerapps-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.containerapps.id]
  }

  private_service_connection {
    name                           = "containerapps-connection"
    private_connection_resource_id = azurerm_container_app_environment.shield_noor.id
    is_manual_connection           = false
    subresource_names             = ["containerapp"]
  }
}

// add VM:

# Create NSG
resource "azurerm_network_security_group" "management" {
  name                = "${var.project_name}-vm-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.shield_noor.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create Public IP
resource "azurerm_public_ip" "management" {
  name                = "${var.project_name}-vm-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.shield_noor.name
  allocation_method   = "Static"
  sku                = "Standard"
}

# Create NIC
resource "azurerm_network_interface" "management" {
  name                = "${var.project_name}-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.shield_noor.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.management.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "management" {
  network_interface_id      = azurerm_network_interface.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}

# Create Ubuntu Desktop VM
resource "azurerm_linux_virtual_machine" "management" {
  name                            = "${var.project_name}-vm"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.shield_noor.name
  network_interface_ids           = [azurerm_network_interface.management.id]
  size                           = var.vm_size
  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y ubuntu-desktop
              apt-get install -y xrdp
              systemctl enable xrdp
              systemctl start xrdp
              EOF
  )
}
