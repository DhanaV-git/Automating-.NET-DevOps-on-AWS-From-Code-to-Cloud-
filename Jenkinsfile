pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = 'YOUR_AWS_ACCOUNT_ID'
        AWS_REGION = 'us-east-1'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vibenova-app"
        KUBE_CONFIG = credentials('eks-kubeconfig')
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/YOUR_GITHUB_REPO.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        sh 'dotnet sonarscanner begin /k:"vibenova" /d:sonar.host.url="http://sonarqube:9000" /d:sonar.login=$SONAR_TOKEN'
                        sh 'dotnet build'
                        sh 'dotnet sonarscanner end /d:sonar.login=$SONAR_TOKEN'
                    }
                }
            }
        }

        stage('Build & Unit Tests') {
            steps {
                sh 'dotnet test'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t vibenova-app:latest .'
            }
        }

        stage('Push Image to AWS ECR') {
            steps {
                script {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                    docker tag vibenova-app:latest ${ECR_REPO}:latest
                    docker push ${ECR_REPO}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes (FluxCD)') {
            steps {
                sh 'kubectl apply -f k8s/deployment.yaml --kubeconfig=$KUBE_CONFIG'
            }
        }
    }
}
