output "vm_id" {
  description = "The ID of the Windows virtual machine."
  value       = azurerm_windows_virtual_machine.virtual_machine.id
}

output "computer_name" {
  description = "The computer name of the Windows virtual machine."
  value       = azurerm_windows_virtual_machine.virtual_machine.computer_name
}

output "public_ip_address" {
  description = "The public IP address of the Windows virtual machine (if one was created)."
  value       = length(azurerm_public_ip.public_ip) > 0 ? azurerm_public_ip.public_ip[0].ip_address : ""
}
