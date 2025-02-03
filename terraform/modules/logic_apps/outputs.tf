output "logic_app_id" {
  description = "The ID of the Logic Apps instance."
  value       = azurerm_logic_app_standard.logic_app.id
}

output "managed_identity_principal_id" {
  description = "The managed identity principal ID of the Logic Apps instance."
  value       = azurerm_logic_app_standard.logic_app.identity[0].principal_id
}
