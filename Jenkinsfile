pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID = '740838937919'
        AWS_REGION = 'us-east-2'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/hello-world-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        CLUSTER_NAME = 'tech-challenge-cluster'
        
        // REMOVED: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
        // The AWS CLI will automatically use the IAM role attached to the EC2 instance
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${ECR_REPO}:${IMAGE_TAG}", "./app")
                }
            }
        }
        
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
    }
    
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
}