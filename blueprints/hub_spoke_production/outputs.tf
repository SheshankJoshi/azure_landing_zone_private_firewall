output "deployment_enabled" {
  value       = local.enabled
  description = "Whether the blueprint passed every deployment safety gate."
}

output "deployment_sequence" {
  value = local.enabled ? {
    stage_00_scope                = terraform_data.stage_00_scope_complete[0].id
    stage_01_identities           = terraform_data.stage_01_identities_complete[0].id
    stage_02_resources            = terraform_data.stage_02_resources_complete[0].id
    stage_03_identity_attachments = terraform_data.stage_03_identity_attachments_complete[0].id
    stage_04_rbac                 = terraform_data.stage_04_rbac_complete[0].id
    stage_05_policy               = terraform_data.stage_05_policy_complete[0].id
  } : null
  description = "Completion identifiers for the explicitly enforced deployment sequence."
}

output "placeholder_warning" {
  value       = "This isolated blueprint contains intentionally invalid Marketplace and governance placeholders. Do not enable deployment until every gate and validation is satisfied."
  description = "Safety warning for consumers of this blueprint."
}
