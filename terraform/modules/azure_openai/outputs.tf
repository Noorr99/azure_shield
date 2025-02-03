output "openai_id" {
  description = "The ID of the Azure OpenAI service."
  value       = azurerm_cognitive_account.openai.id
}

output "openai_name" {
  description = "The name of the Azure OpenAI service."
  value       = azurerm_cognitive_account.openai.name
}
