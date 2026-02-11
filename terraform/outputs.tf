output "resource_group_name" {
  description = "The name of the resource group."
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "The location of the resource group."
  value       = module.resource_group.location
}

output "resource_group_id" {
  description = "The ID of the resource group."
  value       = module.resource_group.resource_id
}

output "storage_account_id" {
  description = "The ID of the storage account."
  value       = module.insecure_storage.storage_account_id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = module.insecure_storage.storage_account_name
}

output "primary_blob_endpoint" {
  description = "The endpoint URL for blob storage."
  value       = module.insecure_storage.primary_blob_endpoint
}

output "primary_connection_string" {
  description = "The primary connection string for the storage account."
  value       = module.insecure_storage.primary_connection_string
  sensitive   = true
}

output "primary_access_key" {
  description = "The primary access key for the storage account."
  value       = module.insecure_storage.primary_access_key
  sensitive   = true
}
