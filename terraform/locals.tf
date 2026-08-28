locals {
  subscription_id          = coalesce(var.subscription_id, data.azapi_client_config.current.subscription_id)
  subscription_resource_id = "/subscriptions/${local.subscription_id}"
  template_path            = abspath("${path.module}/${var.portal_template_path}")
  template_body            = jsondecode(file(local.template_path))

  deployment_parameters = merge(
    var.portal_parameters,
    {
      enableTelemetry = var.enable_telemetry
    }
  )

  arm_parameters = {
    for name, value in local.deployment_parameters :
    name => {
      value = value
    }
  }
}
