# 1. 使用 Node 官方镜像
FROM node:22-alpine

# 2. 设置工作目录
WORKDIR /app

# 3. 复制 package.json
COPY package*.json ./

# 4. 安装依赖
RUN npm install

# 5. 复制项目
COPY . .

# 6. 构建 Next.js
RUN npm run build

# 7. 暴露端口
EXPOSE 3000

# 8. 启动（监听外网）
CMD ["npm", "run", "start", "--", "-H", "0.0.0.0"]