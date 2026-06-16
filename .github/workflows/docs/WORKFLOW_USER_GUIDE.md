# GitHub Actions Workflow - 用户指南

**工作流文件**：`commercial-build-deploy.yml`
**目标读者**：开发人员、产品经理、最终用户

---

## 1. 工作流简介

### 1.1 这是什么？

这是 RustDesk Pro Server 项目的自动化构建和部署工作流。它能帮助您：

- **自动构建**：推送代码即可自动编译多平台版本
- **自动发布**：推送版本标签即可自动创建发布
- **灵活控制**：可手动触发并自定义构建选项
- **质量保证**：自动运行代码质量检查
- **多架构支持**：同时支持 x86_64、ARM64、ARMv7

### 1.2 适用人群

| 角色 | 使用场景 |
|-----|---------|
| 开发人员 | 提交功能代码、修复 bug、发布新版本 |
| 测试人员 | 验证构建产物、测试新版本 |
| 运维人员 | 部署发布、监控构建状态 |
| 产品经理 | 跟踪发布进度、确认版本 |

---

## 2. 快速开始

### 2.1 自动触发 - 推送分支

**适用场景**：开发新功能、修复 bug

```bash
# 1. 克隆代码库
git clone https://github.com/changsongyang/rustdesk-server.git
cd rustdesk-server

# 2. 创建功能分支
git checkout -b feature/my-new-feature

# 3. 开发并提交
git add .
git commit -m "feat: 添加新功能"

# 4. 推送到远程
git push origin feature/my-new-feature
```

**自动执行**：
- 触发开发构建
- 验证代码质量（Rustfmt、Clippy）
- 构建多平台二进制
- 生成 Debian 包
- 构建 Docker 镜像（基础 + 拓展）
- **不创建** GitHub Release

### 2.2 自动触发 - 推送标签

**适用场景**：发布正式版本到生产环境

```bash
# 1. 确保代码已合并到 main 分支
git checkout main
git pull origin main

# 2. 创建版本标签
git tag pro-v1.0.0

# 3. 推送标签
git push origin pro-v1.0.0
```

**自动执行**：
- 触发生产构建
- 完整构建流程
- 创建 GitHub Release
- 推送 Docker 镜像到 GHCR 和 Docker Hub

### 2.3 手动触发

**适用场景**：自定义构建选项、紧急修复

**步骤**：

1. 打开 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 选择 **Commercial Build and Deploy** 工作流
4. 点击 **Run workflow** 按钮
5. 配置参数（见下表）
6. 点击绿色 **Run workflow** 按钮确认

#### 参数配置说明

| 参数 | 说明 | 选项 | 默认值 |
|-----|------|------|--------|
| **触发类型** (trigger_type) | 选择触发方式 | `branch_with_version` / `branch_no_version` / `tag` | 必选 |
| **版本号** (version) | 手动指定版本号 | 任意字符串 | 条件必填 |
| **Git 标签** (git_tag) | 选择已有标签 | 任意标签 | 条件必填 |
| **构建 DEB 包** (build_deb) | 是否构建 Debian 包 | `true` / `false` | `true` |
| **构建 Docker 镜像** (build_docker) | 是否构建 Docker 镜像 | `true` / `false` | `true` |
| **Docker 镜像类型** (docker_image_type) | 镜像类型 | `both` / `base` / `extended` | `both` |

#### 手动触发场景示例

**场景 1：开发构建（不部署）**
- trigger_type: `branch_no_version`
- build_deb: `false`
- build_docker: `false`

**场景 2：生产构建（带版本号）**
- trigger_type: `branch_with_version`
- version: `v1.2.3`
- build_deb: `true`
- build_docker: `true`
- docker_image_type: `both`

**场景 3：仅构建基础镜像**
- trigger_type: `tag`
- git_tag: `pro-v1.0.0`
- build_deb: `true`
- build_docker: `true`
- docker_image_type: `base`

---

## 3. 输入要求

### 3.1 自动触发 - 不需要输入

推送分支或标签即可自动触发。

### 3.2 手动触发 - 输入参数

#### 必填参数

| 参数 | 何时必填 | 说明 |
|-----|---------|------|
| trigger_type | 始终必填 | 选择触发类型 |
| version | 当选择 branch_with_version 时 | 提供版本号 |
| git_tag | 当选择 tag 时 | 选择已有标签 |

#### 可选参数

| 参数 | 默认值 | 说明 |
|-----|-------|------|
| build_deb | true | 是否构建 Debian 包 |
| build_docker | true | 是否构建 Docker 镜像 |
| docker_image_type | both | 镜像类型 |

