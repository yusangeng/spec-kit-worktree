# Speckit 开发规范

## 1. 目录结构规范

工作树模式下的规范文档存放在 `.wt/{特性名称}/specs/` 目录中：

```
.wt/{特性名称}/specs/
└── FS-{编号}-{领域}-{特性}-v{版本}/
    ├── spec.md          # 功能规范 (WHAT & WHY)
    ├── plan.md          # 技术实现计划 (HOW)
    ├── tasks.md         # 任务分解
    ├── research.md      # 研究文档 (可选)
    ├── data-model.md    # 数据模型 (可选)
    ├── .metadata        # 元数据文件
    └── contracts/       # 接口契约 (可选)
        ├── api-spec.md
        └── signalr-spec.md
```

**目录说明**：
- `.wt/` - 工作树根目录，所有特性分支的工作树都在这里
- `{特性名称}` - 特性的短名称（kebab-case格式）
- `specs/` - 规范文档目录
- `FS-{编号}-{领域}-{特性}-v{版本}/` - 特性规范目录

## 2. 文件命名规则

规范目录命名遵循以下格式：

```
FS-{编号}-{领域}-{特性}-v{版本}
```

**组成部分**：
- `{编号}`：四位数字 (0001, 0002, 0003...)
- `{领域}`：中文业务领域（组织管理域、绩效管理域、系统管理域等）
- `{特性}`：英文短名称（2-4个单词，kebab-case，如 photo-albums）
- `{版本}`：语义版本号 (v1, v2, v3...)

**示例**：
```
FS-0001-组织管理域-user-management-v1/
FS-0002-绩效管理域-performance-review-v1/
FS-0003-系统管理域-system-config-v1/
```

## 3. 测试规范

### 单元测试
- **存放位置**：`tests/unit/{源文件名}.test.{扩展名}`
- **覆盖率要求**：分支覆盖率 ≥ 90%
- **必须覆盖场景**：
  - 正常场景（预期行为）
  - 异常场景（参数无效、权限不足等）
  - 边界场景（空值、极值等）

### 集成测试
- **存放位置**：`tests/integration/{用户故事名}.test.{扩展名}`
- **覆盖要求**：
  - 必须覆盖所有功能点
  - 必须覆盖所有异常场景
  - 如果使用 speckit，每个 User Story 对应一个集成测试文件

## 4. Git 提交格式

提交信息遵循以下格式：

```
[{类型}]: {描述} (关联 #{issue_id})
```

**类型（type）**：
- `feat` - 新功能
- `fix` - Bug 修复
- `docs` - 文档更新
- `refactor` - 代码重构
- `test` - 测试相关
- `chore` - 构建/工具相关

**示例**：
```
[feat]: 添加用户认证功能 (关联 #123)
[fix]: 修复登录状态过期问题 (关联 #456)
[docs]: 更新 API 文档 (关联 #789)
```

## 5. 特性编号自动生成

使用以下命令自动获取下一个可用的特性编号：

```bash
find .wt -type d -name "FS-*" | sed 's/.*FS-\([0-9]*\).*/\1/' | sort -n | tail -1
```

**工作原理**：
1. 查找所有 `FS-*` 开头的目录
2. 提取编号部分（4位数字）
3. 按数字排序
4. 取最大值 + 1 作为下一个编号

## 6. 元数据文件格式

每个规范目录包含 `.metadata` 文件，格式如下：

```yaml
number: {编号}
domain: {领域}
feature: {特性}
version: v1
created: {创建时间}
```

**示例**：
```yaml
number: 0001
domain: 组织管理域
feature: user-management
version: v1
created: 2026-02-02T10:30:00+08:00
```

**生成命令**：
```bash
cat > .metadata << EOF
number: 0001
domain: 组织管理域
feature: user-management
version: v1
created: $(date -I)
EOF
```

## 7. 工作目录管理

### 路径变量定义

```bash
# 仓库根目录（自动检测）
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# 特性短名称
FEATURE_SHORT_NAME="{kebab-case name}"  # 例如: user-management

# 业务领域
DOMAIN="{业务域}"  # 例如: 组织管理域

# 工作树目录
WORKTREE_DIR="$REPO_ROOT/.wt/$FEATURE_SHORT_NAME"

# 特性规范目录
FEATURE_DIR="$WORKTREE_DIR/specs/FS-{编号}-${DOMAIN}-${FEATURE_SHORT_NAME}-v1"
```

### Worktree 创建和切换

