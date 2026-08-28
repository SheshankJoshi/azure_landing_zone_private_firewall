output "resource_group_id" {
  value       = azurerm_resource_group.this.id
  description = "Resource group created for the landing zone deployment."
}

output "resource_group_name" {
  value       = azurerm_resource_group.this.name
  description = "Resource group name."
}

output "deployment_name" {
  value       = azurerm_resource_group_template_deployment.this.name
  description = "ARM deployment name."
}

output "template_path" {
  value       = local.template_path
  description = "Resolved path to the portal template."
}
