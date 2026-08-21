include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/modules/ecs_nginx_app"
}

inputs = {
  project_name = "sensedia-devops"
  environment  = "dev"

  vpc_cidr = "10.10.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnet_cidrs = [
    "10.10.1.0/24",
    "10.10.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.10.11.0/24",
    "10.10.12.0/24"
  ]

  nat_gateway_count = 1

  container_image  = "docker.io/lucasbarrosodemattos/desafio-tecnico-devops:sha-8d8f435"
  container_name   = "nginx"
  container_port   = 80
  container_cpu    = 256
  container_memory = 512
  desired_count    = 1
  app_version      = "dev-sha-8d8f435"

  log_retention_in_days = 7

  tags = {
    Environment = "dev"
    Owner       = "Lucas Barroso de Mattos"
    Repository  = "desafio-tecnico-devops"
  }
}