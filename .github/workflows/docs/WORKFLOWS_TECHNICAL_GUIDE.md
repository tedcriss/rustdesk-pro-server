# GitHub Actions 工作流技术文档

**文档版本**：v1.0
**最后更新**：2026-06-16
**目标读者**：开发团队、DevOps 工程师

---

## 目录

1. [工作流总览](#1-工作流总览)
2. [commercial-ci.yml - 持续集成](#2-commercial-ciyml---持续集成)
3. [commercial-security.yml - 安全扫描](#3-commercial-securityyml---安全扫描)
4. [commercial-build.yml - 商业版构建](#4-commercial-buildyml---商业版构建)
5. [commercial-cd.yml - 持续部署](#5-commercial-cdyml---持续部署)
6. [工作流对比与协作关系](#6-工作流对比与协作关系)
7. [常见问题排查](#7-常见问题排查)

---

## 1. 工作流总览

### 1.1 工作流清单

| 工作流文件 | 名称 | 职责 | 触发时机 |
|----------|------|------|---------|
| [commercial-ci.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-ci.yml) | CI | 代码质量检查、单元测试、编译验证 | push to main/develop, PR |
| [commercial-security.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-security.yml) | Security | 依赖漏洞、代码安全、容器扫描、密钥检测 | 每周定时、push to main、手动 |
| [commercial-build.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-build.yml) | Commercial Build | 多平台编译、DEB 打包、Release | push to main、pro-v* 标签、手动 |
| [commercial-cd.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-cd.yml) | CD | Docker 镜像构建推送、多架构 Manifest、SBOM | push to main、pro-v* 标签、手动 |

### 1.2 工作流架构图

```
┌────────────────────────────────────────────────────────────────┐
│                  RustDesk Pro CI/CD 架构                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │   CI (持续集成)   │    │ Security (安全) │                   │
│  │   commercial-ci   │    │ commercial-sec  │                   │
│  │                  │    │                 │                   │
│  │ • Rustfmt        │    │ • Cargo Audit   │                   │
│  │ • Clippy         │    │ • Trivy Scan    │                   │
│  │ • Unit Test      │    │ • CodeQL        │                   │
│  │ • Build Verify   │    │ • Gitleaks      │                   │
│  └────────┬─────────┘    └────────┬────────┘                   │
│           │                       │                            │
│           ▼                       ▼                            │
│  ┌─────────────────────────────────────────┐                  │
│  │       Build (商业版构建)                  │                  │
│  │       commercial-build                   │                  │
│  │                                          │                  │
│  │ • Linux 多架构编译                       │                  │
│  │ • Windows 编译                            │                  │
│  │ • DEB 包构建                              │                  │
│  │ • GitHub Release                          │                  │
│  └────────┬─────────────────────────────────┘                  │
│           │                                                    │
│           │ artifacts: binaries-linux-*, binaries-windows-*  │
│           ▼                                                    │
│  ┌─────────────────────────────────────────┐                  │
│  │       CD (持续部署)                       │                  │
│  │       commercial-cd                      │                  │
│  │                                          │                  │
│  │ • Docker 镜像构建（多架构）              │                  │
│  │ • 多架构 Manifest                        │                  │
│  │ • SBOM 生成                               │                  │
│  │ • Release + docker-compose 更新          │                  │
│  └─────────────────────────────────────────┘                  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 2. commercial-ci.yml - 持续集成

**文件**：[commercial-ci.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-ci.yml)

### 2.1 功能概述

该工作流负责 RustDesk Pro Server 的持续集成验证，主要包括：

- **代码格式化检查**：使用 `cargo fmt --check`
- **静态分析**：使用 Clippy 进行 Lint 检查
- **单元测试**：运行项目测试套件
- **编译验证**：在多个目标平台上验证项目可编译

### 2.2 触发条件

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:
```

| 触发方式 | 条件 | 说明 |
|---------|------|------|
| push | 推送到 main 或 develop | 验证主分支和开发分支 |
| pull_request | 针对 main 或 develop | 验证 PR 合并前 |
| workflow_dispatch | 手动触发 | 通过 GitHub UI 手动运行 |

### 2.3 执行步骤

工作流包含 5 个任务：

| 任务 | 名称 | 职责 | 依赖 |
|-----|------|------|------|
| P1 | `[P1] Rustfmt` | 检查代码格式 | 无 |
| P2 | `[P2] Clippy` | 静态分析 Lint | 无 |
| P3 | `[P3] Test Suite` | 运行单元测试 | 无 |
| P4 | `[P4] Build (${{ matrix.target }})` | 多目标编译验证 | 无 |
| P5 | `[P5] CI Summary` | 汇总所有任务状态 | P1, P2, P3, P4 |

### 2.4 环境配置

```yaml
env:
  CARGO_TERM_COLOR: always    # 彩色输出
  RUST_BACKTRACE: 1          # 启用栈回溯
```

**Runner 要求**：
- 操作系统：`ubuntu-latest`
- Rust 工具链：`stable`（由 `dtolnay/rust-toolchain` 安装）
- 缓存：使用 `Swatinem/rust-cache@v2`

### 2.5 关键参数

#### 编译矩阵

```yaml
matrix:
  target:
    - x86_64-unknown-linux-gnu
    - x86_64-unknown-linux-musl
```

| Target | 用途 | 特殊配置 |
|--------|------|---------|
| `x86_64-unknown-linux-gnu` | 标准 glibc 链接 | 默认配置 |
| `x86_64-unknown-linux-musl` | 静态 musl 链接 | 需要 `musl-tools` |

#### 任务参数

| 任务 | 关键参数 | 说明 |
|-----|---------|------|
| fmt | components: rustfmt | 仅安装 rustfmt 组件 |
| clippy | `--all-targets --no-deps -D warnings` | 检查所有目标，将警告视为错误 |
| test | `DATABASE_URL: "sqlite::memory:"` | 使用内存数据库 |
| build | max-parallel: 5 | 最多 5 个并行编译任务 |

### 2.6 依赖关系

```
P1 (fmt) ─────┐
P2 (clippy) ──┤
P3 (test) ────┼──→ P5 (summary)
P4 (build) ───┘
```

**P1-P4 完全并行执行**，P5 等待所有前置任务完成。

### 2.7 常见问题

#### Q: fmt 任务失败
**原因**：代码格式不符合 Rustfmt 标准  
**解决**：本地运行 `cargo fmt` 修复

#### Q: clippy 任务失败
**原因**：存在 Clippy 警告（视为错误）  
**解决**：本地运行 `cargo clippy --fix` 自动修复

#### Q: test 任务失败
**原因**：单元测试失败  
**解决**：本地运行 `cargo test` 调试

#### Q: 编译验证失败
**原因**：在某个目标上无法编译  
**解决**：检查目标平台特定的依赖

### 2.8 使用示例

```bash
# 推送代码触发 CI
git push origin main

# 创建 PR 触发 CI
gh pr create --base main --head feature/new-feature

# 手动触发 CI
gh workflow run "CI" --ref main
```

---

## 3. commercial-security.yml - 安全扫描

**文件**：[commercial-security.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-security.yml)

### 3.1 功能概述

该工作流执行全面的安全扫描，包括：

- **Cargo 依赖漏洞扫描**：使用 `cargo audit`
- **文件系统漏洞扫描**：使用 Trivy
- **代码安全分析**：使用 CodeQL
- **密钥扫描**：使用 Gitleaks
- **安全报告汇总**

### 3.2 触发条件

```yaml
on:
  schedule:
    - cron: '0 0 * * 0'    # 每周日凌晨 0 点
  push:
    branches: [main]
  workflow_dispatch:
```

| 触发方式 | 条件 | 频率 |
|---------|------|------|
| 定时 | 每周日凌晨 | 每周一次 |
| push | 推送到 main 分支 | 每次推送 |
| 手动 | workflow_dispatch | 按需 |

### 3.3 执行步骤

| 任务 | 名称 | 职责 | 工具 |
|-----|------|------|------|
| 1 | Cargo Audit | 依赖漏洞扫描 | cargo-audit |
| 2 | Trivy Vulnerability Scan | 文件系统扫描 | Trivy |
| 3 | CodeQL Analysis | 代码安全分析 | CodeQL |
| 4 | Secret Detection | 密钥扫描 | Gitleaks |
| 5 | Security Summary | 汇总报告 | - |

### 3.4 环境配置

```yaml
permissions:
  security-events: write    # 写入安全事件
  contents: read             # 读取仓库内容
```

**Runner 要求**：
- 操作系统：`ubuntu-latest`

### 3.5 关键参数

#### Cargo Audit 配置

```bash
cargo audit --ignore RUSTSEC-2023-0071 \
            --ignore RUSTSEC-2025-0040 \
            --ignore RUSTSEC-2021-0139 \
            --ignore RUSTSEC-2024-0375 \
            --ignore RUSTSEC-2023-0051 \
            --ignore RUSTSEC-2021-0137 \
            --ignore RUSTSEC-2023-0040 \
            --ignore RUSTSEC-2021-0145 \
            --ignore RUSTSEC-2023-0059
```

**说明**：忽略已知的、不会影响项目或无法立即修复的漏洞。

#### Trivy 配置

```yaml
scan-type: 'fs'              # 文件系统扫描
scan-ref: './commercial'     # 扫描目录
format: 'sarif'              # SARIF 格式输出
output: 'trivy-results.sarif'
```

#### CodeQL 配置

```yaml
languages: rust              # Rust 语言分析
category: "/language:rust"   # 分类标签
```

#### Gitleaks 配置

```yaml
config-path: .gitleaks.toml  # 自定义配置
redact: true                 # 隐藏敏感信息
```

### 3.6 依赖关系

```
cargo-audit ─────┐
trivy-scan ──────┤
codeql ──────────┼──→ security-summary
secret-scan ─────┘
```

**前 4 个任务完全并行执行**，汇总任务等待所有扫描完成。

### 3.7 常见问题

#### Q: cargo-audit 报告漏洞
**解决**：
1. 评估漏洞影响
2. 更新到修复版本
3. 或使用 `--ignore` 参数临时忽略（如本工作流所示）

#### Q: Trivy 扫描失败
**解决**：检查 SARIF 输出文件，调整扫描配置

#### Q: Gitleaks 误报
**解决**：在 `.gitleaks.toml` 中添加白名单规则

### 3.8 使用示例

```bash
# 手动触发安全扫描
gh workflow run "Security"

# 查看 SARIF 报告
gh workflow run "Security" --ref main
# 下载 trivy-results.sarif 并用 VS Code SARIF Viewer 查看
```

---

## 4. commercial-build.yml - 商业版构建

**文件**：[commercial-build.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-build.yml)

### 4.1 功能概述

该工作流负责商业版的完整构建和发布，包括：

- **多平台编译**：Linux (amd64, arm64v8, armv7) + Windows
- **跨平台编译**：使用 `cross` 工具
- **Debian 包构建**：多架构 DEB 包
- **GitHub Release**：统一发布所有产物

### 4.2 触发条件

```yaml
on:
  workflow_dispatch:
    inputs:
      version:
        description: '版本号 (e.g., pro-v1.0.0)'
        required: false
        type: string
      platforms:
        description: '构建平台 (逗号分隔: amd64,arm64v8,armv7,windows)'
        required: false
        type: string
        default: 'amd64,arm64v8,armv7,windows'
  push:
    branches: [main]
    tags:
      - 'pro-v[0-9]+.[0-9]+.[0-9]+'
      - 'pro-[0-9]+.[0-9]+.[0-9]+'
      - 'pro-v[0-9]+.[0-9]+.[0-9]+-[0-9]+'
      - 'pro-[0-9]+.[0-9]+.[0-9]+-[0-9]+'
```

| 触发方式 | 条件 |
|---------|------|
| 手动触发 | workflow_dispatch，可指定 version 和 platforms |
| 推送到 main 分支 | 自动构建 |
| 推送 pro-v* 标签 | 完整发布流程 |

### 4.3 执行步骤

| 任务 | 名称 | 职责 | 依赖 | 触发条件 |
|-----|------|------|------|---------|
| build | Build (matrix) | Linux 多架构编译 | 无 | 始终 |
| build-win | Build - windows | Windows 编译 | 无 | 始终 |
| deb-package | debian package (matrix) | DEB 包构建 | build | 标签推送 |
| release | Github release | 创建 Release | build, build-win, deb-package | 标签推送 |

### 4.4 环境配置

```yaml
permissions:
  contents: write
  packages: write
  id-token: write

env:
  CARGO_TERM_COLOR: always
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
```

### 4.5 关键参数

#### Linux 编译矩阵

```yaml
matrix:
  job:
    - { name: "amd64",   target: "x86_64-unknown-linux-musl" }
    - { name: "arm64v8", target: "aarch64-unknown-linux-musl" }
    - { name: "armv7",   target: "armv7-unknown-linux-musleabihf" }
```

#### DEB 包构建矩阵

```yaml
matrix:
  job:
    - { name: "amd64",   debian_platform: "amd64",   crossbuild_package: "" }
    - { name: "arm64v8", debian_platform: "arm64",   crossbuild_package: "crossbuild-essential-arm64" }
    - { name: "armv7",   debian_platform: "armhf",   crossbuild_package: "crossbuild-essential-armhf" }
```

#### cross 工具链环境

```yaml
env:
  CARGO_NET_GIT_FETCH_WITH_CLI: true
  OPENSSL_DIR: /usr
  OPENSSL_STATIC: 1
```

#### 版本号提取

```bash
T=${GITHUB_REF#refs/*/}     # 提取 tag 名
VERSION=${T#pro-v}          # 移除 pro-v 前缀
VERSION=${VERSION#pro-}     # 移除 pro- 前缀
```

### 4.6 依赖关系

```
build (matrix) ──┬──→ deb-package (matrix) ──┐
                 │                            │
build-win ───────┴────────────────────────────┼──→ release
                                              │
```

### 4.7 产物

| 产物 | 名称 | 用途 |
|-----|------|------|
| Linux 二进制 | `binaries-linux-{amd64,arm64v8,armv7}` | 多架构二进制 |
| Windows 二进制 | `binaries-windows-x86_64` | Windows 可执行文件 |
| Debian 包 | `debian-package-{amd64,arm64v8,armv7}` | DEB 安装包 |
| GitHub Release | - | 统一发布 |

### 4.8 常见问题

#### Q: cross 工具安装失败
**解决**：使用 Git 源安装
```bash
cargo install cross --git https://github.com/rust-embedded/cross
```

#### Q: musl 编译失败
**解决**：安装必要的依赖
```bash
sudo apt-get install -y musl-tools libssl-dev pkg-config
```

#### Q: DEB 包版本号为空
**解决**：检查 git tag 格式是否正确（应为 `pro-v1.0.0`）

#### Q: Release 创建失败
**解决**：检查 `permissions` 是否包含 `contents: write`

### 4.9 使用示例

```bash
# 推送标签触发完整发布
git tag pro-v1.0.0
git push origin pro-v1.0.0

# 手动触发，指定版本和平台
gh workflow run "Commercial Build" \
  --ref main \
  -f version=pro-v1.0.0 \
  -f platforms=amd64,arm64v8
```

---

## 5. commercial-cd.yml - 持续部署

**文件**：[commercial-cd.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-cd.yml)

### 5.1 功能概述

该工作流负责持续部署，包括：

- **Docker 镜像构建**：多架构（amd64, arm64v8, armv7）
- **镜像推送**：推送到 GHCR 和 Docker Hub
- **多架构 Manifest**：合并多架构镜像
- **SBOM 生成**：生成软件物料清单
- **Docker Compose 更新**：自动更新 `docker-compose.yml`

### 5.2 触发条件

```yaml
on:
  push:
    branches: [main]
    tags:
      - 'v*'
      - 'pro-v*'
      - 'pro-*'
  workflow_dispatch:
```

| 触发方式 | 条件 |
|---------|------|
| 推送到 main 分支 | 构建开发镜像 |
| 推送标签 | 完整发布流程 |
| 手动触发 | 自定义部署 |

### 5.3 执行步骤

| 任务 | 名称 | 职责 | 依赖 | 触发条件 |
|-----|------|------|------|---------|
| docker | Docker push (matrix) | 构建推送多架构 Docker 镜像 | 无 | 始终 |
| docker-manifest | Docker manifest | 创建多架构 Manifest | docker | 标签推送 |
| release | Create Release | 创建 Release + SBOM | docker-manifest | 标签推送 |
| docker-compose | Update Docker Compose | 更新 docker-compose.yml | docker | main 分支 |

### 5.4 环境配置

```yaml
permissions:
  contents: write
  packages: write
  id-token: write

env:
  CARGO_TERM_COLOR: always
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  GHCR_IMAGE: ghcr.io/changsongyang/rustdesk-pro-server
  DOCKERHUB_IMAGE: ycstech/rustdesk-pro-server
  LATEST_TAG: latest
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
```

### 5.5 关键参数

#### Docker 镜像矩阵

```yaml
matrix:
  job:
    - { name: "amd64",   docker_platform: "linux/amd64" }
    - { name: "arm64v8", docker_platform: "linux/arm64" }
    - { name: "armv7",   docker_platform: "linux/arm/v7" }
```

#### Dockerfile

```yaml
file: ./commercial/docker/Dockerfile.gha
```

#### 镜像标签策略

每个镜像生成 6 个标签：
- `{DOCKERHUB_IMAGE}:{LATEST_TAG}-{arch}`
- `{DOCKERHUB_IMAGE}:{GIT_TAG}-{arch}`
- `{DOCKERHUB_IMAGE}:{MAJOR_TAG}-{arch}`
- 对应的 GHCR 镜像标签

#### Manifest 类型

- `:{GIT_TAG}` - 具体版本（仅非手动触发）
- `:{MAJOR_TAG}` - 主版本号
- `:{LATEST_TAG}` - 最新版本

### 5.6 依赖关系

```
docker (matrix) ──┬──→ docker-manifest ──→ release
                  │
                  └──→ docker-compose (仅 main 分支)
```

### 5.7 常见问题

#### Q: Docker 镜像推送失败（403）
**原因**：GHCR 权限不足  
**解决**：确保 `packages: write` 权限已配置

#### Q: 跨架构下载工件失败
**原因**：上游 `commercial-build.yml` 未运行  
**解决**：先运行商业版构建

```yaml
- name: Download binaries from commercial-build
  uses: dawidd6/action-download-artifact@v2
  with:
    workflow: commercial-build.yml
    branch: main
```

#### Q: Manifest 创建失败
**原因**：上游镜像未推送成功  
**解决**：先确认 `docker` 任务完成

#### Q: SBOM 生成失败
**解决**：检查 `anchore/sbom-action` 版本和网络访问

### 5.8 必需的 Secrets

| Secret 名称 | 用途 | 必需性 |
|------------|------|-------|
| `GITHUB_TOKEN` | 自动提供，GHCR 认证 | 必需 |
| `DOCKER_HUB_USERNAME` | Docker Hub 登录 | 推荐 |
| `DOCKER_HUB_PASSWORD` | Docker Hub 登录 | 推荐 |

### 5.9 使用示例

```bash
# 推送标签触发完整部署
git tag pro-v1.0.0
git push origin pro-v1.0.0

# 推送到 main 触发开发镜像构建
git push origin main
```

---

## 6. 工作流对比与协作关系

### 6.1 工作流对比表

| 维度 | CI | Security | Build | CD |
|-----|----|---------|-------|-----|
| **职责** | 代码验证 | 安全扫描 | 构建打包 | 部署发布 |
| **触发频率** | 每次 push | 每周+每次 push | 标签触发 | 标签触发 |
| **运行时长** | 5-10 分钟 | 5-10 分钟 | 15-25 分钟 | 10-20 分钟 |
| **核心工具** | Cargo, Rustfmt, Clippy | Trivy, CodeQL | cross, cargo | Docker, buildx |
| **依赖关系** | 独立 | 独立 | 独立 | 依赖 Build 的 artifacts |

### 6.2 工作流协作关系

```
         ┌──────────┐
         │   CI     │  ← 验证代码
         └────┬─────┘
              │ 通过
              ▼
         ┌──────────┐
         │ Security │  ← 验证安全
         └────┬─────┘
              │ 通过
              ▼
         ┌──────────┐
         │  Build   │  ← 构建产物
         └────┬─────┘
              │ artifacts
              ▼
         ┌──────────┐
         │   CD     │  ← 部署发布
         └──────────┘
```

### 6.3 完整发布流程

```bash
# 1. 开发和验证（CI）
git push origin feature/new-feature
# → 触发 CI，检查代码质量

# 2. 合并到主分支
gh pr merge feature/new-feature

# 3. 安全扫描（Security）
git push origin main
# → 触发 Security，扫描依赖和代码

# 4. 构建发布（Build）
git tag pro-v1.0.0
git push origin pro-v1.0.0
# → 触发 Build，编译 + 打包 + Release

# 5. 部署发布（CD）
# 由 Build 触发的 artifacts 自动触发
# → 触发 CD，构建 Docker 镜像 + Manifest + SBOM
```

---

## 7. 常见问题排查

### 7.1 工作流未触发

**症状**：推送代码后工作流未运行

**排查步骤**：
1. 检查分支名是否在触发器配置中
2. 检查 workflow 文件语法（GitHub 会显示错误）
3. 检查仓库 Actions 是否启用

```bash
# 验证工作流语法
act -W .github/workflows/commercial-ci.yml --dryrun
```

### 7.2 编译失败

**症状**：build-* 任务失败

**常见原因**：
- Rust 工具链版本不匹配
- musl 工具链缺失
- OpenSSL 依赖问题

**解决**：
```bash
# 本地测试编译
cargo build --release --target x86_64-unknown-linux-musl

# 安装 musl 工具
sudo apt-get install -y musl-tools libssl-dev pkg-config
```

### 7.3 任务超时

**症状**：`The operation was canceled.`

**解决**：
- 优化代码或依赖
- 使用更快的 Runner
- 增加 `timeout-minutes`

### 7.4 Secrets 缺失

**症状**：登录或推送失败

**解决**：
```bash
# 添加 Secret
gh secret set DOCKER_HUB_USERNAME
gh secret set DOCKER_HUB_PASSWORD
```

### 7.5 跨工作流依赖失败

**症状**：CD 任务无法下载 Build 的 artifacts

**原因**：
- Build 未运行或失败
- 分支不匹配
- artifacts 已过期（90 天）

**解决**：
1. 确认 Build 已成功完成
2. 检查 `branch: main` 配置
3. 重新触发 Build

### 7.6 Docker 推送失败

**症状**：`denied: requested access to the resource is denied`

**解决**：
1. 检查 `packages: write` 权限
2. 确认 Registry 凭证有效
3. 检查镜像名称是否规范

### 7.7 Release 创建失败

**症状**：softprops/action-gh-release 报错

**解决**：
1. 确认 `contents: write` 权限
2. 检查 GITHUB_TOKEN 有效性
3. 确认有可发布的文件

### 7.8 安全扫描误报

**症状**：扫描报告误报漏洞或密钥

**解决**：
- **Cargo Audit**：使用 `--ignore` 参数
- **Trivy**：调整扫描配置或使用 `.trivyignore`
- **Gitleaks**：在 `.gitleaks.toml` 中配置白名单

---

## 附录 A：完整文件清单

| 文件 | 路径 | 工作流名 |
|-----|------|---------|
| 持续集成 | [commercial-ci.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-ci.yml) | CI |
| 安全扫描 | [commercial-security.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-security.yml) | Security |
| 商业构建 | [commercial-build.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-build.yml) | Commercial Build |
| 持续部署 | [commercial-cd.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-cd.yml) | CD |

## 附录 B：相关资源

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
- [Docker Buildx 文档](https://docs.docker.com/buildx/)
- [CodeQL 文档](https://codeql.github.com/docs/)
- [Trivy 文档](https://aquasecurity.github.io/trivy/)

---

**文档结束**

*本文档由 DevOps 团队维护。*
