pipeline {
    agent any // Предполагается, что на Jenkins-ноде установлен Docker и права настроены

    environment {
        REGISTRY_URL = "registry:5000"
        REGISTRY_USER = "registry_user"
        REGISTRY_PASSWORD = "registry_password"
    }

    stages {
        // 1. Запуск Bash-скрипта
        stage('Run Bash Script') {
            steps {
                sh 'chmod +x ./bash/script.sh'
                sh './bash/script.sh "https://ya.ru" "https://avidreaders.ru/download/voyna-i-mir-tom-1.html?f=txt"'
            }
        }

        // 2. Сборка образа Nginx и Push в Registry
        stage('Build & Push Nginx') {
            steps {
                sh """
                echo "${REGISTRY_PASSWORD}" | docker login ${REGISTRY_URL} -u ${REGISTRY_USER} --password-stdin
                docker build --build-arg BASIC_AUTH_USER=my_drupal_admin -t ${REGISTRY_URL}/nginx-proxy:latest -f ./nginx/Dockerfile .
                docker push ${REGISTRY_URL}/nginx-proxy:latest
                """
            }
        }

        // 3. Деплой через docker-compose
        stage('Deploy') {
                steps {
                    sh 'docker compose up -d --build db_server drupal_site nginx_proxy'
                    // Подключаем сам Jenkins к сети нашего приложения (если он еще не там)
                    sh 'docker network connect devopsintern_devops_net jenkins_local || true'
                }
            }

            // 4. Тестирование (Параллельный запуск стадий в Jenkins)
            stage('Parallel Tests') {
                parallel {
                    stage('Test Upload') {
                        steps {
                            sh """
                            mkdir -p ./html/upload
                            echo "Jenkins test" > ./html/upload/jenkins_test.txt
                            # Копируем файл напрямую внутрь контейнера Nginx, обходя проблемы монтирования
                            docker cp ./html/upload/jenkins_test.txt nginx_container:/opt/html/upload/jenkins_test.txt
                            HOST_IP=\$(getent hosts nginx_container | awk '{print \$1}')
                            echo "Testing via Nginx Container IP: \$HOST_IP"
                            curl -k --resolve site.devops:443:\$HOST_IP -f https://site.devops/upload/jenkins_test.txt
                            """
                        }
                    }
                    stage('Test Drupal API') {
                        steps {
                            sh """
                            HOST_IP=\$(getent hosts nginx_container | awk '{print \$1}')
                            echo "Testing via Nginx Container IP: \$HOST_IP"
                            curl -k --resolve site.devops:443:\$HOST_IP -u my_drupal_admin:my_super_password -s -o /dev/null -w "%{http_code}" https://site.devops/dp/core/install.php
                            """
                        }
                    }
                }
            }
    }
}
