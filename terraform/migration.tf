removed {
  from = azurerm_resource_group.this

  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_resource_group_template_deployment.this

  lifecycle {
    destroy = false
  }
}

import {
  for_each = var.migrate_legacy_azurerm_state ? toset(["resource_group"]) : toset([])

  to = azapi_resource.resource_group
  id = "${local.subscription_resource_id}/resourceGroups/${var.resource_group_name}"
}

import {
  for_each = var.migrate_legacy_azurerm_state ? toset(["legacy_arm_deployment"]) : toset([])

  to = azapi_resource.legacy_arm_deployment
  id = "${local.subscription_resource_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Resources/deployments/${var.deployment_name}"
}
