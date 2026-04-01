# Promotion Materials

Promotion copy for various platforms.

---

## 1. GitHub Topics

Add these topics in GitHub repository settings:

```
claude-code
claude-ai
anthropic
push-notifications
ntfy
mobile-approval
productivity
developer-tools
remote-work
automation
self-hosted
flask
bash
```

---

## 2. Release Notes (v1.0.0)

```markdown
# Claude Mobile Approver v1.0.0

🎉 First public release!

## ✨ Features

- **Real-time Push Notifications** - Get instant alerts when Claude Code needs permission
- **One-tap Approval** - Approve or deny with a single tap from your phone
- **Beautiful Mobile UI** - Clean, responsive approval page with tool details
- **Multi-user Support** - Team members can use independently with isolated topics
- **Privacy Friendly** - Self-hosted, your data stays on your server
- **Cross-platform** - Works on iOS and Android via ntfy app

## 🚀 Quick Start

1. Deploy ntfy server and approval server
2. Configure hook script on your machine
3. Install ntfy app on your phone
4. Start using Claude Code with mobile approval!

## 📖 Documentation

- [Architecture Guide](../ARCHITECTURE.md)
- [Server Setup](../docs/server-setup.md)
- [User Guide](../docs/user-guide.md)

## 🤝 Contributing

Issues and Pull Requests welcome!

## 📄 License

MIT License
```

---

## 3. Product Hunt

### Title
```
Claude Mobile Approver
```

### Tagline
```
Approve Claude Code permissions from your phone
```

### Description
```
🤔 The Problem:
Claude Code often needs your permission to run commands or edit files. But what if you're away from your desk?

💡 The Solution:
Claude Mobile Approver sends real-time push notifications to your phone when Claude needs permission. Review the details and approve/deny with a single tap—from anywhere.

✨ Key Features:
• Real-time push notifications (via ntfy)
• Beautiful mobile approval page
• One-tap approve or deny
• Multi-user support for teams
• Self-hosted for privacy
• Works on iOS and Android
• Easy setup in 5 minutes

🔧 How it works:
1. Deploy the ntfy server and approval service on your server
2. Install the hook script on your machine
3. Configure the ntfy app on your phone
4. When Claude needs permission → You get a notification → Tap to approve → Done!

Perfect for developers who use Claude Code and want the freedom to step away from their desk.

🔗 Open Source: github.com/zenyrahq/claude-mobile-approver
```

### Topics
```
Developer Tools, Productivity, Open Source, AI, Mobile
```

---

## 4. Hacker News (Show HN)

### Title
```
Show HN: Claude Mobile Approver – Approve Claude Code permissions from your phone
```

### Body
```
Hi HN,

I built Claude Mobile Approver to solve a pain point I've been having with Claude Code.

The problem: Claude Code frequently asks for permission to run commands, edit files, etc. But I'm often away from my desk—grabbing coffee, in meetings, or working from another room. When I return, Claude is waiting for my input.

The solution: A system that pushes permission requests to my phone, where I can review and approve them instantly.

How it works:
- A bash hook script intercepts Claude Code's permission requests
- It sends a push notification via ntfy (open-source push service)
- I tap the notification on my phone
- A web page shows the tool name and command details
- I tap Approve or Deny
- Claude Code continues (or stops)

Tech stack:
- ntfy for push notifications (self-hosted)
- Flask for the approval web server
- Bash for the hook script
- Mermaid for architecture diagrams

Features:
- Real-time push via ntfy.sh gateway for iOS/Android
- Multi-user support with isolated topics
- Self-hosted and privacy-friendly
- Bilingual docs (English/中文/日本語)

GitHub: https://github.com/zenyrahq/claude-mobile-approver

I'd love to hear feedback from the community. What features would make this more useful for you?
```

---

## 5. Reddit

### r/ClaudeAI

**Title:**
```
[Tool] I built a mobile approval system for Claude Code - approve permissions from your phone!
```

**Body:**
```
Hey r/ClaudeAI!

I created an open-source tool that lets you approve Claude Code permission requests from your phone.

## Why I built this

I love Claude Code, but I found myself tethered to my desk waiting for permission prompts. If I stepped away for coffee or a meeting, Claude would be sitting there waiting when I returned.

## What it does

- 📱 Sends push notifications when Claude needs permission
- 👆 Shows command/file details on your phone
- ⚡ One-tap approve or deny
- 👥 Supports multiple users (great for teams)
- 🔒 Self-hosted (your data stays with you)

## How it works

The system uses:
- **ntfy** for push notifications (self-hosted)
- **Flask** for the approval web server
- **Bash hook** to intercept permission requests

## Links

GitHub: https://github.com/zenyrahq/claude-mobile-approver

Would love to hear your thoughts and feedback!
```

