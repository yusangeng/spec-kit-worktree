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
  开发 feature-1 → git checkout feature-2 → 开发 → git checkout feature-1
  (来回切换，容易忘记改了什么)

Worktree版本：并行开发，无需切换
  终端1: .wt/feature-1/  → 开发特性1（始终保持在这个分支）
  终端2: .wt/feature-2/  → 开发特性2（始终保持在这个分支）
  (同时进行，各自独立，互不干扰)
```

### 关于 Spec Kit

Spec Kit 是一个**规范驱动开发（Spec-Driven Development）**工具包。核心思想是：

- 先明确 **做什么（WHAT）** 和 **为什么（WHY）**
- 再考虑 **怎么做（HOW）**
- 通过 `/speckit.*` 斜杠命令，结构化地完成开发流程

详细文档：[官方 Spec Kit 文档](https://github.github.io/spec-kit/)

---

## 🎯 这个版本多了什么功能？

### ✨ 新增功能：自动管理 Worktree

当你使用 `/speckit.specify` 创建新特性时，本版本会**自动**创建独立的 Worktree 目录：

```
你只需要：
  /speckit.specify 添加用户登录功能

AI 助手自动做：
  1. 创建 .wt/user-login/ 目录
  2. 创建 feature/user-login 分支
  3. 在 worktree 中创建规范文件
  4. 进入 worktree 目录开始工作

结果：
  - 你可以在 .wt/user-login/ 中开发
  - 主分支保持干净
  - 可以同时开发多个特性（多个终端，多个 worktree）
```

### 与官方版本的对比

| 场景 | 官方 Spec Kit | Spec Kit Worktree |
|------|--------------|-------------------|
| 创建特性 | `/speckit.specify` → 创建分支 | `/speckit.specify` → **自动创建 worktree** |
| 开发特性 A | 在主分支开发，频繁 checkout | 在 `.wt/feature-a/` 开发，无需切换 |
| 同时开发特性 B | 需要先 checkout 到 B 分支 | 打开新终端，在 `.wt/feature-b/` 开发 |
| 切换上下文 | `git checkout`（可能丢失未提交的修改） | `cd .wt/feature-b/`（各自独立，不影响） |

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

### 第 3 步：启动 AI 助手

```bash
cd my-project
# 启动 Claude Code（或其他支持的 AI 助手）
```

### 第 4 步：创建第一个特性（自动创建 Worktree）

在 AI 助手中输入：

```
/speckit.specify 添加用户登录功能，包括邮箱登录和注册
```

**AI 助手会自动：**
1. ✅ 创建 `.wt/user-login/` 目录
2. ✅ 创建 `feature/user-login` 分支
3. ✅ 在 worktree 中创建规范文件
4. ✅ 进入 worktree 目录

你现在可以在 `.wt/user-login/` 中开发了！

### 第 5 步：并行开发多个特性

打开多个终端窗口，**每个窗口开发一个特性**：

```
终端1：
  cd my-project  （如果是新终端）
  /speckit.specify 添加用户认证功能
  → AI 自动创建 .wt/user-auth/，你在这里开发

终端2：（不关闭终端1）
  cd my-project  （如果是新终端）
  /speckit.specify 添加支付功能
  → AI 自动创建 .wt/payment/，你在这里开发

终端3：（继续）
  cd my-project
  /speckit.specify 添加通知系统
  → AI 自动创建 .wt/notification/，你在这里开发

三个特性完全独立，互不干扰！
```

### 第 6 步：继续 SDD 流程

在 AI 助手中继续使用命令：

```
/speckit.plan       # 创建技术方案
/speckit.tasks      # 生成任务列表
/speckit.implement  # 执行实现
```

所有操作都在当前 worktree 中进行，无需手动切换分支。

---

## 🔧 常用命令

### CLI 命令

```bash
# 初始化项目（启用 worktree）
specify-worktree init <project-name> --worktree --ai claude

# 在当前目录初始化
specify-worktree init . --worktree

# 检查工具
specify-worktree check
```

### Slash 命令（在 AI 助手中使用）

```
/speckit.constitution  - 建立项目原则
/speckit.specify       - 定义功能需求（会自动创建 worktree）
/speckit.plan          - 创建技术方案
/speckit.tasks         - 生成任务列表
/speckit.implement     - 执行实现
```

**重要**：你只需要使用这些 `/speckit.*` 命令，worktree 的创建和管理都是自动的！

---

## 💡 使用场景

### 适合使用本版本

✅ **同时开发多个特性** - 如用户认证 + 支付 + 通知
✅ **大型项目** - 切换分支成本高
✅ **频繁上下文切换** - 需要在不同特性间快速切换
✅ **团队协作** - 多人同时开发，减少分支冲突

### 典型工作流程

```
早上：
  /speckit.specify 实现用户认证
  → 在 .wt/user-auth/ 开发

下午：
  需要紧急修复另一个问题，打开新终端
  /speckit.specify 修复支付页面bug
  → 在 .wt/fix-payment/ 开发
  → user-auth 的修改不受影响（在不同目录）

晚上：
  继续开发用户认证
  cd .wt/user-auth
  → 所有修改都还在，没有冲突
```

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

本版本仅增加 Git Worktree 自动化管理，所有核心功能归功于官方团队。

---

## 📞 支持

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/spec-kit/issues)
- **官方文档**: [spec-kit.github.io](https://github.github.io/spec-kit/)
