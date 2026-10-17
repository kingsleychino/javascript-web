# Names match the TF_VAR_* values the GitHub workflow sets:
#   TF_VAR_aws_region, TF_VAR_key_name, TF_VAR_private_key, TF_VAR_public_key

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the EC2 key pair to create"
  type        = string
  default     = "deployer-key"
}

variable "public_key" {
  description = "SSH public key (contents of the .pub file)"
  type        = string
}

variable "private_key" {
  description = "SSH private key, used only by provisioners"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR ranges allowed to SSH in. Narrow this to your own IP, e.g. [\"203.0.113.10/32\"]"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