```bash
# 1. 创建 worktree（使用 bash 脚本）
.specify/scripts/bash/create-worktree.sh $FEATURE_SHORT_NAME

# 2. 验证 worktree 是否创建成功
if [[ ! -d "$WORKTREE_DIR" ]]; then
  echo "错误：Worktree 创建失败"
  exit 1
fi

# 3. 切换到 worktree 目录
cd "$WORKTREE_DIR" || exit 1
echo "✓ 已切换到 worktree: $(pwd)"
```

### 辅助函数参考

#### 自动检测和切换到 Worktree
```bash
function detect_worktree() {
  local repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  local current_dir="$(pwd)"

  # 检查是否在 worktree 中
  if [[ "$current_dir" == "$repo_root/.wt/"* ]]; then
    # 在 worktree 中，提取特性名称
    local feature_name="$(echo "$current_dir" | sed "s|$repo_root/.wt/||" | cut -d'/' -f1)"
    echo "$feature_name"
    return 0
  else
    # 不在 worktree 中
    return 1
  fi
}
```

#### 特性编号检测
```bash
function get_next_feature_number() {
  local repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  local last_number=$(find "$repo_root/.wt" -type d -name "FS-*" 2>/dev/null | \
    sed 's/.*FS-\([0-9]*\).*/\1/' | sort -n | tail -1)

  if [[ -z "$last_number" ]]; then
    echo "0001"
  else
    printf "%04d" $((10#$last_number + 1))
  fi
}
```

#### Worktree 检测
```bash
function is_worktree_mode() {
  local repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  local marker_file="$repo_root/.specify/worktree-mode"
  [[ -f "$marker_file" ]]
}
```

#### 特性目录检测
```bash
function get_feature_dir() {
  local feature_number="$1"
  local domain="$2"
  local feature_name="$3"
  local repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  echo "$repo_root/.wt/$feature_name/specs/FS-${feature_number}-${domain}-${feature_name}-v1"
}
```

## 8. 工作流最佳实践

### 8.1 开始新特性开发

```bash
# 1. 获取下一个特性编号
FEATURE_NUMBER=$(get_next_feature_number)

# 2. 定义元数据
DOMAIN="组织管理域"
FEATURE_SHORT_NAME="user-management"

# 3. 创建 worktree
.specify/scripts/bash/create-worktree.sh $FEATURE_SHORT_NAME

# 4. 切换到 worktree
cd "$(git rev-parse --show-toplevel)/.wt/$FEATURE_SHORT_NAME"

# 5. 创建规范目录
FEATURE_DIR="specs/FS-${FEATURE_NUMBER}-${DOMAIN}-${FEATURE_SHORT_NAME}-v1"
mkdir -p "$FEATURE_DIR"

# 6. 创建元数据文件
cat > "$FEATURE_DIR/.metadata" << EOF
number: ${FEATURE_NUMBER}
domain: ${DOMAIN}
feature: ${FEATURE_SHORT_NAME}
version: v1
created: $(date -I)
EOF

# 7. 开始使用 speckit 工作流
/speckit.specify
```

### 8.2 规范文件创建顺序

1. **spec.md** - 使用 `/speckit.specify` 创建
   - 定义功能需求（WHAT & WHY）
   - 不涉及实现细节（HOW）

2. **plan.md** - 使用 `/speckit.plan` 创建
   - 定义技术实现方案
   - 包含架构设计和选型

3. **tasks.md** - 使用 `/speckit.tasks` 创建
   - 分解为可执行的任务
   - 包含验收标准

4. **contracts/** - 根据需要创建
   - API 契约定义
   - 事件/信号契约定义

### 8.3 代码实现流程

```bash
# 1. 编写单元测试（TDD）
# 2. 实现功能代码
# 3. 运行单元测试（覆盖率 ≥ 90%）
# 4. 编写集成测试
# 5. 运行集成测试
# 6. 提交代码（遵循提交格式）
```

## 9. 常用命令速查

```bash
# 检测是否在 worktree 中
detect_worktree

# 获取下一个特性编号
get_next_feature_number

# 列出所有 worktree
git worktree list

# 切换到特定 worktree
cd $(git rev-parse --show-toplevel)/.wt/{feature-name}

# 创建新的 worktree
.specify/scripts/bash/create-worktree.sh {feature-name}

# 删除 worktree
.specify/scripts/bash/remove-worktree.sh {feature-name}
```

## 10. 注意事项

1. **特性编号唯一性**：在整个仓库中保持唯一，不要重复使用已删除的编号
2. **目录命名一致性**：使用统一的命名格式，便于脚本自动处理
3. **测试覆盖率**：严格遵循 90% 分支覆盖率要求
4. **提交信息规范**：使用标准格式，便于追溯和生成变更日志
5. **元数据维护**：每次创建规范目录时，同步更新 `.metadata` 文件
6. **工作树隔离**：每个特性在独立的 worktree 中开发，避免相互干扰
