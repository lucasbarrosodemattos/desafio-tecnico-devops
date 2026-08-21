output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.application.dns_name
}

output "application_url" {
  description = "Public HTTP URL of the application"
  value       = "http://${aws_lb.application.dns_name}"
}

output "vpc_id" {
  description = "ID of the application VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.application.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.application.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Logs log group"
  value       = aws_cloudwatch_log_group.application.name
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.task.arn
}