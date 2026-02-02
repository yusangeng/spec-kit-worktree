<div align="center">
    <img src="./media/logo_large.webp" alt="Spec Kit Logo" width="200" height="200"/>
    <h1>🌱 Spec Kit Worktree</h1>
    <h3><em>Spec Kit 的 Git Worktree 增强版</em></h3>
</div>

<p align="center">
    <strong>基于官方 Spec Kit，增加 Git Worktree 支持，实现真正的并行特性开发</strong>
</p>

<p align="center">
    <a href="https://github.com/github/spec-kit"><img src="https://img.shields.io/badge/base_official-spec--kit-blue" alt="Based on official spec-kit"/></a>
    <a href="https://github.com/github/spec-kit/blob/main/LICENSE"><img src="https://img.shields.io/github/license/github/spec-kit" alt="License"/></a>
</p>

---

## 📖 什么是 Spec Kit Worktree？

**Spec Kit Worktree** 是 [github/spec-kit](https://github.com/github/spec-kit) 的增强版本，新增了 **Git Worktree 支持**。

### 核心功能：并行开发多个特性

使用官方 Spec Kit 时，你需要在不同的特性分支之间频繁切换。而在本版本中，每个特性都有**独立的 Worktree 目录**，你可以同时打开多个终端窗口，各自开发不同的特性，互不干扰！

```
官方版本：需要频繁切换分支
  develop feature-1 → 开发 → 切换到 feature-2 → 开发 → 切换回 feature-1
  (来回切换，容易混乱)

Worktree版本：并行开发，无需切换
  终端1: .wt/feature-1/  → 开发特性1
  终端2: .wt/feature-2/  → 开发特性2
  终端3: .wt/feature-3/  → 开发特性3
  (同时进行，互不干扰)
```

### 关于 Spec Kit

Spec Kit 是一个**规范驱动开发（Spec-Driven Development）**工具包。核心思想是：

- 先明确 **做什么（WHAT）** 和 **为什么（WHY）**
- 再考虑 **怎么做（HOW）**
- 通过 `/speckit.*` 斜杠命令，结构化地完成开发流程

详细文档：[官方 Spec Kit 文档](https://github.github.io/spec-kit/)

---

## 🎯 这个版本多了什么功能？

### ✨ 新增功能：Git Worktree 支持

#### 1. 并行开发多个特性

```bash
# 同时开发三个特性，互不干扰
.specify/scripts/bash/create-worktree.sh user-auth      # 特性1：用户认证
.specify/scripts/bash/create-worktree.sh payment         # 特性2：支付功能
.specify/scripts/bash/create-worktree.sh notification    # 特性3：通知系统

# 查看所有 worktree
.specify/scripts/bash/list-worktrees.sh

# 在不同终端中同时开发
cd .wt/user-auth       # 终端1：开发用户认证
cd .wt/payment         # 终端2：开发支付功能
cd .wt/notification    # 终端3：开发通知系统
```

#### 2. 跨平台支持

- **Linux/macOS**: Bash 脚本（`.sh`）
- **Windows**: PowerShell 脚本（`.ps1`）

---

## ⚡ 快速开始

### 第 1 步：安装 CLI

```bash
# 使用 uv 安装
uv tool install specify-worktree-cli --from git+https://github.com/YOUR_USERNAME/spec-kit.git

# 验证安装
specify-worktree check
```

### 第 2 步：初始化项目（启用 Worktree）

```bash
# 创建新项目
specify-worktree init my-project --worktree --ai claude

# 或在现有项目中启用
cd my-project
specify-worktree init . --worktree --ai claude
```

### 第 3 步：创建第一个特性

```bash
# 方式一：使用 AI 助手（推荐）
# 启动 Claude Code，然后输入：
/speckit.specify 添加用户登录功能

# 这会自动创建 worktree，你可以看到创建的目录：
# .wt/user-login/

# 方式二：手动创建 worktree
.specify/scripts/bash/create-worktree.sh my-feature

# 进入 worktree 目录
cd .wt/my-feature
```

### 第 4 步：并行开发多个特性

```bash
# 打开多个终端窗口

# 终端1：开发用户认证
.specify/scripts/bash/create-worktree.sh user-auth
cd .wt/user-auth
/speckit.specify 添加用户认证功能

# 终端2：同时开发支付功能（切换到另一个终端）
.specify/scripts/bash/create-worktree.sh payment
cd .wt/payment
/speckit.specify 添加支付功能

# 两个特性完全独立，互不干扰！
```

### 第 5 步：完成开发后清理

```bash
# 查看所有 worktree
.specify/scripts/bash/list-worktrees.sh

# 删除已完成的 worktree
.specify/scripts/bash/remove-worktree.sh user-auth
```

---

## 🔧 常用命令

### Worktree 管理

```bash
# 创建 worktree
.specify/scripts/bash/create-worktree.sh <feature-name>

# 列出所有 worktree
.specify/scripts/bash/list-worktrees.sh

# 删除 worktree
.specify/scripts/bash/remove-worktree.sh <feature-name>
```

### CLI 命令

```bash
# 初始化项目
specify-worktree init <project-name> --worktree --ai claude

# 在当前目录初始化
specify-worktree init . --worktree

# 检查工具
specify-worktree check
```

### Windows 用户（PowerShell）

```bash
# 创建 worktree
.specify/scripts/powershell/Create-Worktree.ps1 <feature-name>

# 列出所有 worktree
.specify/scripts/powershell/List-Worktrees.ps1

# 删除 worktree
.specify/scripts/powershell/Remove-Worktree.ps1 <feature-name>
```

---

## 💡 使用场景

### 适合使用本版本

✅ **同时开发多个特性** - 如用户认证 + 支付 + 通知
✅ **大型项目** - 切换分支成本高
✅ **频繁上下文切换** - 需要在不同特性间快速切换
✅ **团队协作** - 多人同时开发，减少分支冲突

### 使用官方版本即可

✅ **小型项目** - 分支切换成本低
✅ **顺序开发** - 一次只开发一个特性
✅ **不熟悉 Git Worktree** - 团队不熟悉 worktree 概念

---

## 📚 学习更多

### 核心 SDD 方法论

所有 `/speckit.*` 命令与官方版本完全一致：

- **[官方文档](https://github.github.io/spec-kit/)** - 完整的方法论和教程
- **[详细步骤](https://github.github.io/spec-kit/#-detailed-process)** - 完整的 walkthrough

### Slash 命令

启动 AI 助手后，可使用：

```
/speckit.constitution  - 建立项目原则
/speckit.specify       - 定义功能需求（自动创建 worktree）
/speckit.plan          - 创建技术方案
/speckit.tasks         - 生成任务列表
/speckit.implement     - 执行实现
```

### AI 助手支持

支持所有官方 AI Agents：
- Claude Code, Gemini CLI, Cursor, GitHub Copilot, Windsurf, Qwen, 等等

---

## 🤝 贡献

本项目是 Spec Kit 的独立分支版本。

- **上游项目**: [github/spec-kit](https://github.com/github/spec-kit)
- **本仓库**: [YOUR_USERNAME/spec-kit](https://github.com/YOUR_USERNAME/spec-kit)

### 提交 Issue

- **worktree 相关问题** → 在本仓库提交 Issue
- **SDD 方法论问题** → 在官方仓库提交 Issue

---

## 📄 许可证

MIT License - 与官方 Spec Kit 相同

---

## 🙏 致谢

本项目基于 [github/spec-kit](https://github.com/github/spec-kit) 的优秀工作，核心 SDD 方法论和 `/speckit.*` 命令完全来自官方项目。

特别感谢：
- John Lam ([@jflam](https://github.com/jflam))
- Den Delimarsky ([@localden](https://github.com/localden))

本版本仅增加 Git Worktree 支持，所有核心功能归功于官方团队。

---

## 📞 支持

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/spec-kit/issues)
- **官方文档**: [spec-kit.github.io](https://github.github.io/spec-kit/)
