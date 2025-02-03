output "function_app_id" {
  description = "The ID of the Azure Function App."
  value       = azurerm_function_app.functions_app.id
}

output "managed_identity_principal_id" {
  description = "The managed identity principal ID of the Function App."
  value       = azurerm_function_app.functions_app.identity[0].principal_id
}
