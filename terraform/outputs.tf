output "resource_group_name" {
  value = azurerm_resource_group.shield_noor.name
}

output "vnet_id" {
  value = azurerm_virtual_network.shield_noor.id
}

output "subnet_ids" {
  value = {
    ai_services    = azurerm_subnet.ai_services.id
    other_services = azurerm_subnet.other_services.id
    management     = azurerm_subnet.management.id
  }
}

output "storage_account_name" {
  value = azurerm_storage_account.shield_noor.name
}

output "storage_primary_access_key" {
  value     = azurerm_storage_account.shield_noor.primary_access_key
  sensitive = true
}

output "cognitive_search_endpoint" {
  value = azurerm_search_service.shield_noor.endpoint
}

output "openai_endpoint" {
  value = azapi_resource.shield_noor_openai.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.shield_noor.login_server
}

output "container_registry_admin_username" {
  value = azurerm_container_registry.shield_noor.admin_username
}

output "container_registry_admin_password" {
  value     = azurerm_container_registry.shield_noor.admin_password
  sensitive = true
}

output "function_app_hostname" {
  value = azurerm_linux_function_app.shield_noor.default_hostname
}

output "management_vm_public_ip" {
  value = azurerm_public_ip.management.ip_address
}

output "management_vm_private_ip" {
  value = azurerm_network_interface.management.private_ip_address
}