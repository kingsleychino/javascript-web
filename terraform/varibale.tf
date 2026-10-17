variable "region" {
  default = "us-east-1"
}

variable "private_key" {
  description = "Private key for SSH access"
  type        = string
  sensitive   = true
}

variable "public_key" {
  description = "Public key for SSH access"
  type        = string
}