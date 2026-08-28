locals {
  governance_scope_id           = var.management_group.mode == "create" ? try(azapi_resource.management_group[0].id, null) : var.management_group.existing_id
  enabled_policy_definition_ids = local.enabled ? var.policy_definition_ids : {}
}

resource "azapi_resource" "governance_policy_assignment" {
  for_each = local.enabled_policy_definition_ids

  type      = var.resource_types.policy_assignments
  name      = uuidv5("url", "${local.governance_scope_id}|${each.key}")
  parent_id = local.governance_scope_id

  body = {
    properties = {
      description     = "Placeholder assignment for ${each.key}; replace with reviewed parameters and exemptions."
      displayName     = "Placeholder: ${replace(each.key, "_", " ")}"
      enforcementMode = "DoNotEnforce"
      metadata = {
        assignedBy = "hub_spoke_production blueprint"
      }
      parameters         = {}
      policyDefinitionId = each.value
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.policy_assignments) > 0 ? var.ignore_body_changes.policy_assignments : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [terraform_data.stage_04_rbac_complete]
}

resource "terraform_data" "stage_05_policy_complete" {
  count = local.enabled ? 1 : 0

  input = {
    policy_assignment_ids = {
      for key, assignment in azapi_resource.governance_policy_assignment : key => assignment.id
    }
  }

  depends_on = [azapi_resource.governance_policy_assignment]
}
