pipeline {
    agent any // Запускать пайплайн на любом доступном сервере (раннере)

    environment {
        // Задаем переменные окружения, если они понадобятся внутри шагов
        ANSIBLE_CONFIG = 'ansible/ansible.cfg'
    }

    stages {
        stage('Checkout') {
            steps {
                // Скачивание актуального кода из Git
                checkout scm
            }
        }

        stage('Lint & Validate') {
            steps {
                echo 'Проверяем синтаксис Ansible плейбуков...'
                // Проверяем плейбук на грубые ошибки перед запуском
                sh 'ansible-playbook ansible/deploy.yml --syntax-check'
            }
        }

        stage('Deploy Infrastructure') {
            steps {
                echo 'Запуск автоматического развертывания через Ansible...'
                // Запускаем наш готовый плейбук на сервере целевой инфраструктуры
                sh 'ansible-playbook ansible/deploy.yml'
            }
        }
    }

    post {
        success {
            echo 'Ура! Пайплайн успешно завершен, проект развернут.'
        }
        failure {
            echo 'Что-то пошло не так. Проверь логи шагов выше.'
        }
    }
}
