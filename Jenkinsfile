pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '266735824916.dkr.ecr.us-east-1.amazonaws.com/portfolio'
        IMAGE_TAG = "${BUILD_NUMBER}"
        EC2_HOST = '52.73.68.208'
        EC2_USER = 'ubuntu'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/12021m110/my-portpolio.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t portfolio:${IMAGE_TAG} .
                    docker tag portfolio:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                    docker tag portfolio:${IMAGE_TAG} ${ECR_REPO}:latest
                '''
            }
        }

        stage('Push to ECR') {
            steps {
               sh '''
                    aws ecr get-login-password --region us-east-1 > /tmp/ecr_token.txt
                    docker login --username AWS --password-stdin 266735824916.dkr.ecr.us-east-1.amazonaws.com < /tmp/ecr_token.txt
                    rm -f /tmp/ecr_token.txt
                    docker push ${ECR_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REPO}:latest
                '''
           }
       }

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REPO}
                            docker pull ${ECR_REPO}:latest
                            docker stop portfolio || true
                            docker rm portfolio || true
                            docker run -d \
                                --name portfolio \
                                -p 80:80 \
                                --restart always \
                                ${ECR_REPO}:latest
                        "
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 10
                    curl -f http://${EC2_HOST} || exit 1
                    echo "Deployment successful!"
                '''
            }
        }
    }

    post {
        success {
            echo "Portfolio deployed successfully! Build #${BUILD_NUMBER}"
        }
        failure {
            echo "Deployment failed! Check logs."
        }
    }
}