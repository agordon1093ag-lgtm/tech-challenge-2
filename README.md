# Tech Challenge 2: CI/CD Pipeline with Docker, EKS, and Jenkins

## Project Overview
This project demonstrates a complete CI/CD pipeline for containerized applications using:
- **Docker** for containerization
- **Terraform** for Infrastructure as Code (IaC)
- **Amazon EKS** for Kubernetes orchestration
- **Jenkins** for CI/CD automation
- **Helm** for Kubernetes package management

The application is a simple "Hello, World!" Flask web application deployed to an auto-scaling EKS cluster.

## Architecture Diagram
┌─────────┐ ┌──────────┐ ┌─────────┐ ┌─────────┐ ┌──────────┐
│ GitHub │────▶│ Jenkins │────▶│ ECR │────▶│ Helm │────▶│ EKS │
│ Repo │ │ Pipeline │ │ Registry│ │ Chart │ │ Cluster │
└─────────┘ └──────────┘ └─────────┘ └─────────┘ └──────────┘
│
▼
┌──────────┐
│ Load │
│Balancer │
└──────────┘


## Prerequisites

### Local Machine Requirements
- **macOS** (with Homebrew)
- **VS Code** (or any IDE)
- **AWS CLI** (configured with access keys)
- **Terraform** 
- **kubectl** 
- **Helm** 
- **Docker Desktop** 
- **Git**

### AWS Account Requirements
- IAM user with programmatic access
- Permissions for: EC2, EKS, ECR, IAM, VPC
- Sufficient service quotas for EKS

## Environment Setup Instructions

### 1. Install Required Tools (macOS)


# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install terraform awscli kubernetes-cli helm git
brew install --cask docker

# Verify installations
terraform --version
aws --version
kubectl version --client
helm version
docker --version

Configure AWS CLI
git clone https://github.com/agordon1093ag-lgtm/tech-challenge-2.git
cd tech-challenge-2

Application Structure
tech-challenge-2/
├── app/                       # Flask application
│   ├── app.py                 # Main application code
│   ├── Dockerfile             # Docker container definition
│   └── requirements.txt       # Python dependencies
├── terraform/                 # Infrastructure as Code
│   ├── provider.tf            # AWS provider configuration
│   ├── vpc.tf                 # VPC and networking
│   ├── eks-cluster.tf         # EKS cluster definition
│   ├── jenkins-ec2.tf         # Jenkins server EC2 instance
│   └── outputs.tf             # Terraform outputs
├── hello-world-chart/         # Helm chart
│   ├── Chart.yaml             # Chart metadata
│   ├── values.yaml            # Configuration values
│   └── templates/             # Kubernetes manifests
│       ├── deployment.yaml    # Deployment definition
│       ├── service.yaml       # Service definition
│       └── hpa.yaml           # Horizontal Pod Autoscaler
├── Jenkinsfile                # CI/CD pipeline definition
└── README.md                  # This documentation

Terraform Code Explanation

provider.tf
# Configures AWS as the cloud provider
# Sets region to us-east-2 (Ohio)
# Defines required provider versions
Purpose: Initialized Terraform with AWS provider and sets default tags for all resources.

vpc.tf
# Creates a VPC with CIDR 10.0.0.0/16
# Provisions 2 public subnets across availability zones
# Sets up Internet Gateway and route tables
# Tags subnets for EKS integration
Purpose: Provides network infrastructure for EKS cluster and Jenkins EC2 instance. 

eks-cluster.tf
# IAM roles for EKS cluster and worker nodes
# EKS control plane (version 1.29)
# Managed node group with t3.small instances
# Auto-scaling: min=1, max=4, desired=1
Purpose: Creates the Kubernetes cluster with worker nodes that can scale from 1 to 4 instances.

jenkins-ec2.tf
# Security group for Jenkins (ports 22, 8080)
# IAM role with ECR, EKS, and EC2 permissions
# t2.micro EC2 instance with Ubuntu 22.04
# User-data script to install Jenkins, Docker, kubectl, helm
Purpose: Provisions a Jenkins server with all necessary tools pre-installed.

Jenkins Pipeline Explanation
The Jenkinsfile defines a declarative pipeline with the following stages:

