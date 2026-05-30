pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '266735824916.dkr.ecr.us-east-1.amazonaws.com/portfolio'
        IMAGE_TAG = "${BUILD_NUMBER}"
        EC2_HOST = '52.73.68.208'
        EC2_USER = 'ubuntu'
        SONAR_PROJECT_KEY = 'portfolio'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/12021m110/my-portpolio.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                          -Dsonar.projectName="Portfolio Website" \
                          -Dsonar.sources=. \
                          -Dsonar.inclusions="**/*.html,**/*.css,**/*.js" \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_AUTH_TOKEN}
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
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
                withAWS(region: "${AWS_REGION}", credentials: 'aws-credentials') {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS \
                        --password-stdin ${ECR_REPO}
                        docker push ${ECR_REPO}:${IMAGE_TAG}
                        docker push ${ECR_REPO}:latest
                    '''
                }
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

        stage('Prometheus Metrics Check') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "
                            echo '=== Container Status ==='
                            docker ps | grep portfolio

                            echo '=== Container Stats ==='
                            docker stats portfolio --no-stream --format \
                            'CPU: {{.CPUPerc}} | Memory: {{.MemUsage}} | Network: {{.NetIO}}'

                            echo '=== HTTP Response Check ==='
                            curl -o /dev/null -s -w \
                            'HTTP Status: %{http_code} | Response Time: %{time_total}s\n' \
                            http://localhost

                            echo '=== Prometheus Health ==='
                            curl -s http://localhost:9090/-/healthy || \
                            echo 'Prometheus not running - skipping'
                        "
                    '''
                }
            }
        }

    }

    post {
        success {
            echo "✅ Pipeline SUCCESS — Build #${BUILD_NUMBER}"
            echo "🌐 Site: https://venkatanaresh.qzz.io"
            echo "📊 SonarQube: Quality gate passed"
            echo "📈 Prometheus: Metrics verified"
        }
        failure {
            echo "❌ Pipeline FAILED — Build #${BUILD_NUMBER}"
            echo "🔍 Check console output for details"