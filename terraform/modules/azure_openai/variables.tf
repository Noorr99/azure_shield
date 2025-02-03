variable "openai_name" {
  description = "Name of the Azure OpenAI service."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure location."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Azure OpenAI service."
  type        = map(string)
  default     = {}
}
