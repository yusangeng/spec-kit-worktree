# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**Spec Kit** 是一个规范驱动开发（Spec-Driven Development, SDD）工具包，它颠覆了传统的软件开发模式，将规范作为核心的可执行产物，而非可抛弃的文档。项目包含以下部分：

1. **Specify CLI** (`src/specify_cli/__init__.py`) - 用于引导 SDD 项目的 Python CLI 工具
2. **模板系统** (`templates/`) - 支持 17+ 种 AI 编码助手的专用模板
3. **斜杠命令** (`templates/commands/`) - 结构化的规范、规划和实现工作流
4. **辅助脚本** (`scripts/`) - 跨平台的 bash/PowerShell 实用工具

## 开发命令

### 安装与测试

```bash
# 本地安装（用于开发）
uv tool install --from git+https://github.com/github/spec-kit.git specify-cli
# 或从源码安装
uv tool install --editable .

# 运行 CLI
specify --help
specify check        # 验证已安装的工具
specify version      # 显示版本信息

# 初始化新项目
specify init my-project --ai claude
specify init . --ai claude  # 在当前目录初始化
```

### 构建与打包

```bash
# 构建 wheel 包
uv build

# 从构建的 wheel 安装
uv pip install dist/specify_cli-*.whl
```

### 模板管理

模板在 `specify init` 期间从 GitHub releases 下载。修改模板时：

1. 更新 `templates/` 中的模板
2. 更新 `pyproject.toml` 中的版本
3. 创建新的 GitHub release 来发布更新的模板

## 架构设计

### 核心组件

**Specify CLI** (`src/specify_cli/__init__.py`):
- 单文件 Python CLI，使用 Typer 构建命令行界面
- Rich 库提供美观的终端 UI 和进度跟踪
- httpx 从 GitHub releases 下载模板
- readchar 实现跨平台键盘输入
- truststore 处理 SSL/TLS 证书

**Agent 配置** (AGENT_CONFIG 字典):
- 支持 17+ 种 AI agent，各有平台特定的约定
- 每个 agent 包含：名称、配置文件夹、安装 URL、CLI 需求标志
- 示例：Claude Code (`.claude/`)、Cursor (`.cursor/`)、GitHub Copilot (`.github/`)

**模板系统**:
- `templates/commands/` - 斜杠命令定义（Markdown with frontmatter）
- `templates/spec-template.md` - 功能规范模板
- `templates/plan-template.md` - 技术实现计划模板
- `templates/tasks-template.md` - 任务分解模板

**辅助脚本** (`scripts/`):
- `create-new-feature.sh` - Git 分支创建，自动编号（###-feature-name）
- `setup-plan.sh` - 特性的环境变量设置
- `check-prerequisites.sh` - 工具验证
- `update-agent-context.sh` - agent 特定的上下文更新
- 跨平台：bash（Linux/macOS）和 PowerShell（Windows）版本

### 斜杠命令工作流

SDD 流程遵循以下阶段（定义在 `templates/commands/` 中）：

1. **`/speckit.constitution`** - 建立项目原则和治理规范
2. **`/speckit.specify`** - 定义功能需求（WHAT 和 WHY，而非 HOW）
3. **`/speckit.clarify`**（可选）- 结构化提问以解决模糊之处
4. **`/speckit.plan`** - 创建技术实现计划和选型
5. **`/speckit.tasks`** - 生成可执行的任务分解
6. **`/speckit.implement`** - 执行实现任务
7. **`/speckit.analyze`**（可选）- 跨制品一致性检查
8. **`/speckit.checklist`**（可选）- 质量验证检查清单

### Git 集成

- 自动创建格式为 `###-feature-name` 的分支（如 `001-photo-albums`）
- 分支编号基于现有分支和 specs 目录自动递增
- 在 `specs/###-feature-name/` 创建特性目录
- `SPECIFY_FEATURE` 环境变量自动设置为当前特性

### 关键设计模式

**模板驱动架构**:
- 从 GitHub releases 动态下载模板
- agent 特定的目录结构和命令格式
- 分支感知的特性检测

**渐进增强**:
- SDD 工作流所需的核心命令
- 可选的质量保证命令（analyze、checklist）
- 灵活的 agent 支持（基于 CLI vs 基于 IDE）

**错误处理**:
- GitHub 速率限制检测，提供用户友好的错误消息
- git 不可用时优雅降级
- 现有项目的模板合并策略

## 使用模板

修改 `templates/commands/` 中的斜杠命令时：

每个命令文件包含：
- **Frontmatter**：`description`、`handoffs`（工作流转换）
- **用户输入部分**：`$ARGUMENTS` 占位符用于用户提示
- **大纲部分**：逐步执行指令
- **模板引用**：依赖模板的路径

Constitution 更新（`/speckit.constitution`）触发一致性传播：
- 更新 `plan-template.md`、`spec-template.md`、`tasks-template.md`
- 验证所有命令文件中的过时引用
- 生成版本升级理由的同步影响报告

## 环境变量

- `SPECIFY_FEATURE` - 覆盖非 Git 仓库的特性检测
- `GH_TOKEN` / `GITHUB_TOKEN` - GitHub API 速率限制的认证
- `CODEX_HOME` - Codex CLI 工作区路径

## 重要说明

- **尚无测试套件** - 需要手动测试
- **需要 Python 3.11+**（使用现代类型提示和标准库特性）
- **uv** 是包管理器（不是 pip/pip-tools）
- **跨平台支持**（Linux、macOS、Windows）
- **Agent 文件夹可能包含凭据** - 用户应添加到 `.gitignore`
- **分支名称限制为 244 字节**（GitHub 约束）