### r/programming

**Title:**
```
Show r/programming: Claude Mobile Approver - Self-hosted push notifications for terminal permission prompts
```

**Body:**
```
Built a tool to solve a personal pain point: terminal-based AI tools that need permission while I'm away from my desk.

Features:
- Real-time push via ntfy (open source)
- Mobile web UI for approval
- Multi-user with topic isolation
- Bash hooks + Flask backend

GitHub: https://github.com/zenyrahq/claude-mobile-approver

Curious if others have similar workflows that could benefit from this pattern.
```

---

## 6. Twitter/X

### Tweet 1 (Launch)
```
🚀 Introducing Claude Mobile Approver!

📱 Approve Claude Code permissions from your phone
🔔 Real-time push notifications
👥 Multi-user support
🔒 Self-hosted & privacy-friendly

Never be stuck waiting at your desk again!

GitHub: https://github.com/zenyrahq/claude-mobile-approver

#ClaudeAI #DevTools #OpenSource
```

### Tweet 2 (Demo)
```
Ever wish you could approve Claude Code commands while grabbing coffee? ☕

Now you can.

Here's how it works:
1️⃣ Claude needs permission
2️⃣ Phone buzzes
3️⃣ Tap notification
4️⃣ Review & approve
5️⃣ Claude continues

Open source & self-hosted 👇

https://github.com/zenyrahq/claude-mobile-approver

#BuildInPublic
```

### Tweet 3 (Thread starter)
```
🧵 I built a mobile approval system for Claude Code. Here's the story:

[Thread] 🧵
```

---

## 7. 掘金 (中文)

### 标题
```
我用 ntfy 实现了 Claude Code 手机远程审批，再也不用守着电脑了！
```

### 正文大纲
```
## 背景

Claude Code 很强大，但经常需要确认权限。每次离开电脑，Claude 就在等待...

## 解决方案

Claude Mobile Approver - 手机远程审批系统

## 功能特点

- 📱 实时推送通知
- 👆 一键批准/拒绝
- 👥 多用户支持
- 🔒 自托管，隐私友好

## 技术架构

[架构图]

- ntfy: 推送服务
- Flask: 审批服务器
- Bash: Hook 脚本

## 快速开始

[部署步骤]

## 总结

开源地址：https://github.com/zenyrahq/claude-mobile-approver

欢迎 Star ⭐
```

---

## 8. V2EX (中文)

### 节点
```
分享创造
```

### 标题
```
[开源] Claude Mobile Approver - 手机上审批 Claude Code 权限请求
```

### 正文
```
大家好，

我开发了一个小工具，解决我使用 Claude Code 时的一个痛点。

## 问题

Claude Code 经常需要权限确认，但我不想一直守在电脑前。

## 解决方案

做了一个远程审批系统：
- 权限请求 → 推送到手机 → 点击审批 → Claude 继续

## 技术栈

- ntfy (推送服务，自托管)
- Flask (审批服务器)
- Bash (Hook 脚本)

## 特点

- 自托管，隐私友好
- 支持多用户
- iOS/Android 都能用

GitHub: https://github.com/zenyrahq/claude-mobile-approver

欢迎反馈！
```

---

## 9. Zenn (日本語)

### タイトル
```
Claude Codeの権限リクエストをスマホで承認できるツールを作った
```

### 概要
```
Claude Codeの権限リクエストをスマホにプッシュ通知し、
ワンタップで承認/拒否できるオープンソースツールを開発しました。
```

---

## 10. Awesome Lists to Submit

Submit to these repositories:

1. **awesome-claude** - AI tools related to Claude
2. **awesome-productivity** - Productivity tools
3. **awesome-selfhosted** - Self-hosted applications
4. **awesome-bash** - Bash scripts and tools
5. **awesome-flask** - Flask applications

### Submission Template
```
## Claude Mobile Approver

Approve Claude Code permission requests from your phone via push notifications.

- **URL**: https://github.com/zenyrahq/claude-mobile-approver
- **Description**: Real-time push notifications for Claude Code permissions with mobile approval UI
- **Category**: [Developer Tools / Productivity / Self-hosted]
- **License**: MIT
```

---

## Checklist

- [ ] Add GitHub Topics in repository settings
- [ ] Create v1.0.0 Release on GitHub
- [ ] Add demo.gif and screenshots to docs/images/
- [ ] Submit to Product Hunt
- [ ] Post to Hacker News (Show HN)
- [ ] Share on Reddit (r/ClaudeAI, r/programming)
- [ ] Tweet with demo
- [ ] Post to 掘金/V2EX (Chinese)
- [ ] Post to Zenn/Qiita (Japanese)
- [ ] Submit to Awesome lists
