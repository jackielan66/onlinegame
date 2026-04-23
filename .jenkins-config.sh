#!/bin/bash

# Jenkins 环境配置脚本
# 在Jenkins服务器上执行此脚本进行初始化配置

set -e

echo "=========================================="
echo "在线游戏项目 Jenkins 配置脚本"
echo "=========================================="

# 1. 安装必要的Jenkins插件
echo "📦 检查并安装必要的Jenkins插件..."
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_TOKEN="${JENKINS_TOKEN:-your-token}"

REQUIRED_PLUGINS=(
    "gitlab"
    "sonar"
    "nexus-artifact-uploader"
    "docker"
    "docker-commons"
    "email-ext"
    "timestamper"
    "ws-cleanup"
    "nodejs"
)

# 2. 创建全局凭证
echo "🔑 配置Jenkins全局凭证..."
cat << 'EOF'

请在Jenkins UI中添加以下凭证:

1. Docker Registry凭证 (Credentials ID: docker-registry-url)
   - 类型: Username with password
   - Username: your-docker-user
   - Password: your-docker-password

2. SonarQube Token (Credentials ID: sonarqube-token)
   - 类型: Secret text
   - Secret: your-sonar-token

3. Nexus凭证 (Credentials ID: nexus-credentials)
   - 类型: Username with password
   - Username: your-nexus-user
   - Password: your-nexus-password

4. GitLab凭证
   - 类型: SSH Key
   - 或 Personal Access Token

EOF

# 3. 配置全局环境变量
echo "⚙️ 配置全局环境变量..."
cat << 'EOF'

在 Jenkins -> Manage Jenkins -> System -> Global properties 中添加:

DOCKER_REGISTRY=your-registry-url
SONARQUBE_SERVER=http://sonarqube-server:9000
NEXUS_SERVER=http://nexus-server:8081
DEV_SERVER=user@dev-server-ip
STAGING_SERVER=user@staging-server-ip
PROD_SERVER=user@prod-server-ip
SSH_KEY=/var/jenkins_home/.ssh/id_rsa
APP_HOST=your-app-domain

EOF

# 4. 生成SSH密钥（如果需要）
echo "🔐 检查SSH密钥..."
if [ ! -f "/var/jenkins_home/.ssh/id_rsa" ]; then
    echo "生成SSH密钥..."
    ssh-keygen -t rsa -N "" -f /var/jenkins_home/.ssh/id_rsa
    echo "SSH密钥已生成，请确保公钥已添加到目标服务器的authorized_keys"
else
    echo "SSH密钥已存在"
fi

# 5. 安装Node.js
echo "📥 配置Node.js..."
cat << 'EOF'

在 Jenkins -> Manage Jenkins -> Global Tool Configuration 中配置:

NodeJS:
  - Name: Node 22
  - Version: 22.x

EOF

# 6. GitLab Webhook配置
echo "🔗 GitLab Webhook配置..."
cat << 'EOF'

在GitLab项目设置中添加Webhook:

URL: http://your-jenkins-server/project/online-game
秘钥: your-webhook-secret
事件: Push events, Merge request events

EOF

echo ""
echo "=========================================="
echo "✅ Jenkins配置完成！"
echo "=========================================="
echo ""
echo "下一步:"
echo "1. 访问 Jenkins UI 并创建凭证"
echo "2. 创建新的Pipeline Job"
echo "3. 选择 Pipeline script from SCM"
echo "4. 配置GitLab Repository URL"
echo "5. 脚本路径: Jenkinsfile"
echo ""
