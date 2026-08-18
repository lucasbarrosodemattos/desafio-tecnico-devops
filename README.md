# **Desafio Técnico Hands-On: ECS + ALB Isolado, Logging, State no S3 & Segurança IAM Granular**

### **0. Passo a Passo de Execução do Teste**

1. **Realizar o fork do repositório** para a conta pessoal do candidato no
   GitHub.
2. **Realizar todas as implementações no código do fork** (frontend, imagem
   Docker, workflow do GitHub Actions e infraestrutura Terraform/Terragrunt),
   conforme as seções abaixo.
3. **Ao terminar, notificar o time da Sensedia** informando a conclusão do
   desafio e **enviar o link do repositório** (fork) para avaliação.

> **Observação importante:** O candidato deve entregar **apenas os fontes** no
> repositório (código da aplicação, imagem Docker, workflow do GitHub Actions e
> infraestrutura Terraform/Terragrunt). **Não** é necessário deixar a
> infraestrutura em execução — a equipe da Sensedia utilizará uma **conta de
> testes** para validar a infraestrutura a partir dos fontes entregues.

---

### **1. Objetivo**

Provisionar uma infraestrutura de microsserviço com **Terraform** e **Terragrunt**, executando um container NGINX no **ECS** isolado em subnets privadas, acessível unicamente via **Application Load Balancer (ALB)**, com coleta de logs, *Health Check*, estado remoto no S3/DynamoDB e **políticas de IAM aplicando rigorosamente o princípio do menor privilégio (*Least Privilege*)**.

> **Modos de Execução (Escolha do Candidato):**
> * **Opção A (AWS Real):** Executar diretamente em uma conta AWS de testes/sandbox.
> * **Opção B (LocalStack - Opcional):** Executar localmente via Docker para simular a AWS sem custos.
>
>

---

### **2. Requisitos Obrigatórios de Arquitetura, Segurança & IAM**

* **Segurança IAM & Mínimo Acesso (Obrigatório):**
* **Separação de Papéis:** Diferenciar explicitamente a **ECS Task Execution Role** (utilizada pelo Fargate/ECS agent) da **ECS Task Role** (utilizada pela aplicação/container).
* **ECS Task Execution Role Granular:** Permitir apenas pull de imagens e gravação de logs. A política **NÃO pode usar `Resource: "*"`** nas ações do CloudWatch; deve restringir o campo `Resource` exclusivamente ao ARN do grupo de logs da aplicação (`arn:aws:logs:region:account:log-group:/ecs/nginx-app:*`).
* **ECS Task Role:** Como o NGINX não consome APIs da AWS, a Task Role deve ser criada com zero permissões ativas (ou não associada a políticas de escrita/leitura na AWS).
* **Sem Políticas Gerenciadas Genéricas:** Evitar o uso de `AdministratorAccess` ou `PowerUserAccess`.

* **Gestão de Estado Remoto (S3 + DynamoDB):**
* Backend remoto gerenciado pelo Terragrunt no **S3** com *state locking* via **DynamoDB**.
* Criptografia e versionamento ativos no bucket S3.

* **Rede & Isolamento:**
* VPC com Subnets Públicas (para o ALB) e Subnets Privadas (para o ECS).
* O container no ECS **não pode ter IP público** (`assign_public_ip = false` / alocado em subnet privada).

* **Segurança de Rede (Security Groups):**
* **Security Group do ALB:** Entrada liberada na porta `80` para `0.0.0.0/0`.
* **Security Group do ECS Task:** Entrada na porta `80` **restrita estritamente ao Security Group ID do ALB** (uso de referência por `security_groups`, sem liberar blocos CIDR).

* **ECS, Container & Observabilidade:**
* Imagem pública `nginx:latest`.
* **Health Check:** Configurado no Target Group do ALB (retorno HTTP `200` em `/`) e verificação nativa na Task Definition (`HEALTHCHECK`).
* CloudWatch Log Group dedicado com driver `awslogs`.

---

### **2.1. Imagem Docker & Publicação via GitHub Actions**

O candidato deve **criar a imagem Docker** do frontend NGINX e publicá-la em um
registro de containers (ex.: **Docker Hub**) para que o ECS possa baixá-la e
executá-la. **Somente a imagem** é entregue via **GitHub Actions** (CI/CD). A
**infraestrutura** (Terraform/Terragrunt) **não** é provisionada por CI — ela é
responsabilidade do candidato **rodar localmente** (na própria máquina), seja
na AWS real ou via LocalStack.

* **Dockerfile:** Deve empacotar o frontend estático (`src/`) em uma imagem
  NGINX. A definição do `Dockerfile` fica a critério do candidato.

* **Publicação no Docker Hub:** A imagem deve ser versionada com uma tag
  (ex.: `latest` e/ou o SHA do commit) e enviada ao repositório do candidato no
  Docker Hub.

* **Workflow GitHub Actions:** Criar um workflow (ex.:
  `.github/workflows/build-and-push.yml`) que construa a imagem e faça o push.
  A configuração do workflow (gatilhos, steps, actions utilizadas) fica a
  critério do candidato.

* **Integração com o ECS:** A `image` da Task Definition do ECS deve apontar
  para a imagem publicada no Docker Hub.

