############################################
# 1. Terraform Configuration + Remote Backend
############################################
terraform {
  # Use Azure Storage for remote backend state
  backend "azurerm" {
    resource_group_name  = "rg-terraform-storage"
    storage_account_name = "terraformstgaks99"
    container_name       = "tfstatesheilddev"
    key                  = "terraform.tfstate"
  }

  required_version = ">= 1.4.0"

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
}

provider "azurerm" {
  features {}
}

provider "azapi" {
  # no extra config needed
}

############################################
# 3. Variables
############################################
variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-shelidnoor"
}

variable "storage_account_name" {
  type    = string
  default = "storageshelidnoor999"
}

variable "logic_app_name" {
  type    = string
  default = "logic-app-shelidnoor"
}

variable "function_app_name" {
  type    = string
  default = "function-app-shelidnoor"
}

variable "app_service_plan_name" {
  type    = string
  default = "asp-function-shelidnoor"
}

variable "search_service_name" {
  type    = string
  default = "search-shelidnoor"
}

variable "openai_account_name" {
  type    = string
  default = "openai-shelidnoor"
}

############################################
# 4. Resource Group
############################################
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

############################################
# 5. Storage Account (Blob + Table)
############################################
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  kind                     = "StorageV2"
}

resource "azurerm_storage_container" "documents" {
  name                  = "documents"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_table" "checklist" {
  name                 = "checklist"
  storage_account_name = azurerm_storage_account.main.name
}

############################################
# 6. Logic App (Consumption)
############################################
resource "azurerm_logic_app_workflow" "main" {
  name                = var.logic_app_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Example placeholder action
resource "azurerm_logic_app_action_http" "sample_http_action" {
  logic_app_id = azurerm_logic_app_workflow.main.id
  name         = "sample-http-step"
  method       = "GET"
  uri          = "https://example.org/api/test"
  headers = {
    "Accept" = "application/json"
  }
}

############################################
# 7. Function App (for OCR & Indexing)
############################################
resource "azurerm_app_service_plan" "function_plan" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "main" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  version                    = "~3"

  # Example: app settings
  # site_config {
  #   app_settings = {
  #     "FUNCTIONS_EXTENSION_VERSION" = "~4"
  #     "WEBSITE_RUN_FROM_PACKAGE"    = "1"
  #   }
  # }
}

############################################
# 8. Azure Cognitive Search
############################################
resource "azurerm_search_service" "main" {
  name                = var.search_service_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku {
    name = "basic"
  }

  replica_count   = 1
  partition_count = 1
}

############################################
# 9. Azure OpenAI (via azapi)
############################################
resource "azapi_resource" "openai_account" {
  type      = "Microsoft.CognitiveServices/accounts@2022-12-01"
  name      = var.openai_account_name
  parent_id = azurerm_resource_group.main.id
  location  = azurerm_resource_group.main.location

  body = jsonencode({
    sku = {
      name = "S0"
      tier = "Standard"
    }
    kind = "OpenAI"
    properties = {
      customSubDomainName = var.openai_account_name
    }
  })
}

resource "azapi_resource" "openai_deployment" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2022-12-01"
  name      = "my-gpt-deployment"
  parent_id = azapi_resource.openai_account.id

  body = jsonencode({
    properties = {
      model = {
        format  = "OpenAI"
        name    = "gpt-35-turbo"
        version = "0301"
      }
    }
  })
}

############################################
# 10. Outputs
############################################
output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.main.name
}

output "logic_app_id" {
  description = "Logic App Resource ID"
  value       = azurerm_logic_app_workflow.main.id
}

output "function_app_url" {
  description = "Primary endpoint for the Function App"
  value       = azurerm_function_app.main.default_hostname
}

output "search_service_name" {
  description = "Cognitive Search Service Name"
  value       = azurerm_search_service.main.name
}

output "openai_resource_id" {
  description = "Azure OpenAI Resource ID"
  value       = azapi_resource.openai_account.id
}