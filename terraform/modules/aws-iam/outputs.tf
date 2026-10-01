output "apex_core_role_arn" {
  description = "ARN of the APEX-OS core role"
  value       = aws_iam_role.apex_core.arn
}

output "apex_core_role_name" {
  description = "Name of the APEX-OS core role"
  value       = aws_iam_role.apex_core.name
}

output "apex_agent_role_arn" {
  description = "ARN of the APEX-OS agent execution role"
  value       = aws_iam_role.apex_agent.arn
}

output "apex_agent_role_name" {
  description = "Name of the APEX-OS agent execution role"
  value       = aws_iam_role.apex_agent.name
}

output "apex_admin_role_arn" {
  description = "ARN of the APEX-OS admin role"
  value       = aws_iam_role.apex_admin.arn
}

output "apex_admin_role_name" {
  description = "Name of the APEX-OS admin role"
  value       = aws_iam_role.apex_admin.name
}

output "kms_key_arn" {
  description = "ARN of the APEX-OS KMS key"
  value       = aws_kms_key.apex.arn
}

output "kms_key_id" {
  description = "ID of the APEX-OS KMS key"
  value       = aws_kms_key.apex.key_id
}
