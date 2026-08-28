resource "azapi_resource" "management_group" {
  count = local.enabled && var.management_group.mode == "create" ? 1 : 0

  type      = var.resource_types.management_groups
  name      = var.management_group.name
  parent_id = "/"

  body = {
    properties = {
      displayName = var.management_group.display_name
      details = var.management_group.parent_resource_id == null ? null : {
        parent = {
          id = var.management_group.parent_resource_id
        }
      }
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.management_groups) > 0 ? var.ignore_body_changes.management_groups : null
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

  depends_on = [terraform_data.deployment_authorization]

  lifecycle {
    prevent_destroy = true
  }
}

resource "azapi_resource" "resource_group" {
  for_each = local.enabled_resource_groups

  type      = var.resource_types.resource_groups
  name      = each.value.name
  parent_id = "/subscriptions/${each.value.subscription_id}"
  location  = var.location
  tags      = var.tags

  body = {}

  ignore_body_changes    = length(var.ignore_body_changes.resource_groups) > 0 ? var.ignore_body_changes.resource_groups : null
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

  depends_on = [terraform_data.deployment_authorization]

  lifecycle {
    prevent_destroy = true
  }
}

resource "azapi_resource" "management_group_subscription" {
  for_each = local.enabled_subscription_enrollments

  type      = var.resource_types.management_group_subscriptions
  name      = each.value
  parent_id = var.management_group.mode == "create" ? azapi_resource.management_group[0].id : var.management_group.existing_id

  body = {}

  ignore_body_changes    = length(var.ignore_body_changes.management_group_subscriptions) > 0 ? var.ignore_body_changes.management_group_subscriptions : null
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

  depends_on = [terraform_data.deployment_authorization]
}

resource "terraform_data" "stage_00_scope_complete" {
  count = local.enabled ? 1 : 0

  input = {
    management_group_id = var.management_group.mode == "create" ? azapi_resource.management_group[0].id : var.management_group.existing_id
    enrolled_subscriptions = {
      for key, enrollment in azapi_resource.management_group_subscription : key => enrollment.id
    }
    resource_group_ids = { for key, resource_group in azapi_resource.resource_group : key => resource_group.id }
  }

  depends_on = [
    azapi_resource.management_group,
    azapi_resource.management_group_subscription,
    azapi_resource.resource_group,
    terraform_data.deployment_authorization,
  ]
}
