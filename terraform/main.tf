# Deliberately insecure configuration for testing purposes
# DO NOT USE IN PRODUCTION

# Create a resource group using the public module
module "resource_group" {
  source = "github.com/nathlan/terraform-azurerm-resourcegroup"

  name = var.resource_group_name
  tags = var.tags
}

# Consume the storage account module with insecure settings
module "insecure_storage" {
  source = "github.com/nathlan/terraform-azurerm-storage-account"

  name                = var.storage_account_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  # Insecure settings - DO NOT USE IN PRODUCTION
  min_tls_version               = "TLS1_0" # Allow older TLS versions (insecure)
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