---

## 4. 预期输出

### 4.1 自动化产物

工作流运行成功后，会生成以下产物：

#### 二进制文件

| 平台 | 架构 | 格式 |
|-----|------|------|
| Linux | x86_64 | ELF 可执行文件 |
| Linux | ARM64 (aarch64) | ELF 可执行文件 |
| Linux | ARMv7 | ELF 可执行文件 |
| Windows | x86_64 | PE 可执行文件 |

#### Debian 包

| 包名 | 架构 |
|-----|------|
| rustdesk-pro-server_1.0.0_amd64.deb | x86_64 |
| rustdesk-pro-server_1.0.0_arm64.deb | ARM64 |
| rustdesk-pro-server_1.0.0_armhf.deb | ARMv7 |

#### Docker 镜像

| 类型 | 标签格式 | 用途 |
|-----|---------|------|
| 基础镜像 | `{tag}-{arch}` | 标准部署 |
| 拓展镜像 | `{tag}-extended-{arch}` | 高级功能 |

#### GitHub Release（仅生产构建）

- 包含所有二进制和 Debian 包
- 自动生成发布说明
- 标记为 Latest Release

### 4.2 如何下载产物

#### 方式 1：GitHub Artifacts

1. 打开工作流运行页面
2. 滚动到底部的 **Artifacts** 部分
3. 点击下载对应的 artifact

#### 方式 2：GitHub Release

1. 打开仓库的 **Releases** 页面
2. 选择对应的版本
3. 在 **Assets** 中下载文件

#### 方式 3：Docker 镜像

```bash
# 拉取基础镜像
docker pull ghcr.io/changsongyang/rustdesk-pro-server:v1.0.0-amd64

# 拉取拓展镜像
docker pull ghcr.io/changsongyang/rustdesk-pro-server:v1.0.0-extended-amd64
```

---

## 5. 构建状态追踪

### 5.1 查看构建进度

1. 进入 GitHub 仓库的 **Actions** 页面
2. 选择 **Commercial Build and Deploy** 工作流
3. 点击最新的运行记录
4. 查看各个任务的执行状态：
   - ✅ 绿色：成功
   - ❌ 红色：失败
   - 🟡 黄色：运行中
   - ⚪ 灰色：跳过

### 5.2 关键检查点

| 阶段 | 状态 | 含义 |
|-----|------|------|
| P1 - Pre-Build | 准备 | 准备构建环境和参数 |
| P2 - Code Quality | 检查 | 代码质量验证 |
| P3 - Build | 构建 | 编译二进制 |
| P4 - Build Summary | 汇总 | 验证产物 |
| P5 - Debian | 产物 | 生成 DEB 包 |
| P6 - GitHub Release | 发布 | 创建发布 |
| P7 - Docker | 产物 | 构建 Docker 镜像 |
| P9 - Deploy | 部署 | 最终汇总 |

### 5.3 接收通知

**配置通知**：
1. 进入仓库的 **Settings** -> **Notifications**
2. 选择 **Actions** 类别
3. 启用邮件或 webhook 通知

---

## 6. 最佳实践

### 6.1 版本号管理

**遵循语义化版本（SemVer）**：

| 格式 | 用途 | 示例 |
|-----|------|------|
| `MAJOR.MINOR.PATCH` | 稳定版本 | `1.0.0` |
| `MAJOR.MINOR.PATCH-rc.N` | 预发布版本 | `1.0.0-rc.1` |
| `MAJOR.MINOR.PATCH-beta.N` | Beta 版本 | `1.0.0-beta.1` |

**推荐**：
- ✅ `pro-v1.0.0` - 主要发布
- ✅ `pro-v1.0.1` - 紧急修复
- ✅ `pro-v1.1.0-rc.1` - 候选发布
- ❌ `v1.0` - 缺少 patch 号
- ❌ `1.0.0` - 缺少 `pro-` 前缀

### 6.2 提交信息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```bash
# 功能
git commit -m "feat: 添加用户认证功能"

# 修复
git commit -m "fix: 修复连接超时问题"

# 文档
git commit -m "docs: 更新 README"

# 重构
git commit -m "refactor: 优化数据库查询"

