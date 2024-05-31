variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so the name is unique in your Azure subscription."
}

variable "owner_email" {
  type        = string
  default     = "andreas@confluent.io"
  description = "Identifier for all created resources."
}

variable "source_address_prefix" {
  type        = string
  default     = "0.0.0.0"
  description = "Source IP address allowed to make SSH / Kafka connections."
}
