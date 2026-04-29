pipeline {
    agent { label 'ssh-agent' }

    tools {
        nodejs 'node-20'
    }

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['stg', 'prod'], description: 'Environnement de déploiement')
        string(name: 'REGISTRY', defaultValue: 'registry.spokayhub.top', description: 'URL du registre Docker')
        string(name: 'GIT_URL', defaultValue: 'https://github.com/BX37/EFREI-PipelinesFinal-Backend.git', description: 'URL du dépôt Git')
        string(name: 'GIT_BRANCH', defaultValue: 'master', description: 'Branche Git à utiliser')
        string(name: 'TARGET_PLATFORM', defaultValue: 'linux/amd64', description: 'Plateforme cible')
        string(name: 'VM_HOST', defaultValue: '172.178.120.232', description: 'VM cible')
        string(name: 'VM_USER', defaultValue: 'azureuser', description: 'Utilisateur VM')
    }

    environment {
        IMAGE_NAME     = 'efrei-pipelinesfinal-backend'
        IMAGE          = "${params.REGISTRY}/${IMAGE_NAME}"
        COMPOSE_FILE   = "docker-compose.${params.DEPLOY_ENV}.yml"
        CONTAINER_NAME = "${IMAGE_NAME}-${params.DEPLOY_ENV}"
    }

    stages {

        stage('Test') {
            steps {
                sh '''
                    docker network inspect test-network >/dev/null 2>&1 || docker network create test-network

                    docker rm -f mysql-test || true

                    docker run -d --name mysql-test \
                      --network test-network \
                      -e MYSQL_ROOT_PASSWORD=root \
                      -e MYSQL_DATABASE=incident_db \
                      mysql:8.4.8

                    echo "Attente que MySQL soit prêt..."
                    for i in $(seq 1 30); do
                        if docker exec mysql-test mysqladmin ping -h localhost -proot --silent 2>/dev/null; then
                            echo "MySQL prêt !"
                            break
                        fi
                        sleep 3
                    done

                    docker build --target test -t backend-test .

                    docker run --rm \
                      --network test-network \
                      -e DB_HOST=mysql-test \
                      -e DB_PORT=3306 \
                      -e DB_USER=root \
                      -e DB_PASSWORD=root \
                      -e DB_NAME=incident_db \
                      backend-test

                    docker rm -f mysql-test || true
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('sonar-spokay') {
                        sh "${scannerHome}/bin/sonar-scanner"
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build') {
            steps {
                sh """
                    docker build \
                        --platform ${params.TARGET_PLATFORM} \
                        -t $IMAGE:$IMAGE_TAG \
                        -t $IMAGE:latest \
                        .
                """
            }
        }

        stage('Push') {
            steps {
                withDockerRegistry(credentialsId: 'registry-credentials', url: "https://${params.REGISTRY}/") {
                    sh '''
                        docker push $IMAGE:$IMAGE_TAG
                        docker push $IMAGE:latest
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sshagent(credentials: ["backend-${params.DEPLOY_ENV}-ssh-credentials"]) {
                    echo "Déploiement en cours..."
                }
            }
        }
    }

    post {
        success {
            echo "Déploiement réussi"
        }
        failure {
            echo "Déploiement échoué"
        }
    }
}