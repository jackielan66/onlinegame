# Jenkins 部署指南（新手版）

**这是一个超级简单的指南，只有6个步骤！**

---

## 🎯 目标

当你 `git push` 代码到 GitHub 时，Jenkins 自动：
1. 拉取代码
2. 构建 Next.js 应用
3. 打包成 Docker 镜像
4. 上传到 Docker Hub
5. 部署到你的服务器

---

## 📋 前置准备

### 需要的账户（都是免费的）
- ✅ GitHub 账户（你已有）
- ✅ Docker Hub 账户（免费注册）
- ✅ 一台服务器（阿里云、腾讯云或自己的服务器）

### 需要安装的东西
- Jenkins（服务器或本地）
- Docker（服务器上）

---

## ⚡ 5分钟快速开始

### 第1步：注册Docker Hub账户
访问 https://hub.docker.com 注册（免费）

### 第2步：在Jenkins中添加凭证

进入 **Jenkins首页** → **Manage Jenkins** → **Manage Credentials**

点击 **(global)** → **Add Credentials**，添加：

```
Type: Username with password
Username: 你的Docker Hub用户名
Password: Docker Hub密码（不是GitHub密码！）
ID: docker-username
```

再添加第二个：

```
Type: Username with password
Username: 你的Docker Hub用户名
Password: Docker Hub密码
ID: docker-password
```

### 第3步：修改 Jenkinsfile 中的这三个地方

打开项目根目录的 `Jenkinsfile`，找到这几行：

```groovy
DOCKER_USERNAME = credentials('docker-username')
DOCKER_PASSWORD = credentials('docker-password')
DOCKER_IMAGE = 'your-docker-username/online-game'  // ← 改成你的！
SERVER_IP = 'your-server-ip'                       // ← 改成你的！
SERVER_USER = 'root'
```

**改成：**
```groovy
DOCKER_IMAGE = 'yourname/online-game'  // 比如：'john123/online-game'
SERVER_IP = '1.2.3.4'                  // 你的服务器公网IP
```

### 第4步：创建Jenkins Pipeline Job

在 Jenkins 首页点击 **New Item**：

```
Item name: online-game
Type: 选择 Pipeline
点击 OK
```

在配置页面：

**Definition** 选项卡中选择：
```
Pipeline script from SCM
SCM: Git
Repository URL: 你的GitHub仓库地址
  比如：https://github.com/yourname/online-game.git
Credentials: 选择你的GitHub凭证
Branch: */main
Script Path: Jenkinsfile
```

点击 **Save**

### 第5步：在服务器上配置

SSH 连接到你的服务器：

```bash
# 1. 创建应用目录
mkdir -p /app/online-game
cd /app/online-game

# 2. 创建 docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    image: yourname/online-game:latest
    container_name: online-game
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: always
EOF

# 3. 第一次手动启动（建立Docker目录）
docker pull yourname/online-game:latest || echo "镜像还不存在，下次自动拉取"
```

### 第6步：测试一下

回到 Jenkins，点击你创建的 **online-game** Job

点击 **Build Now**

等待几分钟，看是否成功（会看到绿色的✅）

---

## 🔄 工作流程

从现在开始，你只需要这样做：

```bash
# 1. 本地修改代码
vim app/page.tsx

# 2. 提交并推送
git add .
git commit -m "修复bug"
git push origin main

# 3. Jenkins 自动开始构建！
# 在 Jenkins 首页就能看到进度
# 3-5分钟后，应用自动部署到服务器
# 访问 http://你的服务器IP:3000 就能看到新版本

# 完毕！你不需要做任何其他事情
```

---

## 📺 查看构建日志

在 Jenkins 首页：

1. 点击 **online-game** Job
2. 点击最新的 **Build #1**（或其他数字）
3. 点击 **Console Output**
4. 看到绿色的 ✅ 就是成功了！

如果看到红色的 ❌，查看错误信息（通常是缺少凭证或配置错误）

---

## 🛠️ 常见问题

### Q1: 构建失败，说"找不到docker-username"
**原因**：忘记添加凭证
**解决**：回到第2步，添加Jenkins凭证

### Q2: 推送镜像失败，说"未授权"
**原因**：Docker Hub用户名/密码错误
**解决**：检查凭证中的用户名和密码是否正确

### Q3: 部署到服务器失败
**原因**：通常是SSH密钥问题
**解决**：
```bash
# 在服务器上检查是否有docker
docker --version

# 检查 docker-compose
docker-compose --version
```

### Q4: 应用部署了但访问不了
**原因**：防火墙或Docker未启动
**解决**：
```bash
# SSH连接到服务器
ssh root@你的IP

# 查看Docker日志
docker logs online-game

# 检查端口是否监听
docker ps | grep online-game
```

---

## 📚 下一步学习

现在你已经掌握了基础，后面可以学：
- ✏️ 添加 ESLint 检查
- 📊 添加 SonarQube 代码分析
- 📧 添加邮件通知
- 🚨 添加告警机制

但现在不必急，先让这个简单的流程稳定运行！

---

## 🆘 需要帮助？

遇到问题先看：
1. Jenkins 的 **Console Output** 日志
2. 服务器的 Docker 日志：`docker logs online-game`
3. 检查所有凭证是否配置正确

祝你使用愉快！🎉
