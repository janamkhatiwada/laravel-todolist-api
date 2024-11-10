## Local Setup

Make sure you have the following installed:

- Docker & Docker Compose
- Git
- PHP Composer

## Local Setup Instructions

### 1. Clone the Repository

Clone the repository from GitHub:

```bash
git clone https://github.com/janamkhatiwada/laravel-todolist-api.git
cd laravel-todolist-api
```

### 2. Configure Environment

Copy the example environment file and adjust environment variables as needed:

```bash
cp .env.example .env
```

Update `.env` with the following configuration for Docker:

```env
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel_user
DB_PASSWORD=laravel_password

REDIS_HOST=redis
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025

FILESYSTEM_DRIVER=s3
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadminpassword
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-bucket-name
AWS_URL=http://localhost:9000
```

Replace `your-bucket-name` with the desired bucket name for MinIO.

### 3. Build Docker Image

Build the Docker image to ensure the `app` service has all the necessary dependencies and configurations:

```bash
docker-compose build app
```

### 4. Install Composer Dependencies

Run Composer to install the necessary dependencies:

```bash
docker-compose run --rm app composer install
```

### 5. Generate Application Key

Run the following command to generate the application key:

```bash
docker-compose run --rm app php artisan key:generate
```

### 6. Run Migrations and Seed Database

Run the migrations to create the database tables and seed initial data:

```bash
docker-compose run --rm app php artisan migrate --seed
```

### 7. Start Docker Containers

Finally, start the Docker containers:

```bash
docker-compose up -d
```

This will start:

- `app`: The PHP application container.
- `webserver`: Nginx for serving the Laravel app.
- `db`: MySQL for database storage.
- `redis`: Redis for caching and queueing.
- `mailhog`: MailHog for capturing emails sent by Laravel (accessible at `http://localhost:8025`).
- `minio`: MinIO as an S3-compatible storage service (API on `http://localhost:9000` and Console at `http://localhost:9001`).

### 8. Access the Application

You should now be able to access the application at `http://localhost:8000`.

---

### Additional Access Information:

- **MailHog**: Check captured emails at `http://localhost:8025`.
- **MinIO Console**: Manage S3-compatible storage at `http://localhost:9001` with credentials `minioadmin`/`minioadminpassword`.


# Deployment with Terraform and GitHub Actions CI/CD

## Prerequisites

1. **AWS Account**: Ensure you have an AWS account with IAM permissions to manage resources.
2. **GitHub Repository Secrets**: Set up the following secrets in your GitHub repository:
   - `AWS_ACCESS_KEY_ID`: AWS Access Key ID for Terraform access.
   - `AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key for Terraform access.
   - `TOKEN`: Personal GitHub token to enable manual approval.
3. **Create Secrets Manager for env variables**: Before doing tf apply please create secrets manager for api. Those env variables will be used in application setup. And update secrets-name accordingly in terraform/provisioner/install_dependencies.sh. Line no: 35 and 36     

## Project Structure

The project uses Terraform for infrastructure provisioning and GitHub Actions for the CI/CD workflow. Below is an example directory structure:

```plaintext
.
├── main.tf                # Main Terraform configuration file
├── variables.tf           # Terraform variable definitions
├── modules/               # Terraform modules for networking, autoscaling, IAM, etc.
├── provisioner/
│   └── install_dependencies.sh   # Script for provisioning instances
└── .github/
    └── workflows/
        └── deploy.yml     # GitHub Actions CI/CD workflow
