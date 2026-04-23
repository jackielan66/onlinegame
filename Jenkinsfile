pipeline {
    agent any

    // 环境变量配置
    environment {
        DOCKER_REGISTRY = credentials('docker-registry-url')
        // SONAR_TOKEN = credentials('sonarqube-token')
        // NEXUS_CREDENTIALS = credentials('nexus-credentials')
        NODE_ENV = 'production'
        APP_NAME = 'online-game'
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/${APP_NAME}"
    }

    // 构建触发器
    triggers {
        // 监听GitHub Webhook
        githubPush()
    }

    // 构建参数
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'staging', 'production'],
            description: '选择部署环境'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: '跳过测试'
        )
    }

    options {
        // 保留构建历史
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '5'))
        // 超时设置
        timeout(time: 1, unit: 'HOURS')
        // 构建时间戳
        timestamps()
    }

    stages {
        stage('🔍 代码检出') {
            steps {
                script {
                    echo "从GitLab检出代码..."
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '${GIT_BRANCH}']],
                        userRemoteConfigs: [[url: '${GIT_URL}']]
                    ])
                }
            }
        }

        stage('📦 依赖安装') {
            steps {
                script {
                    echo "安装项目依赖..."
                    sh '''
                        npm install --no-save
                        npm audit fix --audit-level=moderate || true
                    '''
                }
            }
        }

        stage('🧹 代码格式检查') {
            steps {
                script {
                    echo "运行ESLint检查..."
                    sh '''
                        npm run lint || true
                    '''
                }
            }
        }

        stage('🔐 SonarQube 代码质量分析') {
            steps {
                script {
                    echo "上传代码到SonarQube进行质量分析..."
                    sh '''
                        npm install -g sonar-scanner
                        sonar-scanner \
                          -Dsonar.projectKey=online-game \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=http://sonarqube-server:9000 \
                          -Dsonar.login=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('🛡️ Sonatype 安全检查') {
            steps {
                script {
                    echo "检查开源组件安全性..."
                    sh '''
                        # 使用 npm audit 进行安全检查
                        npm audit --json > audit-report.json || true
                        
                        # 可选：集成 Sonatype Nexus IQ 扫描
                        # curl -v -X POST --data-binary @audit-report.json \
                        #   -H "Content-Type: application/json" \
                        #   -u "${NEXUS_CREDENTIALS}" \
                        #   http://nexus-server/service/rest/v1/security/scan
                    '''
                }
            }
        }

        stage('🏗️ 构建应用') {
            steps {
                script {
                    echo "构建Next.js应用..."
                    sh '''
                        npm run build
                    '''
                }
            }
        }

        stage('🐳 构建Docker镜像') {
            steps {
                script {
                    echo "构建Docker镜像: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    sh '''
                        docker build \
                          -t ${DOCKER_IMAGE}:${BUILD_NUMBER} \
                          -t ${DOCKER_IMAGE}:latest \
                          .
                    '''
                }
            }
        }

        stage('📤 推送到制品库') {
            steps {
                script {
                    echo "上传构建产物到Nexus..."
                    sh '''
                        # 登录Docker Registry
                        echo "${NEXUS_CREDENTIALS_PSW}" | docker login \
                          -u "${NEXUS_CREDENTIALS_USR}" \
                          --password-stdin ${DOCKER_REGISTRY}
                        
                        # 推送镜像
                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:latest
                        
                        # 上传构建产物（可选）
                        # tar -czf online-game-${BUILD_NUMBER}.tar.gz .next/
                        # curl -v --user "${NEXUS_CREDENTIALS}" --upload-file \
                        #   online-game-${BUILD_NUMBER}.tar.gz \
                        #   http://nexus-server/repository/releases/
                    '''
                }
            }
        }

        stage('🚀 部署应用') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def deployEnv = params.DEPLOY_ENV ?: 'dev'
                    echo "部署到${deployEnv}环境..."
                    sh '''
                        # 根据环境部署
                        case ${DEPLOY_ENV} in
                            dev)
                                echo "部署到开发环境..."
                                ssh -i ${SSH_KEY} ${DEV_SERVER} "cd /apps/online-game && docker-compose pull && docker-compose up -d"
                                ;;
                            staging)
                                echo "部署到测试环境..."
                                ssh -i ${SSH_KEY} ${STAGING_SERVER} "cd /apps/online-game && docker-compose pull && docker-compose up -d"
                                ;;
                            production)
                                echo "部署到生产环境..."
                                ssh -i ${SSH_KEY} ${PROD_SERVER} "cd /apps/online-game && docker-compose pull && docker-compose up -d"
                                ;;
                        esac
                    '''
                }
            }
        }

        stage('✅ 部署验证') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "验证部署..."
                    sh '''
                        # 等待应用启动
                        sleep 5
                        
                        # 检查应用健康状态
                        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://${APP_HOST}:3000/health)
                        if [ $RESPONSE -eq 200 ]; then
                            echo "✅ 应用部署成功"
                        else
                            echo "❌ 应用部署失败"
                            exit 1
                        fi
                    '''
                }
            }
        }
    }

    post {
        always {
            // 清理工作区
            cleanWs()
        }
        success {
            script {
                echo "✅ 构建成功！"
                // 发送通知（邮件、Slack等）
                // emailext(
                //     to: '${DEFAULT_RECIPIENTS}',
                //     subject: "构建成功: ${JOB_NAME} #${BUILD_NUMBER}",
                //     body: "构建信息：${BUILD_URL}"
                // )
            }
        }
        failure {
            script {
                echo "❌ 构建失败！"
                // 发送失败通知
            }
        }
    }
}
