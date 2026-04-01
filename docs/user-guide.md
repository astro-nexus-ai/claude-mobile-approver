# Claude Mobile Approver - 同事配置指南

使用本指南在你的设备上配置 Claude Code 移动审批功能。

## 功能说明

- 当 Claude Code 需要权限时，手机会收到推送通知
- 在手机上一键批准或拒绝
- 任何有网络的地方都可以使用

---

## 前置条件

开始之前，请向管理员获取以下信息：
- **服务器地址**: `http://<服务器地址>:2586`
- **你的用户名**: （例如：`wang`）
- **你的密码**: （例如：`Wang@2026`）
- **你的 Topic**: （例如：`claude-approve-wang`）

---

## 向管理员确认的信息

配置前，请先联系管理员获取以下信息，并填写在此处方便后续配置：

| 信息项 | 说明 | 你的值 |
|-------|------|-------|
| 服务器地址 | ntfy 服务器 IP 或域名 | `________________` |
| 用户名 | 你的登录账号 | `________________` |
| 密码 | 你的登录密码 | `________________` |
| Topic | 消息频道名称 | `claude-approve-__________` |

**示例**（请替换为你自己的值）：
```
服务器地址: your-server.example.com
用户名: wang
密码: YourPassword123
Topic: claude-approve-wang
```

---

## 第一步：在手机上安装 ntfy App

### iOS 用户
1. 打开 **App Store**
2. 搜索 **"ntfy"**
3. 安装由 Philipp C. Heckel 开发的应用

### Android 用户
1. 打开 **Play 商店** 或 **F-Droid**
2. 搜索 **"ntfy"**
3. 安装应用

---

## 第二步：配置 ntfy App

### 2.1 添加服务器

1. 打开 **ntfy** 应用
2. 进入 **Settings**（设置/齿轮图标）
3. 点击 **Add server**（添加服务器）
4. 输入：
   - **Base URL**: `http://<服务器地址>:2586`
5. 点击 **Save**（保存）

### 2.2 登录账号

1. 点击刚添加的服务器
2. 输入你的凭据：
   - **Username**: （你的用户名，例如 `wang`）
   - **Password**: （你的密码）
3. 点击 **Login**（登录）

### 2.3 订阅 Topic

1. 在主界面点击 **+** 或 **Subscribe**
2. 输入：
   - **Topic**: （你的 topic，例如 `claude-approve-wang`）
3. **重要**：开启 **Instant delivery** 选项
4. 点击 **Subscribe**

### 2.4 开启通知权限（iOS）

1. 进入 **设置** → **通知** → **ntfy**
2. 开启 **允许通知**
3. 开启 **锁屏**、**通知中心**、**横幅**
4. 开启 **声音**

### 2.5 关闭电池优化（Android）

1. 进入 **设置** → **应用** → **ntfy** → **电池**
2. 选择 **无限制**
3. 进入 **设置** → **应用** → **ntfy** → **电池** → **应用电池优化**
4. 为 ntfy 选择 **不优化**

---

## 第三步：配置你的电脑

### 3.1 创建 Hook 脚本

创建目录：
```bash
mkdir -p ~/.claude/scripts
```

创建文件 `~/.claude/scripts/ntfy-notify.sh`，内容如下：

