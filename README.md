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

## 📖 简介

**Spec Kit Worktree** 是基于 [github/spec-kit](https://github.com/github/spec-kit) 的一个分支版本，核心增强是 **Git Worktree 支持**。

### 官方 Spec Kit 是什么？

Spec Kit 是一个规范驱动开发（Spec-Driven Development, SDD）工具包，它颠覆了传统的软件开发模式。核心思想是：

- **规范是可执行的产物**，而非可抛弃的文档
- 先定义 **WHAT（做什么）** 和 **WHY（为什么）**，再考虑 HOW（怎么做）
- 通过 `/speckit.*` 斜杠命令，实现结构化的开发流程

详细文档请参考：[官方 Spec Kit 文档](https://github.github.io/spec-kit/)

---

## 🎯 与官方版本的区别

### 核心差异

| 特性 | 官方 Spec Kit | Spec Kit Worktree (本版本) |
|------|--------------|---------------------------|
| **CLI 命令** | `specify` | `specify-worktree` |
| **分支策略** | 单仓库，频繁切换分支 | 多 Worktree，并行开发 |
| **特性隔离** | 逻辑隔离（分支） | 物理隔离（独立目录） |
| **开发模式** | 顺序开发 | 并行开发 |
| **上下文切换** | 需要切换分支 | 无需切换，直接进入目录 |
| **脚本语言** | Python CLI | Bash/PowerShell 脚本 |

### 主要增强

#### 1. Git Worktree 原生支持

每个特性开发都有独立的 Worktree 目录，实现真正的物理隔离：

```bash
# 创建特性 A 的 worktree
.specify/scripts/bash/create-worktree.sh user-auth
cd .wt/user-auth  # 进入独立的开发目录

# 创建特性 B 的 worktree
.specify/scripts/bash/create-worktree.sh payment-gateway
cd .wt/payment-gateway  # 另一个独立目录

# 同时开发两个特性，无需频繁切换分支！
```

#### 2. 跨平台脚本支持

提供 **Bash**（Linux/macOS）和 **PowerShell**（Windows）两种脚本：

```bash
# Linux/macOS
.specify/scripts/bash/create-worktree.sh <feature-name>
.specify/scripts/bash/list-worktrees.sh
.specify/scripts/bash/remove-worktree.sh <feature-name>

# Windows
.specify/scripts/powershell/Create-Worktree.ps1 <feature-name>
.specify/scripts/powershell/List-Worktrees.ps1
.specify/scripts/powershell/Remove-Worktree.ps1 <feature-name>
```

#### 3. 可定制的模板脚本

脚本作为模板复制到目标项目，用户可根据需求自由修改，而非固化的 Python CLI 命令。

---

## ⚡ 快速开始

### 1. 安装 CLI

```bash
# 使用 uv 安装（推荐）
uv tool install specify-worktree-cli --from git+https://github.com/YOUR_USERNAME/spec-kit.git

# 验证安装
specify-worktree check
```

### 2. 初始化项目（启用 Worktree 模式）

```bash
# 创建新项目并启用 worktree 模式
specify-worktree init my-project --worktree --ai claude

# 或在现有项目中启用
cd my-project
specify-worktree init . --worktree --ai claude
```

### 3. 创建第一个特性 Worktree

```bash
# 方式一：在 AI 助手中使用 /speckit.specify 命令
# 会自动创建 worktree

# 方式二：手动创建 worktree
.specify/scripts/bash/create-worktree.sh my-first-feature

# 进入 worktree 目录
cd .wt/my-first-feature

# 开始开发！
```

---

## 🔧 核心功能

### Worktree 管理

#### 列出所有 Worktree

```bash
.specify/scripts/bash/list-worktrees.sh
```

输出示例：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Feature:    user-auth
  Branch:     feature/user-auth
  Path:       .wt/user-auth
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 1 worktree(s)
```

#### 删除 Worktree

```bash
.specify/scripts/bash/remove-worktree.sh user-auth
```

### 典型开发流程

```bash
# 1. 初始化项目（启用 worktree）
specify-worktree init my-project --worktree --ai claude
cd my-project

# 2. 启动 AI 助手（如 Claude Code）

# 3. 使用 /speckit.specify 创建第一个特性
# 会自动创建 worktree 并进入

# 4. 在 AI 助手中使用 /speckit.plan 创建技术方案

# 5. 使用 /speckit.tasks 生成任务列表

# 6. 使用 /speckit.implement 执行实现

# 7. 完成后，删除 worktree
.specify/scripts/bash/remove-worktree.sh feature-name
```

---

## 📚 详细文档

### 核心 SDD 方法论

- **[完整的 Spec-Driven Development 方法论](https://github.github.io/spec-kit/spec-driven.html)** - 官方详细教程
- **[详细步骤指南](https://github.github.io/spec-kit/#-detailed-process)** - 完整的 walkthrough

### Slash 命令参考

所有 `/speckit.*` 命令与官方版本完全一致，详细说明请参考：

- **[Core Commands](https://github.github.io/spec-kit/#-slash-commands)**
  - `/speckit.constitution` - 建立项目原则
  - `/speckit.specify` - 定义功能需求
  - `/speckit.plan` - 创建技术方案
  - `/speckit.tasks` - 生成任务列表
  - `/speckit.implement` - 执行实现

- **[Optional Commands](https://github.github.io/spec-kit/#-slash-commands-1)**
  - `/speckit.clarify` - 澄清需求细节
  - `/speckit.analyze` - 一致性分析
  - `/speckit.checklist` - 质量检查清单

### AI 助手支持

支持所有官方 [AI Agents](https://github.github.io/spec-kit/#-supported-ai-agents)：
- Claude Code, Gemini CLI, Cursor, GitHub Copilot, Windsurf, Qwen, 等等

---

## 🎨 使用场景

### 适合使用 Worktree 版本的场景

✅ **并行开发多个特性** - 同时开发多个不相关的特性
✅ **大型项目** - 项目大，切换分支成本高
✅ **频繁上下文切换** - 需要在不同特性间快速切换
✅ **团队协作** - 多人同时开发，减少分支冲突

### 使用官方版本即可的场景

✅ **小型项目** - 项目小，分支切换成本低
✅ **顺序开发** - 一次只开发一个特性
✅ **不熟悉 Git Worktree** - 团队不熟悉 worktree 概念

---

## 🛠️ 技术实现

### 架构差异

```
官方 Spec Kit:
project/
├── .git/
├── feature-1/  # 通过 git checkout feature-1 切换
├── feature-2/  # 通过 git checkout feature-2 切换
└── main/

Spec Kit Worktree:
project/
├── .git/
├── .wt/
│   ├── feature-1/  # 独立的工作目录，始终在 feature-1 分支
│   ├── feature-2/  # 独立的工作目录，始终在 feature-2 分支
│   └── main/       # 主分支的工作目录
```

### 代码变更

- **移除**: Python worktree 模块（405 行）
- **添加**: Bash/PowerShell 脚本（~1,500 行）
- **优势**: 脚本可定制，用户可修改适应项目需求

详细变更请参考：[提交记录](https://github.com/YOUR_USERNAME/spec-kit/commits/main)

---

## 🔧 命令参考

### `specify-worktree init` 参数

```bash
specify-worktree init <PROJECT_NAME> [OPTIONS]

# 选项：
  --ai <agent>          # AI 助手 (claude, gemini, copilot, cursor-agent, etc.)
  --worktree           # 启用 worktree 模式（本版本核心特性）
  --script <sh|ps>     # 脚本类型：sh (bash) 或 ps (PowerShell)
  --here               # 在当前目录初始化
  --force              # 强制合并，跳过确认
  --no-git             # 跳过 git 初始化
  --debug              # 启用调试输出
  --github-token       # GitHub API token
```

### 示例

```bash
# 基本初始化（启用 worktree）
specify-worktree init my-project --worktree

# 使用特定 AI 助手
specify-worktree init my-project --ai claude --worktree

# 在当前目录初始化
specify-worktree init . --worktree --ai claude

# Windows PowerShell 脚本
specify-worktree init my-project --worktree --script ps
```

---

## 🤝 贡献

本项目是 Spec Kit 的独立分支版本，专注于 worktree 功能的增强。

- **上游项目**: [github/spec-kit](https://github.com/github/spec-kit)
- **本仓库**: [YOUR_USERNAME/spec-kit](https://github.com/YOUR_USERNAME/spec-kit)

### 提交 Issue

如果遇到问题，请先确认是否是 worktree 特有的问题：
- **worktree 相关问题** → 在本仓库提交 Issue
- **SDD 方法论问题** → 在官方仓库提交 Issue

---

## 📄 许可证

本项目继承官方 Spec Kit 的 [MIT 许可证](./LICENSE)。

---

## 🙏 致谢

本项目基于 [github/spec-kit](https://github.com/github/spec-kit) 的优秀工作，核心 SDD 方法论和 `/speckit.*` 命令完全来自官方项目。

特别感谢官方团队的：
- John Lam ([@jflam](https://github.com/jflam))
- Den Delimarsky ([@localden](https://github.com/localden))

本版本仅增加 Git Worktree 支持，所有核心功能归功于官方团队。

---

## 📞 支持

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/spec-kit/issues)
- **官方文档**: [spec-kit.github.io](https://github.github.io/spec-kit/)
- **官方 Issues**: [github/spec-kit/issues](https://github.com/github/spec-kit/issues)
