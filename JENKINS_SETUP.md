# Jenkins 部署指南

## 📋 目录
1. [系统要求](#系统要求)
2. [Jenkins 安装](#jenkins-安装)
3. [插件配置](#插件配置)
4. [凭证设置](#凭证设置)
5. [Job 创建](#job-创建)
6. [环境配置](#环境配置)
7. [常见问题](#常见问题)

---

## 系统要求

- **Jenkins**: 2.414+
- **Java**: JDK 11+
- **Docker**: 20.10+
- **Node.js**: 22+
- **Git**: 2.30+

### 外部服务
- **GitLab**: 用于代码管理
- **SonarQube**: 用于代码质量分析（可选）
- **Nexus**: 用于制品存储（可选）
- **服务器**: 用于应用部署

---

## Jenkins 安装

### 1. 使用 Docker 快速启动

```bash
docker run -d --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e JENKINS_OPTS="--prefix=/jenkins" \
  jenkins/jenkins:lts
```

### 2. 本地安装（macOS）

```bash
# 使用Homebrew
brew install jenkins-lts
brew services start jenkins-lts

# Jenkins将在 http://localhost:8080 启动
```

### 3. Linux 安装

```bash
# Ubuntu/Debian
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins

# 启动服务
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

---

## 插件配置

### 安装必要插件

登录 Jenkins 后，进入 **Manage Jenkins** > **Manage Plugins**，搜索并安装：

| 插件名称 | 版本 | 用途 |
|---------|------|------|
| GitLab | 最新 | GitLab集成 |
| Pipeline | 最新 | Pipeline支持 |
| SonarQube Scanner | 最新 | SonarQube代码扫描 |
| Docker Pipeline | 最新 | Docker支持 |
| Nexus Artifact Uploader | 最新 | Nexus集成 |
| Email Extension | 最新 | 邮件通知 |
| Timestamper | 最新 | 时间戳 |
| Workspace Cleanup | 最新 | 工作区清理 |
| NodeJS | 最新 | Node.js支持 |
| AnsiColor | 最新 | 彩色输出 |

---

## 凭证设置

### 1. GitLab 凭证

**方式A: SSH Key**
```
Manage Jenkins > Manage Credentials > (global)
点击 Add Credentials:
- Type: SSH Username with private key
- Username: git
- Private Key: 粘贴你的SSH私钥
- ID: gitlab-ssh
```

**方式B: Personal Access Token**
```
- Type: GitLab API Token
- API Token: 从GitLab生成的token
- ID: gitlab-token
```

### 2. Docker Registry 凭证

```
- Type: Username with password
- Username: your-docker-user
- Password: your-docker-password（或access token）
- ID: docker-registry-url
```

### 3. SonarQube Token

```
- Type: Secret text
- Secret: 从SonarQube生成的token
- ID: sonarqube-token
```

### 4. Nexus 凭证

```
- Type: Username with password
- Username: your-nexus-user
- Password: your-nexus-password
- ID: nexus-credentials
```

### 5. 服务器SSH凭证

```
- Type: SSH Username with private key
- Username: deploy（或你的用户名）
- Private Key: 服务器SSH密钥
- ID: deploy-ssh
```

---

## Job 创建

### 创建 Pipeline Job

1. 点击 **New Item**
2. 输入任务名: `online-game`
3. 选择 **Pipeline**
4. 点击 **OK**

### 配置Pipeline

**General 选项卡:**
```
- 描述: 出海在线小游戏 CI/CD Pipeline
- 勾选: Discard old builds
  - Strategy: Log Rotation
  - Days to keep builds: 30
  - Max # of builds to keep: 10
```

**Pipeline 选项卡:**
```
Definition: Pipeline script from SCM
SCM: Git
  - Repository URL: your-gitlab-url/online-game.git
  - Credentials: gitlab-ssh
  - Branch: */main
  - Script Path: Jenkinsfile
```

**Build Triggers 选项卡:**
```
- 勾选: Provide GitLab-specific refspec
- 勾选: Push events
- 勾选: Merge request events
```

---

## 环境配置

### 1. 全局环境变量

**Manage Jenkins > System > Global properties**

```
✓ Environment variables:

DOCKER_REGISTRY=docker.io/your-account
SONARQUBE_SERVER=http://sonarqube-server:9000
NEXUS_SERVER=http://nexus-server:8081
NEXUS_REPOSITORY=releases
DEV_SERVER=deploy@dev.example.com
STAGING_SERVER=deploy@staging.example.com
PROD_SERVER=deploy@prod.example.com
SSH_KEY=/var/jenkins_home/.ssh/id_rsa
APP_HOST=app.example.com
```

### 2. Node.js 配置

**Manage Jenkins > Global Tool Configuration > NodeJS**

```
- Name: Node 22
- Version: 22.x
- Install automatically: ✓
```

### 3. SonarQube 服务器配置

**Manage Jenkins > Configure System > SonarQube servers**

```
- Name: SonarQube
- Server URL: http://sonarqube-server:9000
- Server authentication token: 选择凭证
```

---

## 环境部署脚本

### 开发环境配置

在目标服务器上：

```bash
# 1. 创建应用目录
sudo mkdir -p /apps/online-game
sudo chown $USER:$USER /apps/online-game

# 2. 创建 docker-compose.yml
cd /apps/online-game
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    image: ${DOCKER_REGISTRY}/online-game:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

# 3. 创建启动脚本
cat > start.sh << 'EOF'
#!/bin/bash
docker-compose pull
docker-compose up -d
EOF

chmod +x start.sh
```

### 生产环境配置

生产环境建议使用：
- 反向代理（Nginx）
- SSL证书（Let's Encrypt）
- 负载均衡
- 监控告警

```bash
# Nginx配置示例
server {
    listen 443 ssl http2;
    server_name app.example.com;

    ssl_certificate /etc/ssl/cert.pem;
    ssl_certificate_key /etc/ssl/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 常见问题

### Q1: Jenkins 无法连接到 GitLab

**解决方案:**
```bash
# 1. 检查SSH连接
ssh -vT git@gitlab.example.com

# 2. 添加GitLab主机到 known_hosts
ssh-keyscan -H gitlab.example.com >> ~/.ssh/known_hosts

# 3. 确保私钥权限正确
chmod 600 ~/.ssh/id_rsa
```

### Q2: Docker 构建失败

**检查:**
```bash
# 确保Jenkins用户可以访问Docker
sudo usermod -aG docker jenkins
newgrp docker

# 重启Jenkins
sudo systemctl restart jenkins
```

### Q3: SonarQube 扫描超时

**调整:**
```groovy
// 在Jenkinsfile中增加超时时间
timeout(time: 30, unit: 'MINUTES') {
    // sonarqube扫描代码
}
```

### Q4: 部署到服务器失败

**检查:**
```bash
# 1. SSH连接测试
ssh -i /path/to/key user@server

# 2. 确保目录权限
ls -la /apps/online-game

# 3. Docker-compose权限
chmod +x /apps/online-game/start.sh
```

---

## 查看构建日志

### 方式1: Jenkins UI
```
点击Job > 点击Build # > Console Output
```

### 方式2: SSH查看
```bash
# 在Jenkins服务器上
tail -f /var/jenkins_home/jobs/online-game/builds/lastStableBuild/log
```

### 方式3: Docker日志
```bash
# 查看应用日志
docker logs -f online-game

# 查看构建日志
docker logs -f jenkins
```

---

## 监控和告警

### 邮件通知配置

**Manage Jenkins > Configure System > Email Notification**

```
- SMTP server: smtp.gmail.com
- SMTP Port: 587
- Use SMTP Authentication: ✓
- Username: your-email@gmail.com
- Password: app-password
- TLS: ✓
```

### Slack 通知（可选）

安装 Slack Notification 插件，配置webhook即可。

---

## 备份和恢复

### 备份Jenkins配置

```bash
# 备份整个Jenkins_home目录
docker exec jenkins tar czf - /var/jenkins_home > jenkins_backup_$(date +%Y%m%d).tar.gz

# 或者只备份jobs
docker cp jenkins:/var/jenkins_home/jobs ./jenkins_jobs_backup
```

### 恢复配置

```bash
# 恢复Jenkins_home
docker exec jenkins tar xzf jenkins_backup.tar.gz -C /

# 重启Jenkins
docker restart jenkins
```

---

## 参考资源

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [GitLab Jenkins Integration](https://docs.gitlab.com/ee/integration/jenkins.html)
- [SonarQube Jenkins Plugin](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-jenkins/)

---

## 支持

有任何问题，请联系DevOps团队或查看Jenkins官方文档。
