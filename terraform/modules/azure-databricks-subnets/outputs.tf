output "private_subnet_name" {
  value       = azurerm_subnet.private-subnet.name
  description = "Name of private subnet"
}

output "private_subnet_id" {
  value       = azurerm_subnet.private-subnet.id
  description = "ID of private subnet"
}

output "public_subnet_name" {
  value       = azurerm_subnet.public-subnet.name
  description = "Name of public subnet"
}

output "public_subnet_id" {
  value       = azurerm_subnet.public-subnet.id
  description = "ID of public subnet"
}

output "private_subnet_prefixes" {
  value       = azurerm_subnet.private-subnet.address_prefixes
  description = "Address spaces of the private subnet"
}

output "public_subnet_prefixes" {
  value       = azurerm_subnet.public-subnet.address_prefixes
  description = "Address spaces of the public subnet"
}
