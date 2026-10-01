variable "aws_region" {
  description = "AWS region for APEX-OS resources"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply to all APEX-OS IAM resources"
  type        = map(string)
  default = {
    Project     = "APEX-OS"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
