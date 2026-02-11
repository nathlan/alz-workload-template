# Terraform variable definitions for insecure test configuration
# DO NOT USE IN PRODUCTION

location = "australiaeast"

account_tier = "Standard"

account_replication_type = "LRS"

account_kind = "StorageV2"

access_tier = "Hot"

containers = {
  public_data = {
    name                  = "public-data"
    container_access_type = "blob" # Public read access for blobs (insecure)
  }
}

tags = {
  Environment = "Testing"
  Security    = "Insecure"
  Purpose     = "Testing-Only"
}
