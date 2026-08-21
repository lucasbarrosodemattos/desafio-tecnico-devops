variable "project_name" {
  description = "Name used as a prefix for AWS resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be dev, qa, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block assigned to the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Two availability zones used by the application."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "Exactly two different availability zones must be provided."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets."
  type        = list(string)

  validation {
    condition = (
      length(var.public_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Exactly two valid public subnet CIDR blocks must be provided."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets."
  type        = list(string)

  validation {
    condition = (
      length(var.private_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Exactly two valid private subnet CIDR blocks must be provided."
  }
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways. Use one for dev/qa and two for prod."
  type        = number

  validation {
    condition     = contains([1, 2], var.nat_gateway_count)
    error_message = "nat_gateway_count must be either 1 or 2."
  }
}

variable "container_image" {
  description = "Public Docker image executed by the ECS tasks."
  type        = string

  validation {
    condition     = length(trimspace(var.container_image)) > 0
    error_message = "container_image cannot be empty."
  }
}

variable "container_name" {
  description = "Name assigned to the application container."
  type        = string
  default     = "nginx"
}

variable "container_port" {
  description = "Port exposed by the application container."
  type        = number
  default     = 80

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "container_cpu" {
  description = "CPU units allocated to each Fargate task."
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.container_cpu)
    error_message = "container_cpu must be a value supported by AWS Fargate."
  }
}

variable "container_memory" {
  description = "Memory in MiB allocated to each Fargate task."
  type        = number
  default     = 512

  validation {
    condition     = var.container_memory >= 512
    error_message = "container_memory must be at least 512 MiB."
  }
}

variable "desired_count" {
  description = "Number of ECS tasks maintained by the service."
  type        = number

  validation {
    condition     = var.desired_count >= 1 && floor(var.desired_count) == var.desired_count
    error_message = "desired_count must be a positive whole number."
  }
}

variable "app_version" {
  description = "Application version injected into the HTML when the container starts."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.app_version))
    error_message = "app_version may contain only letters, numbers, dots, underscores, and hyphens."
  }
}

variable "alb_health_check_path" {
  description = "HTTP path used by the ALB Target Group health check."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.alb_health_check_path, "/")
    error_message = "alb_health_check_path must start with a slash."
  }
}

variable "container_health_check_path" {
  description = "HTTP path used by the native ECS container health check."
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.container_health_check_path, "/")
    error_message = "container_health_check_path must start with a slash."
  }
}

variable "log_retention_in_days" {
  description = "Number of days that CloudWatch Logs retains application logs."
  type        = number

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.log_retention_in_days
    )
    error_message = "log_retention_in_days must be a value supported by CloudWatch Logs."
  }
}

variable "tags" {
  description = "Additional tags applied to all supported AWS resources."
  type        = map(string)
  default     = {}
}