variable "prefix" {
  type        = string
  description = "main prefix in front of most infra for multi-user accounts"
  default     = "hackathon"
}

variable "common_tags" {
  type        = map(string)
  description = "tags common to all taggable resources"
  default = {
    Env     = "dev"
    Owner   = "PlatformTeam"
    Project = "Hackathon"
    Name    = "Hackathon object"
  }
}



variable "vpc_cidr" {
  type        = string
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of public subnet CIDR ranges to create in VPC."
  default     = [
    "10.0.0.0/19"
  ]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of private subnet CIDR ranges to create in VPC."
  default     = [
    "10.0.64.0/19"
  ]
}
