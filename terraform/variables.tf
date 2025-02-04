variable "resource_group_name" {
  type    = string
  default = "shield-rg"
}

variable "location" {
  type    = string
  default = "northeurope"
}

variable "sites_noor_shields_name" {
  type    = string
  default = "noor-shields"
}

variable "sites_sheildnetwork_name" {
  type    = string
  default = "sheildnetwork"
}

variable "privateEndpoints_pe_blob_name" {
  type    = string
  default = "pe-blob"
}

variable "components_sheildnetwork_name" {
  type    = string
  default = "sheildnetwork"
}

variable "virtualNetworks_vnet_prod_name" {
  type    = string
  default = "vnet-prod"
}

variable "privateEndpoints_pe_aisrch_name" {
  type    = string
  default = "pe-aisrch"
}

variable "storageAccounts_sheildnoor_name" {
  type    = string
  default = "sheildnoor"
}

variable "accounts_noorsheild_name" {
  type    = string
  default = "noorsheild"
}

variable "privateEndpoints_noorfunction_name" {
  type    = string
  default = "noorfunction"
}

variable "serverfarms_ASP_rgnetworking_81f2_name" {
  type    = string
  default = "ASP-rgnetworking-81f2"
}

variable "serverfarms_ASP_rgnetworking_b8b4_name" {
  type    = string
  default = "ASP-rgnetworking-b8b4"
}

variable "privateEndpoints_pe_noorshield_name" {
  type    = string
  default = "pe-noorshield"
}

variable "privateEndpoints_pe_openai_east_name" {
  type    = string
  default = "pe-openai-east"
}

variable "searchServices_aisrch_noorsheild_name" {
  type    = string
  default = "aisrch-noorsheild"
}

variable "storageAccounts_rgnetworking9b4d_name" {
  type    = string
  default = "rgnetworking9b4d"
}

variable "storageAccounts_rgnetworkingb244_name" {
  type    = string
  default = "rgnetworkingb244"
}

variable "networkSecurityGroups_nsg_subnet_ai_name" {
  type    = string
  default = "nsg-subnet-ai"
}

variable "networkSecurityGroups_nsg_subnet_services_name" {
  type    = string
  default = "nsg-subnet-services"
}

variable "privateDnsZones_privatelink_openai_azure_com_name" {
  type    = string
  default = "privatelink.openai.azure.com"
}

variable "privateDnsZones_privatelink_azurewebsites_net_name" {
  type    = string
  default = "privatelink.azurewebsites.net"
}

variable "privateDnsZones_privatelink_search_windows_net_name" {
  type    = string
  default = "privatelink.search.windows.net"
}

variable "privateDnsZones_privatelink_vaultcore_azure_net_name" {
  type    = string
  default = "privatelink.vaultcore.azure.net"
}

variable "privateDnsZones_privatelink_blob_core_windows_net_name" {
  type    = string
  default = "privatelink.blob.core.windows.net"
}

variable "privateDnsZones_privatelink_table_core_windows_net_name" {
  type    = string
  default = "privatelink.table.core.windows.net"
}

variable "workspaces_DefaultWorkspace_3e169b7b_edb6_4452_94b0_847f2917971a_NEU_externalid" {
  type    = string
  default = ""   # Provide your Log Analytics workspace resource ID here.
}
