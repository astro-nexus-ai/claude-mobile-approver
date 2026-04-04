# Claude Mobile Approver - 服务器配置指南

Claude Mobile Approver 推送通知系统的服务端配置文档。

## 前置条件

- 已安装 Docker 的 Linux 服务器
- 开放 2586 和 2587 端口

## 1. 部署 ntfy 服务器

### 创建目录

```bash
mkdir -p /opt/ntfy/cache /opt/ntfy/config
```

### 创建配置文件

```bash
cat > /opt/ntfy/config/server.yml << 'EOF'
# Ntfy 服务器配置
base-url: http://YOUR_SERVER_IP:2586
behind-proxy: false

# 认证设置
auth-file: /etc/ntfy/user.db
auth-default-access: deny-all
enable-signup: false

# 速率限制
visitor-request-limit-burst: 100
visitor-request-limit-replenish: 1s
visitor-message-daily-limit: 0

# 缓存
cache-file: /var/cache/ntfy/cache.db
cache-duration: 12h

# 启用 iOS/Android 推送通知（通过 ntfy.sh 中转）
upstream-base-url: "https://ntfy.sh"
EOF
```

### 生成 Web Push 密钥（iOS 推送必需）

iOS 设备需要 Web Push 配置才能接收即时推送通知：

```bash
# 生成 Web Push 密钥对
docker exec ntfy ntfy webpush keys
```

输出示例：
```
web-push-public-key: BKy5v-xxx...
web-push-private-key: QF1wNZxxx...
```

将生成的密钥添加到 `/opt/ntfy/config/server.yml`：

```bash
cat >> /opt/ntfy/config/server.yml << 'EOF'

# Web Push 配置（iOS 推送必需）
web-push-public-key: YOUR_PUBLIC_KEY
web-push-private-key: YOUR_PRIVATE_KEY
web-push-file: /var/cache/ntfy/webpush.db
web-push-email-address: your-email@example.com
EOF
```

**⚠️ 重要**：添加 Web Push 配置后需要重启 ntfy：
```bash
cd /opt/ntfy && docker compose restart
```

### 创建 docker-compose.yml

```bash
cat > /opt/ntfy/docker-compose.yml << 'EOF'
services:
  ntfy:
    image: binwiederhier/ntfy
    command: serve
    ports:
      - "2586:80"
    volumes:
      - ./config:/etc/ntfy
      - ./cache:/var/cache/ntfy
    restart: unless-stopped
EOF
```

### 启动 ntfy

```bash
cd /opt/ntfy && docker compose up -d
```

### 创建管理员用户

```bash
docker exec -it ntfy ntfy user add --role=admin claude
# 根据提示输入密码
```

## 2. 部署审批服务器

### 创建目录

```bash
mkdir -p /opt/claude-approver/approvals
```

### 上传 app.py

从仓库下载 `app.py` 并上传到 `/opt/claude-approver/`。

### 创建启动脚本

```bash
cat > /opt/claude-approver/start.sh << 'EOF'
#!/bin/bash
cd /opt/claude-approver
export PORT=2587
export APPROVAL_DIR=/opt/claude-approver/approvals
nohup python3 app.py > /var/log/claude-approver.log 2>&1 &
EOF

chmod +x /opt/claude-approver/start.sh
```

### 启动审批服务器

```bash
/opt/claude-approver/start.sh
```

## 3. 添加新用户

为每位同事创建独立用户和 topic：

```bash
# 创建用户
docker exec -it ntfy ntfy user add --role=user <用户名>
# 根据提示输入密码

# 授权访问专属 topic
docker exec ntfy ntfy access <用户名> claude-approve-<用户名> rw
```

示例：
```bash
# 创建用户 wang
docker exec -it ntfy ntfy user add --role=user wang
# 输入密码：Wang@2026

# 授权 topic
docker exec ntfy ntfy access wang claude-approve-wang rw
```

### 验证用户

```bash
# 查看用户列表
docker exec ntfy ntfy user list

# 查看权限列表
docker exec ntfy ntfy access list
```

## 4. 服务器地址

| 服务 | 地址 |
|-----|------|
| ntfy 服务器 | `http://YOUR_SERVER_IP:2586` |
| 审批服务器 | `http://YOUR_SERVER_IP:2587` |

## 5. 故障排查

### 查看 ntfy 日志
```bash
docker logs -f ntfy
```

### 查看审批服务器日志
```bash
tail -f /var/log/claude-approver.log
```

### 重启服务
```bash
# 重启 ntfy
cd /opt/ntfy && docker compose restart

# 重启审批服务器
pkill -f "python3 app.py"
/opt/claude-approver/start.sh
```

### 健康检查
```bash
curl http://localhost:2586/health
curl http://localhost:2587/health
```
