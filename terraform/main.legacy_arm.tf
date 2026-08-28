resource "azapi_resource" "legacy_arm_deployment" {
  type      = var.resource_types.resources_deployments
  name      = var.deployment_name
  parent_id = azapi_resource.resource_group.id

  body = {
    properties = {
      mode       = "Incremental"
      parameters = local.arm_parameters
      template   = local.template_body
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.resources_deployments) > 0 ? var.ignore_body_changes.resources_deployments : null
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

  depends_on = [terraform_data.stage_01_identities_complete]
}
