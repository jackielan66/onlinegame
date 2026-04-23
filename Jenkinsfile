pipeline {
    agent any

    // 定义变量（替换这些值！）
    environment {
        SERVER_IP = 'your-server-ip'
        SERVER_USER = 'root'
        APP_PATH = '/app/online-game'
    }

    stages {
        // 第1步：拉取代码
        stage('1️⃣ 拉取代码') {
            steps {
                echo "从GitHub拉取代码..."
                checkout scm
            }
        }

        // 第2步：安装依赖
        stage('2️⃣ 安装依赖') {
            steps {
                echo "npm install..."
                sh 'npm install'
            }
        }

        // 第3步：构建应用
        stage('3️⃣ 构建Next.js') {
            steps {
                echo "npm run build..."
                sh 'npm run build'
            }
        }

        // 第4步：构建Docker镜像
        stage('4️⃣ 构建Docker镜像') {
            steps {
                echo "docker build..."
                sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .'
                sh 'docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest'
            }
        }

        // 第5步：推送镜像
        stage('5️⃣ 推送到Docker Hub') {
            steps {
                echo "docker push..."
                sh '''
                    echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                    docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }

        // 第6步：部署到服务器
        stage('6️⃣ 部署到服务器') {
            steps {
                echo "部署应用..."
                sh '''
                    ssh -i ~/.ssh/id_rsa ${SERVER_USER}@${SERVER_IP} << 'SCRIPT'
cd /app/online-game
docker pull ${DOCKER_IMAGE}:latest
docker-compose down || true
docker-compose up -d
SCRIPT
                '''
            }
        }
    }

    post {
        success {
            echo "✅ 部署成功！"
        }
        failure {
            echo "❌ 部署失败，请检查日志"
        }
    }
}
