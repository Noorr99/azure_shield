variable "project_name" {
  type        = string
  description = "Project name prefix for all resources"
  default     = "shield-noor"
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
  default     = "East US"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for Virtual Network"
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  type        = map(string)
  description = "Address prefixes for subnets"
  default = {
    ai_services    = "10.0.1.0/24"
    other_services = "10.0.2.0/24"
    management     = "10.0.3.0/24"
  }
}

variable "vm_size" {
  type        = string
  description = "Size of the management VM"
  default     = "Standard_D2s_v3"
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for VM"
  default     = "adminuser"
}

variable "vm_admin_password" {
  type        = string
  description = "Admin password for VM"
  sensitive   = true
  default     = "P@ssw0rd1234!"
}

variable "storage_account_tier" {
  type        = string
  description = "Storage Account tier"
  default     = "Standard"
}

variable "storage_replication_type" {
  type        = string
  description = "Storage Account replication type"
  default     = "LRS"
}

variable "search_sku" {
  type        = string
  description = "Azure Cognitive Search SKU"
  default     = "basic"
}

variable "openai_sku" {
  type        = string
  description = "Azure OpenAI SKU"
  default     = "S0"
}

variable "acr_sku" {
  type        = string
  description = "Azure Container Registry SKU"
  default     = "Premium"
}