* **Exibição da versão na página:** O `index.html` já contém um campo
  **Versão** com o placeholder `__APP_VERSION__`. A **variável de ambiente
  `versão`** (ex.: `VERSION`/`VERSAO`) será **passada pelo ECS no momento do
  run do container** (definida no `environment` da Task Definition). A troca do
  placeholder deve ser realizada **quando o container de fato subir** — ou seja,
  em tempo de execução (no start do container), e não no build da imagem. A
  implementação fica a critério do candidato.

* **Infraestrutura roda localmente:** O provisionamento da infraestrutura
  (VPC, ALB, ECS, S3/DynamoDB, IAM) é executado manualmente pelo candidato na
  máquina local, seguindo as instruções da seção **6. Instruções de Teste** —
  não há pipeline de CI para a infra.

> **Segredos no GitHub Actions:** As credenciais do registro de containers
> devem ser armazenadas como *Secrets* do repositório, nunca no código.

---

### **3. Estrutura de Diretórios Esperada**

```text
.
├── docker-compose.yml         # Opcional: Apenas se optar por usar o LocalStack
├── modules/
│   └── ecs_nginx_app/        # Módulo reutilizável do Terraform
│       ├── main.tf            # VPC, SGs, ALB, ECS, IAM, CloudWatch
│       ├── variables.tf
│       └── outputs.tf
└── live/                     # Estrutura de ambientes Terragrunt
    ├── terragrunt.hcl        # Backend S3 global + Provider flexível
    ├── dev/
    │   └── terragrunt.hcl    # Instância do ambiente DEV
    ├── qa/
    │   └── terragrunt.hcl    # Instância do ambiente QA
    └── prod/
        └── terragrunt.hcl    # Instância do ambiente PROD

```

---

### **4. Configuração do Terragrunt com Backend S3 (`live/terragrunt.hcl`)**

```hcl
locals {
  use_localstack = get_env("USE_LOCALSTACK", "false") == "true"
  aws_region     = "us-east-1"
}

# Configuração do Remote State no S3 + DynamoDB Lock
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "devops-assessment-tfstate-${path_relative_to_include()}"
    key            = "terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "devops-assessment-tflocks"

    %{ if local.use_localstack }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    s3_force_path_style         = true
    endpoints = {
      s3       = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
    }
    %{ endif }
  }
}

# Override dinâmico do Provider AWS
generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  %{ if local.use_localstack }
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2   = "http://localhost:4566"
    ecs   = "http://localhost:4566"
    elbv2 = "http://localhost:4566"
    logs  = "http://localhost:4566"
    iam   = "http://localhost:4566"
    s3    = "http://localhost:4566"
  }
  %{ endif }
}
EOF
}

```

---

### **5. Especificação Explicita de IAM no Módulo Terraform (`modules/ecs_nginx_app`)**

O candidato deve criar as políticas de IAM explicitando os escopos:

```hcl
# Policy inline/custom para a Task Execution Role restrita ao Log Group específico
resource "aws_iam_policy" "ecs_execution_cw_policy" {
  name        = "ecs-execution-cloudwatch-policy"
  description = "Permite enviar logs apenas para o log group especifico do NGINX"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        # RESTRITO ao ARN exato do Log Group criado
        Resource = "${aws_cloudwatch_log_group.nginx_logs.arn}:*"
      }
    ]
  })
}

```

---

### **6. Instruções de Teste no README.md**

O candidato deve documentar a execução do teste:

* **AWS Real:** `aws configure` -> `cd live/dev` -> `terragrunt init` -> `terragrunt apply`
* **LocalStack (Opcional):** `docker compose up -d` -> `export USE_LOCALSTACK=true` -> `cd live/dev` -> `terragrunt apply`

**Validações Solicitadas:**

1. Acesso público bloqueado diretamente nas instâncias/tasks e liberado apenas pela URL do ALB (`curl http://<DNS_DO_ALB>`).
2. Confirmação do estado mantido no S3/DynamoDB.
3. Demonstração no código de que as políticas IAM do ECS usam escopos de recursos específicos (sem `Resource: "*"` para o CloudWatch).
4. Leitura dos logs no CloudWatch (`aws logs tail /ecs/nginx-app`).

---

### **7. Critérios de Avaliação**

| Requisito | O que será avaliado |
| --- | --- |
| **Granularidade do IAM** | Aplicação do princípio de menor privilégio. Verificação de que as roles do ECS especificam ARNs exatos de recursos no CloudWatch (sem coringas no `Resource`). |
| **Separação Task vs. Execution Role** | Distinção correta entre o papel da infraestrutura (Execution Role) e o da aplicação (Task Role). |
| **Gestão de Estado Remoto** | Configuração correta do backend S3 com trava DynamoDB gerenciados pelo Terragrunt. |
| **Ambientes (Dev, QA e Produção)** | Terragrunt estruturado em **três ambientes** (`dev`, `qa` e `prod`), cada um com sua instância/backend correspondente. |
| **Isolamento de Rede & SGs** | ECS em subnet privada e SG da Task restringindo o acesso unicamente ao SG do ALB. |
| **Resiliência & Observabilidade** | Health Checks ativos (ALB + Container) e logs fluindo para o CloudWatch via `awslogs`. |
