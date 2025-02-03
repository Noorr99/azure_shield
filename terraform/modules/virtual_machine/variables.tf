variable "resource_group_name" {
  description = "(Required) Specifies the resource group name of the virtual machine"
  type        = string
}

variable "name" {
  description = "(Required) Specifies the name of the virtual machine"
  type        = string
}

variable "size" {
  description = "(Required) Specifies the size of the virtual machine"
  type        = string
}

variable "os_disk_image" {
  description = "(Optional) Specifies the OS disk image of the Windows virtual machine"
  type        = map(string)
  default     = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

variable "os_disk_storage_account_type" {
  description = "(Optional) Specifies the storage account type of the OS disk of the virtual machine"
  default     = "StandardSSD_LRS"
  type        = string

  validation {
    condition     = contains(
      ["Premium_LRS", "Premium_ZRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Standard_LRS"],
      var.os_disk_storage_account_type
    )
    error_message = "The storage account type of the OS disk is invalid."
  }
}

variable "public_ip" {
  description = "(Optional) Specifies whether to create a public IP for the virtual machine"
  type        = bool
  default     = false
}

variable "location" {
  description = "(Required) Specifies the location of the virtual machine"
  type        = string
}

variable "domain_name_label" {
  description = "(Required) Specifies the DNS domain name of the virtual machine"
  type        = string
}

variable "subnet_id" {
  description = "(Required) Specifies the resource ID of the subnet hosting the virtual machine"
  type        = string
}

variable "vm_user" {
  description = "(Required) Specifies the username of the virtual machine"
  type        = string
  default     = "azadmin"
}

variable "admin_password" {
  description = "(Required) Specifies the administrator password for the Windows virtual machine"
  type        = string
  sensitive   = true
}

variable "boot_diagnostics_storage_account" {
  description = "(Optional) The primary/secondary endpoint for the Azure Storage Account used to store Boot Diagnostics."
  default     = ""
}

variable "tags" {
  description = "(Optional) Specifies the tags of the virtual machine"
  default     = {}
}
