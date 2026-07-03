variable "vpc_cidr" {
  description = "CIDR block for the CloudFlow VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "az" {
  description = "Availability Zone for subnets"
  type        = string
  default     = "eu-north-1a"
}

variable "my_ip" {
  description = "Your public IP in CIDR form, for SSH access"
  type        = string
  # no default — we pass it at apply time so it's never stale in the file
}