locals {
  template_path = abspath("${path.module}/${var.portal_template_path}")
  template_body = file(local.template_path)

  deployment_parameters = merge(
    var.portal_parameters,
    {
      enableTelemetry = var.enable_telemetry
    }
  )

  arm_parameters_content = jsonencode({
    for name, value in local.deployment_parameters :
    name => {
      value = value
    }
  })
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}

resource "azurerm_resource_group_template_deployment" "this" {
  name                = var.deployment_name
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode     = "Incremental"
  template_content    = local.template_body
  parameters_content  = local.arm_parameters_content
}