```

## Workflow Overview

### Workflow Triggers

The workflow (`deploy.yml`) triggers on:
- **Push to `main` branch**: Initiates deployment for changes merged to the `main` branch.
- **Manual Dispatch**: Allows manual triggering of the workflow via GitHub's UI (`workflow_dispatch`).

### Workflow Steps

1. **terraform-plan**: This job includes steps to plan, manually approve, and apply Terraform changes on AWS.

#### Steps in Detail

1. **Checkout repository**: Clones the GitHub repository into the workflow environment.
   
   ```yaml
   - name: Checkout repository
     uses: actions/checkout@v3
   ```

2. **Setup Terraform**: Installs Terraform, ensuring the environment is ready for running Terraform commands.
   
   ```yaml
   - name: Setup Terraform
     uses: hashicorp/setup-terraform@v2
     with:
       terraform_wrapper: false
   ```

3. **Configure AWS credentials**: Configures AWS credentials using GitHub secrets to grant access to AWS resources.
   
   ```yaml
   - name: Configure AWS credentials
     uses: aws-actions/configure-aws-credentials@v2
     with:
       aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
       aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
       aws-region: us-east-1
   ```

4. **Plan Terraform**: Initializes Terraform and creates an execution plan without making any changes. The output is saved as `tfplan`, which shows the infrastructure changes.
   
   ```yaml
   - name: Plan Terraform
     id: terraform_plan
     run: cd terraform && terraform init && terraform plan -out=tfplan
   ```

5. **Manual Approval**: Requests manual approval before applying changes. An issue is created in the repository for specified approvers to review and approve.
   
   ```yaml
   - uses: trstringer/manual-approval@v1
     with:
       secret: ${{ secrets.TOKEN }}
       approvers: janamkhatiwada
       minimum-approvals: 1
       issue-title: "Deploying to prod"
       issue-body: "Review the terraform plan, then approve or deny the deployment to prod."
       exclude-workflow-initiator-as-approver: false
   ```

6. **Terraform apply**: If approval is granted, the `terraform apply` command is executed to apply the changes and deploy the infrastructure to AWS.
   
   ```yaml
   - name: Terraform apply
     run: |
       cd terraform && terraform apply
   ```

## Deployment Configuration Details

The deployment configuration provisions a highly available, autoscaling setup on AWS using:

1. **Launch Templates**: Configures instances with user data scripts for initial setup.
2. **Auto Scaling Group (ASG)**: Ensures availability and scalability by automatically adjusting the number of instances.
3. **Application Load Balancer (ALB)**: Balances incoming traffic across instances, with health checks to route traffic only to healthy instances.
4. **Instance Refresh**: Configures rolling updates for ASG to minimize downtime during deployments by replacing instances gradually.

### Example Terraform Configuration Snippet (main.tf)

```hcl
module "networking" {
  source             = "./modules/networking_module"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  environment        = "prod"
}

module "launch_template" {
  source                   = "./modules/launch_template"
  launch_template_name     = "web-lt"
  instance_type            = "t2.micro"
  ami_id                   = var.ami_id
  security_group_id        = module.security_group.id
  iam_instance_profile_name = aws_iam_instance_profile.secrets_manager_instance_profile.name
  environment              = "prod"
}
```

### Health Check Configuration

The load balancer only forwards traffic to healthy instances based on a health check configuration that pings the root path (`/`) every 30 seconds.

```hcl
resource "aws_lb_target_group" "web_tg" {
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}
```

## Rolling Updates with Auto Scaling Group

The configuration ensures that updates follow a rolling update pattern, with only 50% of instances being replaced at any given time. This minimizes downtime and maintains availability.

```hcl
instance_refresh {
  strategy = "Rolling"
  preferences {
    min_healthy_percentage = 50
  }
}
```

## Updating Code and Infrastructure

To deploy new changes:
1. Update the code or Terraform configurations.
2. Push to the `main` branch or manually trigger the workflow.
3. Review and approve the deployment plan when prompted.
4. The new infrastructure will be rolled out according to the `instance_refresh` configuration.

## Summary

This setup provides a robust, automated deployment process with GitHub Actions CI/CD and Terraform, featuring:
- Infrastructure-as-code (IaC) with Terraform.
- Secure deployment to AWS using IAM and Secrets Manager.
- Highly available infrastructure with auto-scaling, load balancing, and rolling updates.
