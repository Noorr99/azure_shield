variable "resource_group_name" {
  type    = string
  default = "example-rg"
}

variable "location" {
  type    = string
  default = "northeurope"
}

variable "accounts_noorsheild_name" {
  type = string
  description = "Name of the Cognitive Services account (OpenAI)."
  default = "noorsheild"
}

variable "components_sheildnetwork_name" {
  type = string
  description = "Name of the Application Insights component."
  default = "sheildnetwork"
}

variable "networkSecurityGroups_nsg_subnet_ai_name" {
  type = string
  default = "nsg-subnet-ai"
}

variable "networkSecurityGroups_nsg_subnet_services_name" {
  type = string
  default = "nsg-subnet-services"
}

variable "privateDnsZones_privatelink_azurewebsites_net_name" {
  type = string
  default = "privatelink.azurewebsites.net"
}

variable "privateDnsZones_privatelink_blob_core_windows_net_name" {
  type = string
  default = "privatelink.blob.core.windows.net"
}

variable "privateDnsZones_privatelink_openai_azure_com_name" {
  type = string
  default = "privatelink.openai.azure.com"
}

variable "privateDnsZones_privatelink_search_windows_net_name" {
  type = string
  default = "privatelink.search.windows.net"
}

variable "storageAccounts_rgnetworking9b4d_name" {
  type = string
  default = "rgnetworking9b4d"
}

variable "storageAccounts_sheildnoor_name" {
  type = string
  default = "sheildnoor"
}

variable "searchServices_aisrch_noorsheild_name" {
  type = string
  default = "aisrch-noorsheild"
}

variable "serverfarms_ASP_rgnetworking_81f2_name" {
  type = string
  default = "ASP-rgnetworking-81f2"
}

variable "serverfarms_ASP_rgnetworking_b8b4_name" {
  type = string
  default = "ASP-rgnetworking-b8b4"
}

variable "sites_noor_shields_name" {
  type = string
  default = "noor-shields"
}

variable "sites_sheildnetwork_name" {
  type = string
  default = "sheildnetwork"
}

variable "privateEndpoints_noorfunction_name" {
  type = string
  default = "noorfunction"
}

# (Add additional variables as needed for the remaining parameters…)
