data "azapi_client_config" "deployment" {
  count = var.deployment_enabled ? 1 : 0
}

resource "terraform_data" "deployment_authorization" {
  count = var.deployment_enabled ? 1 : 0

  input = {
    active_principal_id = data.azapi_client_config.deployment[0].object_id
  }

  lifecycle {
    precondition {
      condition = (
        !startswith(local.pinned_env0_deployment_principal_id, "REPLACE_") &&
        lower(data.azapi_client_config.deployment[0].object_id) == lower(local.pinned_env0_deployment_principal_id)
      )
      error_message = "Deployment is blocked: pin the reviewed env0 principal ID in locals.tf, and run with that federated identity."
    }
  }
}
