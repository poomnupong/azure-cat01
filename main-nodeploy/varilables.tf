variable "BRANCH" {
  type        = string
  description = "git branch name for use as resource name"
  default     = "bbb"
}

variable "PREFIX" {
  type        = string
  description = "prefix for use as resource name"
  default     = "ppp"
}

variable "REGION" {
  type        = string
  description = "region for use as resource name"
  default     = "southcentralus"
}