# 测试
git commit -m "test: 添加单元测试"
```

### 6.3 分支命名规范

| 类型 | 命名格式 | 示例 |
|-----|---------|------|
| 功能 | `feature/*` 或 `feat/*` | `feature/user-auth` |
| 修复 | `fix/*` 或 `bugfix/*` | `fix/connection-timeout` |
| 热修复 | `hotfix/*` | `hotfix/security-patch` |
| 发布 | `release/*` | `release/v1.0.0` |
| 个人 | `dev/*` 或 `wip/*` | `dev/john-experiment` |

### 6.4 推送前检查

在推送代码前，请确保：

- [ ] 代码已通过本地 `cargo build`
- [ ] 代码已通过 `cargo fmt --check`
- [ ] 代码已通过 `cargo clippy`
- [ ] 单元测试通过 `cargo test`
- [ ] 提交信息符合规范
- [ ] 没有提交敏感信息（密码、密钥）

### 6.5 故障排除快速参考

| 问题 | 解决方案 |
|-----|---------|
| 工作流未触发 | 检查分支名是否匹配触发器配置 |
| 代码质量检查失败 | 本地运行 `cargo fmt` 和 `cargo clippy` 修复 |
| 构建失败 | 查看日志中的编译错误 |
| 镜像推送失败 | 联系管理员检查 Registry 凭证 |
| 版本号错误 | 确保使用 `pro-v*` 格式 |

---

## 7. 常见问题解答 (FAQ)

### Q1: 如何发布新版本？

**A**: 推送以 `pro-v` 开头的标签即可触发自动发布：

```bash
git tag pro-v1.0.0
git push origin pro-v1.0.0
```

### Q2: 如何只构建特定平台？

**A**: 使用手动触发，并通过参数控制：

1. 选择 **Run workflow**
2. 设置 `trigger_type: branch_no_version`
3. 设置 `build_docker: true`
4. 设置 `docker_image_type: base`（或 `extended`）

### Q3: 如何查看历史构建记录？

**A**: 进入 **Actions** 标签页，可以查看所有历史运行记录。

### Q4: 推送后多久能看到结果？

**A**:
- 代码质量检查：1-3 分钟
- 完整构建：30-40 分钟
- 总计：约 40-50 分钟

### Q5: 失败后如何重试？

**A**:
1. 打开失败的工作流运行
2. 点击右上角的 **Re-run jobs** 按钮
3. 选择 **Re-run failed jobs** 或 **Re-run all jobs**

### Q6: 能否跳过代码质量检查？

**A**: 不推荐跳过。但紧急情况下可以：
1. 使用手动触发
2. 在 code-quality 步骤中设置 `continue-on-error: true`

### Q7: Docker 镜像推送到哪里？

**A**: 推送到两个 Registry：
- **GitHub Container Registry (GHCR)**：`ghcr.io/changsongyang/rustdesk-pro-server`
- **Docker Hub**：`docker.io/changsongyang/rustdesk-pro-server`

### Q8: 如何下载构建产物？

**A**: 三种方式：
1. **Artifacts**：在工作流运行页面下载
2. **Releases**：在 Releases 页面下载（仅生产构建）
3. **Docker**：使用 `docker pull` 命令

### Q9: 支持哪些 Linux 发行版？

**A**: 
- 构建环境：Ubuntu 22.04
- 目标平台：musl libc（静态链接，可在大多数 Linux 发行版运行）

### Q10: 如何联系支持？

**A**: 
- 在仓库创建 Issue
- 联系 DevOps 团队
- 查看 [运维文档](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/docs/WORKFLOW_OPERATIONS.md) 获取详细信息

---

## 8. 附录

### 8.1 完整触发器配置

| 触发方式 | 分支/标签 | 构建类型 | 部署 |
|---------|---------|---------|------|
| 推送分支 | main, master, develop, development | 开发 | ❌ |
| 推送分支 | feature/**, feat/** | 开发 | ❌ |
| 推送分支 | fix/**, bugfix/**, hotfix/** | 开发 | ❌ |
| 推送分支 | release/**, dev/**, wip/** | 开发 | ❌ |
| 推送标签 | pro-v*, pro-* | 生产 | ✅ |
| 手动触发 | 任意（自定义） | 自定义 | 自定义 |

### 8.2 快速命令参考

```bash
# 推送开发代码
git push origin feature/my-feature

# 推送修复
git push origin fix/bug-name

# 创建并推送版本标签
git tag pro-v1.0.0 && git push origin pro-v1.0.0

# 查看所有标签
git tag -l "pro-v*"

# 删除远程标签
git push origin --delete pro-v1.0.0
```

### 8.3 相关文档链接

- [实现文档](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/docs/WORKFLOW_IMPLEMENTATION.md)
- [运维文档](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/docs/WORKFLOW_OPERATIONS.md)
- [GitHub Actions 官方文档](https://docs.github.com/en/actions)

---

**最后更新**：2026-06-16
**文档版本**：v1.0
**维护者**：DevOps 团队