Stage 1: Checkout
stage('Checkout') {
    steps {
        checkout scm
    }
}
Purpose: Pulls the latest source code from GitHub repository.

Stage 2: Build Docker Image
stage('Build Docker Image') {
    steps {
        script {
            dockerImage = docker.build("${ECR_REPO}:${IMAGE_TAG}", "./app")
        }
    }
}
Purpose: Builds a Docker image from the Flask application code.

Stage 3: Push to ECR
stage('Push to ECR') {
    steps {
        script {
            sh '''
                aws ecr get-login-password --region ${AWS_REGION} | \
                docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                docker push ${ECR_REPO}:${IMAGE_TAG}
            '''
        }
    }
}
Purpose: Authenticates with Amazon ECR and pushes the Docker image to the repository.

Stage 4: Deploy to EKS
stage('Deploy to EKS') {
    steps {
        script {
            sh '''
                aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
                helm upgrade --install hello-world-app ./hello-world-chart \
                    --set image.repository=${ECR_REPO} \
                    --set image.tag=${IMAGE_TAG} \
                    --namespace default
            '''
        }
    }
}
Purpose: Updates kubeconfig, then deploys the application to EKS using Helm with the new image tag.

Post Actions
post {
    success {
        echo 'Pipeline executed successfully!'
        script {
            sh 'kubectl get svc hello-world-app-flask-app'
        }
    }
    failure {
        echo 'Pipeline failed!'
    }
}
Purpose: Displays the service URL on success or failure message on error.

Deployment Instructions

Step 1: Provision EKS Cluster
cd terraform
terraform init
terraform plan
terraform apply  # Type 'yes' when prompted

Step 2: Configure kubectl
aws eks update-kubeconfig --region us-east-2 --name tech-challenge-cluster
kubectl get nodes  # Verify nodes are ready

Step 3: Create ECR Repository
aws ecr create-repository --repository-name hello-world-app --region us-east-2

Step 4: Access Jenkins
1. Get Jenkins public IP:
cd terraform
terraform output jenkins_public_ip
2. Open browser: http://<jenkins-ip>:8080
3. Initial password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword

Step 5: Configure Jenkins Credentials
Add AWS credentials as secret text:
aws-access-key-id
aws-secret-access-key

Step 6: Create Jenkins Pipeline
1. New Item → Pipeline → Name: hello-world-app-pipeline
2. Pipeline → Pipeline script from SCM
3. SCM: Git → Repository URL: https://github.com/agordon1093ag-lgtm/tech-challenge-2.git
4. Script Path: Jenkinsfile
5. Save and Build Now

Auto-scaling Configuration
The Horizontal Pod Autoscaler (HPA) is configured to:
Min replicas: 1
Max replicas: 3
CPU threshold: 50%
Memory threshold: 50%

# From hello-world-chart/templates/hpa.yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 50

Verification 
Check Deployment Status

# Get pods
kubectl get pods

# Get HPA status
kubectl get hpa

# Get service URL
kubectl get svc hello-world-app-flask-app        

Access Application
Visit the EXTERNAL-IP from the service output in your browser: http://ad47927d068d1419db714d83aba92352-84571044.us-east-2.elb.amazonaws.com
You should see: "Hello, World!"

Clean Up
To avoid ongoing AWS charges, destroy all resources:
# Delete Jenkins pipeline and EC2 instance
cd terraform
terraform destroy

# Delete ECR repository
aws ecr delete-repository --repository-name hello-world-app --region us-east-2 --force

Troubleshooting
Common Issues and Solutions
Issue	                            Solution
Jenkins can't connect to EKS	    Add IAM role to aws-auth ConfigMap
Docker permission denied	        Add Jenkins user to docker group
Helm deployment fails	            Update kubectl version to match cluster
GitHub webhook not triggering	    Enable CSRF proxy compatibility in Jenkins

Technologies Used
AWS EKS - Kubernetes cluster
Terraform - Infrastructure provisioning
Docker - Containerization
Jenkins - CI/CD automation
Helm - Kubernetes package management
Flask - Python web framework
GitHub - Source code management

Author
Aundrea Gordon