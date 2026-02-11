variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to create."
}

variable "location" {
  type        = string
  description = "The Azure location where resources should be created."
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account. Must be globally unique."
}

variable "account_tier" {
  type        = string
  description = "Defines the Tier to use for this storage account."
}

variable "account_replication_type" {
  type        = string
  description = "Defines the type of replication to use for this storage account."
}

variable "account_kind" {
  type        = string
  description = "Defines the Kind of account."
}

variable "access_tier" {
  type        = string
  description = "Defines the access tier for the storage account."
}

variable "containers" {
  type = map(object({
    name                  = string
    container_access_type = optional(string, "private")
    metadata              = optional(map(string), {})
  }))
  description = "Map of blob containers to create."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to resources."
}