```bash
#!/bin/bash
# Claude Code 远程审批脚本
# 重要：请将下面的值替换为你自己的凭据！

NTFY_SERVER="http://<服务器地址>:2586"
APPROVAL_SERVER="http://<服务器地址>:2587"
NTFY_USER="你的用户名"                    # <-- 替换为你的用户名
NTFY_PASS="你的密码"                      # <-- 替换为你的密码
NTFY_TOPIC="claude-approve-你的用户名"    # <-- 替换为你的 topic

# 生成唯一会话 ID
SESSION_ID="sess-$(date +%s)-$$"

# 从标准输入读取 hook 输入
INPUT=$(cat)

# 提取工具信息
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')
SUGGESTIONS=$(echo "$INPUT" | jq -c '.permission_suggestions // []')

# 根据工具类型构建描述
case "$TOOL_NAME" in
    Bash)
        CMD=$(echo "$TOOL_INPUT" | jq -r '.command // ""')
        DESC="执行命令: $(echo "$CMD" | cut -c1-50)"
        ;;
    Edit)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        DESC="编辑文件: $FILE"
        ;;
    Write)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        DESC="写入文件: $FILE"
        ;;
    Read)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        DESC="读取文件: $FILE"
        ;;
    Glob)
        PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // ""')
        DESC="查找文件: $PATTERN"
        ;;
    Grep)
        PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // ""')
        DESC="搜索内容: $PATTERN"
        ;;
    *)
        DESC="工具: $TOOL_NAME"
        ;;
esac

# 创建审批请求
curl -s -X POST "$APPROVAL_SERVER/request/$SESSION_ID" \
    -H "Content-Type: application/json" \
    -d "{
        \"tool\": \"$TOOL_NAME\",
        \"input\": $TOOL_INPUT,
        \"description\": \"$DESC\",
        \"suggestions\": $SUGGESTIONS
    }" > /dev/null 2>&1

# 构建审批 URL
APPROVAL_URL="$APPROVAL_SERVER/$SESSION_ID"

# 发送通知
curl -s -u "$NTFY_USER:$NTFY_PASS" \
    -H "Title: 🤖 $DESC" \
    -H "Priority: high" \
    -H "Tags: claude" \
    -H "Click: $APPROVAL_URL" \
    -d "工具: $TOOL_NAME" \
    "$NTFY_SERVER/$NTFY_TOPIC" > /dev/null 2>&1

# 轮询等待审批结果（最长 5 分钟）
MAX_WAIT=300
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    STATUS=$(curl -s "$APPROVAL_SERVER/check/$SESSION_ID" 2>/dev/null | jq -r '.status // "pending"')

    case "$STATUS" in
        approved)
            curl -s -X POST "$APPROVAL_SERVER/cleanup/$SESSION_ID" > /dev/null 2>&1
            jq -n '{
                hookSpecificOutput: {
                    hookEventName: "PermissionRequest",
                    decision: { behavior: "allow" }
                }
            }'
            exit 0
            ;;
        denied)
            curl -s -X POST "$APPROVAL_SERVER/cleanup/$SESSION_ID" > /dev/null 2>&1
            jq -n '{
                hookSpecificOutput: {
                    hookEventName: "PermissionRequest",
                    decision: { behavior: "deny", message: "已通过手机拒绝" }
                }
            }'
            exit 0
            ;;
    esac

    sleep 2
    WAITED=$((WAITED + 2))
done

# 超时 - 默认允许（如需更安全可改为 deny）
jq -n '{
    hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: { behavior: "allow" }
    }
}'
exit 0
```

**重要**：请替换脚本中的以下值：
- `你的用户名` → 你的实际用户名
- `你的密码` → 你的实际密码
- `claude-approve-你的用户名` → 你的实际 topic

### 3.2 添加执行权限

```bash
chmod +x ~/.claude/scripts/ntfy-notify.sh
```

---

## 第四步：配置 Claude Code

编辑 `~/.claude/settings.json`，添加 hooks 配置：

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/ntfy-notify.sh"
          }
        ]
      }
    ]
  }
}
```

如果文件已存在，将 `hooks` 部分合并到现有配置中。

---

## 第五步：测试

### 5.1 测试推送通知

请管理员发送测试通知，或自行运行：

```bash
curl -u "你的用户名:你的密码" \
  -H "Title: 📱 测试" \
  -H "Priority: high" \
  -d "这是一条测试消息" \
  "http://<服务器地址>:2586/claude-approve-你的用户名"
```

手机应该收到推送通知。

### 5.2 测试完整流程

1. 启动 Claude Code
2. 触发一个权限请求（例如让 Claude 执行一个 bash 命令）
3. 手机收到推送通知
4. 点击通知打开审批页面
5. 点击 **Approve** 或 **Deny**
6. Claude Code 根据你的决定继续执行或停止

---

## 快速参考

| 项目 | 值 |
|-----|-----|
| ntfy 服务器 | `http://<服务器地址>:2586` |
| 审批服务器 | `http://<服务器地址>:2587` |
| 你的用户名 | _（向管理员获取）_ |
| 你的密码 | _（向管理员获取）_ |
| 你的 Topic | `claude-approve-<用户名>` |

---

## 故障排查

### 手机收不到推送通知
1. 检查 ntfy app 是否已登录
2. 检查是否已订阅 topic
3. 确保订阅设置中开启了 **Instant delivery**
4. 检查 iOS/Android 系统通知权限

### 审批不生效
1. 检查审批服务器状态：`curl http://<服务器地址>:2587/health`
2. 检查 hook 脚本是否有执行权限：`ls -la ~/.claude/scripts/ntfy-notify.sh`
3. 检查 Claude Code settings.json 配置是否正确

### 超时错误
- 默认超时时间为 5 分钟
- 请在超时前完成审批操作

---

## 需要帮助？

如有问题，请联系管理员。
