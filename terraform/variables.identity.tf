variable "managed_identities" {
  type = map(object({
    name              = string
    resource_group_id = optional(string)
    location          = optional(string)
    tags              = optional(map(string), {})
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
User-assigned managed identities created in deployment Stage 01, before any landing-zone workload resources.

The map key is deliberately arbitrary and stable. `resource_group_id` defaults to the compatibility resource group, `location` defaults to `resource_group_location`, and per-identity tags are merged over the root tags.
DESCRIPTION

  validation {
    condition = alltrue([
      for identity in values(var.managed_identities) :
      identity.resource_group_id == null || can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", identity.resource_group_id))
    ])
    error_message = "Each non-null managed identity `resource_group_id` must be a valid resource group resource ID."
  }
}
