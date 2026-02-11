locals {
  workload = "webapp"
  env      = "prod"
  team     = "finance"
}

module "resource_group" {
  source = "github.com/nathlan/terraform-azurerm-resource-group"

  workload = local.workload
  env      = local.env
  team     = local.team
  location = "australiaeast"

  tags = {
    ManagedBy  = "Terraform"
    CostCenter = "12345"
  }

  lock = {
    kind = "CanNotDelete"
  }
}
# Consume the storage account module with insecure settings
module "insecure_storage" {
  source = "github.com/nathlan/terraform-azurerm-storage-account"

  workload            = local.workload
  env                 = local.env
  team                = local.team
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  # Insecure settings - DO NOT USE IN PRODUCTION
  min_tls_version               = "TLS1_0" # Use  older TLS versions (insecure)
  enable_https_traffic_only     = false    # Allow HTTP traffic (insecure)
  public_network_access_enabled = true     # Allow public access (insecure)

  # No network rules - allows all traffic (insecure)
  network_rules = null

  # No blob properties - no versioning, no soft delete (insecure)
  blob_properties = null

  # Basic account configuration
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  # Create some containers with public access (insecure)
  containers = var.containers

  tags = var.tags
}
