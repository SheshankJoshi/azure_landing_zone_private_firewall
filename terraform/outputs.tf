output "resource_group_id" {
  value       = azapi_resource.resource_group.id
  description = "Resource group created for the landing zone deployment."
}

output "resource_group_name" {
  value       = azapi_resource.resource_group.name
  description = "Resource group name."
}

output "deployment_name" {
  value       = azapi_resource.legacy_arm_deployment.name
  description = "ARM deployment name."
}

output "template_path" {
  value       = local.template_path
  description = "Resolved path to the portal template."
}

output "managed_identities" {
  value = {
    for key, identity in azapi_resource.managed_identity : key => {
      resource_id  = identity.id
      client_id    = identity.output.properties.clientId
      principal_id = identity.output.properties.principalId
      tenant_id    = identity.output.properties.tenantId
    }
  }
  description = "User-assigned managed identities created in Stage 01, keyed by the caller-supplied stable map keys."
}

output "deployment_sequence" {
  value = {
    stage_00_scope      = terraform_data.stage_00_scope_complete.id
    stage_01_identities = terraform_data.stage_01_identities_complete.id
    legacy_arm          = azapi_resource.legacy_arm_deployment.id
  }
  description = "Completion identifiers for the currently implemented deployment stages."
}
