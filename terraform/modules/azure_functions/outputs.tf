output "function_app_id" {
  description = "The ID of the Azure Function App."
  value       = azurerm_function_app.functions_app.id
}

output "service_plan_id" {
  description = "The ID of the Service Plan."
  value       = azurerm_service_plan.functions_plan.id
}

output "storage_account_name" {
  description = "The name of the Storage Account created for the Function App."
  value       = azurerm_storage_account.functions_storage.name
}
