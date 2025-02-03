output "search_service_id" {
  description = "The ID of the Azure Cognitive Search service."
  value       = azurerm_search_service.search.id
}

output "search_service_name" {
  description = "The name of the Azure Cognitive Search service."
  value       = azurerm_search_service.search.name
}
