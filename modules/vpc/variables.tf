variable "vpc_cidr" {
  description = "The VPC CIDR must be /16"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "The VPC CIDR must be a /16 block (10.0.0.0/16)."
  }
}

variable "multi_az" {
  description = "If True, it creates multiple AZs"
  type        = bool
  default     = false
}

variable "egress_strategy" {
  description = "Egress strategy: 'single' for 1 NAT GW, 'multi' for 1 NAT GW per AZ"
  type        = string
  default     = "single"

  validation {
    condition     = var.egress_strategy == "single" || var.egress_strategy == "multi"
    error_message = "egress_strategy must be 'single' or 'multi'"
  }
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "custom"
}