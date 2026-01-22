pipeline {
    agent {
        label 'imuz-docker' 
    }

    environment {
        YC_TOKEN = "${params.YC_TOKEN}" 
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }

    parameters {
        string(name: 'YC_TOKEN', defaultValue: '', description: 'Введите OAuth токен Yandex Cloud')
    }

    stages {
        stage('Build Artifact') {
            steps {
                script {
                    echo '--- Building Artifact (Docker Save) ---'
                    sh 'docker pull 1vmc1/music-app:bot-v1'
                    sh 'docker save 1vmc1/music-app:bot-v1 -o music-bot.tar'
                }
            }
        }

        stage('Infrastructure (Terraform)') {
            steps {
                script {
                    echo '--- Creating Infrastructure in Yandex Cloud ---'
                    // Инициализация
                    sh 'terraform init'
                    
                    // Применение (создание сервера)
                    // Используем токен из параметров
                    sh "terraform apply -var='yc_token=${YC_TOKEN}' -auto-approve"
                    
                    // Сохраняем IP нового сервера в файл, чтобы Ansible его знал
                    sh 'terraform output -raw external_ip > server_ip.txt'
                    
                    // Читаем IP в переменную
                    def server_ip = readFile('server_ip.txt').trim()
                    echo "Created Server IP: ${server_ip}"
                }
            }
        }

        stage('Configuration (Ansible)') {
            steps {
                script {
                    echo '--- Configuring Server with Ansible ---'
                    def server_ip = readFile('server_ip.txt').trim()
                    
                    // Генерируем hosts.ini на лету (подставляем IP)
                    sh """
                        echo "[yandex_servers]" > hosts.ini
                        echo "${server_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa_deploy ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> hosts.ini
                    """
                    
                    // Запускаем Ansible (ставим Докер)
                    // (Предполагается, что setup_yandex.yml уже скачан из Git)
                    sh 'ansible-playbook -i hosts.ini setup_yandex.yml'
                }
            }
        }
        stage('Deploy App') {
            steps {
                script {
                    echo '--- Deploying Bot ---'
                    def server_ip = readFile('server_ip.txt').trim()
                    
                    // Копируем архив
                    sh "scp -i /home/ubuntu/.ssh/id_rsa_deploy -o StrictHostKeyChecking=no music-bot.tar ubuntu@${server_ip}:/tmp/music-bot.tar"
                    
                    // Запускаем (С ТОКЕНОМ!)
                    sh """
                        ssh -i /home/ubuntu/.ssh/id_rsa_deploy -o StrictHostKeyChecking=no ubuntu@${server_ip} '
                            sudo docker load -i /tmp/music-bot.tar
                            sudo docker stop music-bot || true
                            sudo docker rm music-bot || true
                            
                            # ЗАПУСК С ТОКЕНОМ:
                            sudo docker run -d --name music-bot --restart always -e BOT_TOKEN='8570334492:AAG5baJCvzFUlPCvNP2ZQbDqls2UdAxDRB0' 1vmc1/music-app:bot-v1
                        '
                    """
                }
            }
        }
    }
}
