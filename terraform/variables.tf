variable "prefix" {
  type        = string
  description = "Prefix for all resource names"
  default     = "demo"
}

variable "location" {
  type        = string
  description = "Azure Region"
  default     = "northeurope"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for VNet"
  default     = ["10.0.0.0/16"]
}

variable "subnet_services_cidr" {
  type        = string
  description = "CIDR for 'services' subnet"
  default     = "10.0.1.0/24"
}

variable "subnet_ai_cidr" {
  type        = string
  description = "CIDR for 'ai' subnet"
  default     = "10.0.2.0/24"
}

# Example NSG rules—adjust to your needs
variable "nsg_rules" {
  type        = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
    description                = string
  }))
  description = "List of NSG rules to apply to each subnet."
  default = [
    {
      name                       = "AllowAzureLoadBalancer"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      description                = "Allow inbound from Azure Load Balancer"
    }
    # Add more custom rules as needed
  ]
}

variable "tags" {
  type        = map(string)
  description = "Common tags for resources"
  default     = {
    environment = "dev"
    owner       = "team-xyz"
  }
}
