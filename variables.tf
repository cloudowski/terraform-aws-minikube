variable "env_name" {
  description = "String used as a prefix for AWS resources"
  type        = string
}

variable "subnet_id" {
  description = "ID of the AWS subnet"
  type        = string
}

variable "vpc_id" {
  description = "ID of the AWS VPC"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3a.large"
}

variable "instance_disk_size" {
  description = "Instance disk size (in GB)"
  type        = number
  default     = 50
}
