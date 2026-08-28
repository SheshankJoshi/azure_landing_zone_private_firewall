resource "azapi_resource" "resource_group" {
  type      = var.resource_types.resources_resource_groups
  name      = var.resource_group_name
  parent_id = local.subscription_resource_id
  location  = var.resource_group_location
  tags      = var.tags

  body = {}

  ignore_body_changes    = length(var.ignore_body_changes.resources_resource_groups) > 0 ? var.ignore_body_changes.resources_resource_groups : null
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
}

resource "terraform_data" "stage_00_scope_complete" {
  input = {
    resource_group_id = azapi_resource.resource_group.id
  }

  depends_on = [azapi_resource.resource_group]
}
