output "functions_app_name" {
  description = "The name of the Azure Functions app."
  value       = azurerm_linux_function_app.functions_app.name
}

output "functions_app_default_hostname" {
  description = "The default hostname of the Azure Functions app."
  value       = azurerm_linux_function_app.functions_app.default_site_hostname
}

output "functions_plan_id" {
  description = "The ID of the App Service Plan used by the Functions app."
  value       = azurerm_service_plan.functions_plan.id
}

output "functions_storage_account_name" {
  description = "The name of the Storage Account used by the Functions app."
  value       = azurerm_storage_account.functions_storage.name
}
