# GitHub Action 完整示例详解指南

本文档详细介绍 GitHub Actions 的使用方法，基于 RustDesk Pro Server 项目中的实际工作流文件编写。

---

## 目录

1. [工作流文件结构](#1-工作流文件结构)
2. [触发器配置详解](#2-触发器配置详解)
3. [Job 配置详解](#3-job-配置详解)
4. [Step 配置详解](#4-step-配置详解)
5. [Matrix 构建配置详解](#5-matrix-构建配置详解)
6. [环境变量和 Secrets 配置](#6-环境变量和-secrets-配置)
7. [Artifacts 和缓存配置](#7-artifacts-和缓存配置)
8. [并行执行配置详解](#8-并行执行配置详解)
9. [条件执行配置详解](#9-条件执行配置详解)
10. [最佳实践总结](#10-最佳实践总结)
11. [完整参考示例](#11-完整参考示例)

---

## 1. 工作流文件结构

### 1.1 三层嵌套关系

GitHub Actions 工作流采用 **触发器(Triggers) → 作业(Jobs) → 步骤(Steps)** 的三层嵌套结构：

```
on:                    # 第一层：触发器 (Triggers)
  push:
    branches: [main]

jobs:                  # 第二层：作业 (Jobs)
  build:               # Job ID
    runs-on: ubuntu-22.04
    steps:             # 第三层：步骤 (Steps)
      - uses: actions/checkout@v4
      - run: cargo build
```

### 1.2 基础工作流文件示例

```yaml
name: 工作流名称                    # 工作流标题（可选）

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

env:
  CARGO_TERM_COLOR: always          # 全局环境变量

jobs:
  build:                            # Job ID（唯一标识）
    name: Build Job                 # Job 显示名称
    runs-on: ubuntu-22.04           # 运行节点

    steps:
      - name: Checkout              # Step 名称
        uses: actions/checkout@v4   # 使用 Action
        with:                       # Action 参数
          submodules: recursive

      - name: Build
        run: cargo build            # 执行命令
```

### 1.3 各配置项含义解释

| 配置项 | 位置 | 说明 | 示例 |
|--------|------|------|------|
| `name` | 工作流顶层 | 工作流显示名称 | `name: CI` |
| `on` | 工作流顶层 | 触发条件 | `on: push` |
| `env` | 工作流顶层 | 全局环境变量，所有 Job 共享 | `env: { KEY: value }` |
| `jobs` | 工作流顶层 | 所有作业定义 | `jobs: { build: {...} }` |
| `jobs.<id>.name` | Job | Job 显示名称 | `name: Build` |
| `jobs.<id>.runs-on` | Job | 运行环境的标签 | `runs-on: ubuntu-22.04` |
| `jobs.<id>.needs` | Job | 依赖的其他 Job | `needs: [job1, job2]` |
| `jobs.<id>.if` | Job | 条件执行表达式 | `if: github.ref == 'main'` |
| `jobs.<id>.strategy` | Job | Matrix 构建配置 | `strategy: { matrix: {...} }` |
| `jobs.<id>.steps` | Job | 步骤列表 | `steps: [{uses: ..., run: ...}]` |
| `steps[].name` | Step | 步骤显示名称 | `name: Checkout` |
| `steps[].uses` | Step | 引用的 Action | `uses: actions/checkout@v4` |
| `steps[].run` | Step | 执行命令 | `run: npm install` |
| `steps[].with` | Step | Action 参数 | `with: { token: ${{ secrets.GITHUB_TOKEN }} }` |
| `steps[].env` | Step | 步骤级环境变量 | `env: { NODE_ENV: test }` |
| `steps[].if` | Step | 步骤级条件 | `if: success()` |

---

## 2. 触发器配置详解

### 2.1 push/pull_request 触发示例

```yaml
on:
  # push 到指定分支时触发
  push:
    branches:
      - main
      - develop
    # 排除某些分支
    branches-ignore:
      - feature-*
    # 监听特定路径变化
    paths:
      - 'src/**'
      - '**.rs'
    # 忽略特定路径
    paths-ignore:
      - 'docs/**'
    # 监听特定标签
    tags:
      - 'v*'
      - 'pro-*'
    # 忽略空提交
    ignore-empty: false

  # pull_request 触发
  pull_request:
    branches: [main, develop]
    types:
      - opened      # PR 打开
      - synchronize # PR 同步（新建提交）
      - reopened   # PR 重新打开
      - closed     # PR 关闭
```

**实际项目参考**（commercial-build-deploy.yml）：

```yaml
on:
  # 方式1: 推送 tag 触发
  push:
    branches: [main]
    tags:
      - 'pro-v*'
      - 'pro-*'
  
  # 方式2: 手动触发
  workflow_dispatch:
```

### 2.2 workflow_dispatch 触发示例

手动触发工作流，支持输入参数：

```yaml
on:
  workflow_dispatch:
    inputs:
      version:
        description: '版本号 (e.g., pro-v1.0.0)'
        required: false
        type: string
      environment:
        description: '部署环境'
        required: true
        type: choice
        options:
          - production
          - staging
          - dev
      debug:
        description: '启用调试模式'
        type: boolean
        default: false
```

**实际项目参考**（commercial-build-deploy.yml）：

```yaml
workflow_dispatch:
  inputs:
    version:
      description: '版本号 (e.g., pro-v1.0.0)'
      required: false
      type: string
```

### 2.3 schedule/crontab 触发示例

定时执行工作流，使用 cron 语法：

```yaml
on:
  schedule:
    # 每周一凌晨 2 点执行
    - cron: '0 2 * * 1'
    # 每天凌晨 0 点执行
    - cron: '0 0 * * *'
    # 工作日每天下午 6 点执行
    - cron: '0 18 * * 1-5'
    # 每月 1 日凌晨 1 点执行
    - cron: '0 1 1 * *'
```

**cron 表达式格式**：

```
┌───────────── 分钟 (0-59)
│ ┌───────────── 小时 (0-23)
│ │ ┌───────────── 日期 (1-31)
│ │ │ ┌───────────── 月份 (1-12)
│ │ │ │ ┌───────────── 星期 (0-6，0=周日)
│ │ │ │ │
* * * * *
```

### 2.4 workflow_run 触发示例

在另一个工作流完成后触发：

```yaml
on:
  workflow_run:
    workflows: ["CI"]              # 监听的工作流名称
    types: [completed]             # 触发时机：completed
    branches: [main]               # 可选：限定分支
```

---

## 3. Job 配置详解

### 3.1 runs-on 配置说明

指定 Job 运行的环境：

| 运行器类型 | 示例 | 说明 |
|-----------|------|------|
| GitHub 托管 | `ubuntu-latest` | Ubuntu 最新 LTS |
| GitHub 托管 | `ubuntu-22.04` | Ubuntu 22.04 |
| GitHub 托管 | `windows-2022` | Windows Server 2022 |
| GitHub 托管 | `macos-14` | macOS Sonoma |
| 自托管 | `self-hosted` | 自托管运行器 |
| 自托管 + 标签 | `['self-hosted', 'linux']` | 带标签的自托管 |

```yaml
# GitHub 托管运行器
jobs:
  ubuntu-job:
    runs-on: ubuntu-22.04
  
  windows-job:
    runs-on: windows-2022
  
  macos-job:
    runs-on: macos-14
  
  # 自托管运行器
  self-hosted-job:
    runs-on: ['self-hosted', 'linux', 'x64']
```

### 3.2 needs 依赖配置说明

设置 Job 之间的依赖关系，形成 DAG（有向无环图）：

```yaml
jobs:
  job1:
    runs-on: ubuntu-latest
  
  job2:
    needs: job1                    # 等待 job1 完成
    runs-on: ubuntu-latest
  
  job3:
    needs: [job1, job2]            # 等待多个 Job 完成
    runs-on: ubuntu-latest
```

**常见模式**：

```yaml
jobs:
  # 阶段 1: 并行构建
  build-linux:
    runs-on: ubuntu-latest
  build-windows:
    runs-on: windows-2022
  
  # 阶段 2: 依赖阶段 1
  test:
    needs: [build-linux, build-windows]
    runs-on: ubuntu-latest
  
  # 阶段 3: 依赖阶段 2
  deploy:
    needs: test
    runs-on: ubuntu-latest
```

### 3.3 if 条件配置说明

控制 Job 是否执行：

```yaml
jobs:
  deploy:
    needs: build
    # 仅在 main 分支且 tag 推送时执行
    if: github.ref == 'refs/heads/main' && startsWith(github.event.head_commit.message, 'deploy')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

**实际项目参考**（commercial-build-deploy.yml）：

```yaml
deb-package:
  needs: 
    - pre-build
    - build-summary
  # 使用 Job outputs 进行条件判断
  if: needs.pre-build.outputs.should_deploy == 'true' && needs.build-summary.result == 'success'
  runs-on: ubuntu-22.04
```

### 3.4 outputs 输出配置说明

定义 Job 的输出变量，供其他 Job 使用：

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      build_status: ${{ steps.build-status.outputs.status }}
      artifact_name: ${{ steps.build-status.outputs.artifact_name }}
    steps:
      - id: build-status
        run: |
          echo "status=success" >> $GITHUB_OUTPUT
          echo "artifact_name=my-artifact" >> $GITHUB_OUTPUT

  deploy:
    needs: build
    # 使用上一个 Job 的输出
    if: needs.build.outputs.build_status == 'success'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying ${{ needs.build.outputs.artifact_name }}"
```

---

## 4. Step 配置详解

### 4.1 uses 调用 Action 配置说明

引用社区或官方 Action：

```yaml
steps:
  # 官方 Action
  - uses: actions/checkout@v4
  
  # 第三方 Action（带版本）
  - uses: dtolnay/rust-toolchain@stable
  
  # 第三方 Action（精确版本）
  - uses: docker/login-action@v2
  
  # 引用 Docker 镜像
  - uses: docker://nginx:latest
  
  # 引用 GitHub 市场 Action
  - uses: GermanBluefox/code-sign-action@v7
```

**常用 Action 列表**：

| Action | 用途 | 示例 |
|--------|------|------|
| `actions/checkout` | 检出代码 | `uses: actions/checkout@v4` |
| `actions/setup-node` | 设置 Node.js | `uses: actions/setup-node@v4` |
| `actions/setup-python` | 设置 Python | `uses: actions/setup-python@v5` |
| `dtolnay/rust-toolchain` | 设置 Rust | `uses: dtolnay/rust-toolchain@stable` |
| `actions/upload-artifact` | 上传制品 | `uses: actions/upload-artifact@v4` |
| `actions/download-artifact` | 下载制品 | `uses: actions/download-artifact@v4` |
| `actions/cache` | 缓存管理 | `uses: actions/cache@v4` |
| `docker/login-action` | Docker 登录 | `uses: docker/login-action@v2` |
| `docker/setup-qemu-action` | QEMU 设置 | `uses: docker/setup-qemu-action@v2` |
| `docker/setup-buildx-action` | Buildx 设置 | `uses: docker/setup-buildx-action@v2` |
| `Swatinem/rust-cache` | Rust 缓存 | `uses: Swatinem/rust-cache@v2` |

### 4.2 run 执行命令配置说明

```yaml
steps:
  # 单行命令
  - run: echo "Hello World"
  
  # 多行命令（使用 |）
  - run: |
      echo "Line 1"
      echo "Line 2"
      cargo build --release
  
  # 使用 shell 指定
  - name: Windows PowerShell Command
    run: Write-Host "Hello"
    shell: pwsh
  
  # 使用工作目录
  - name: Run in subdirectory
    run: npm install
    working-directory: ./ui/html
```

**常用 shell 选项**：

| Shell | 用途 | 配置值 |
|-------|------|--------|
| bash | Linux/macOS 默认 | `shell: bash` |
| pwsh | PowerShell Core | `shell: pwsh` |
| powershell | Windows PowerShell | `shell: powershell` |
| python | Python 解释器 | `shell: python` |
| sh | POSIX sh | `shell: sh` |

### 4.3 with 参数传递配置说明

向 Action 传递参数：

```yaml
steps:
  # Checkout Action 参数
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0        # 完整历史
      submodules: recursive # 递归克隆子模块
      token: ${{ secrets.GITHUB_TOKEN }}  # 认证令牌
  
  # setup-node 参数
  - uses: actions/setup-node@v4
    with:
      node-version: '20'
      cache: 'npm'
      cache-dependency-path: '**/package-lock.json'
  
  # rust-toolchain 参数
  - uses: dtolnay/rust-toolchain@stable
    with:
      toolchain: "1.96"
      targets: aarch64-unknown-linux-musl
      components: rustfmt, clippy
```

### 4.4 env 环境变量配置说明

```yaml
# 步骤级环境变量
steps:
  - name: Build with custom env
    env:
      CARGO_TERM_COLOR: always
      RUST_BACKTRACE: 1
      DATABASE_URL: "sqlite::memory:"
    run: cargo build --release

# 条件环境变量
  - name: Conditional env
    env:
      NODE_ENV: ${{ github.event_name == 'push' && 'production' || 'test' }}
    run: echo $NODE_ENV
```

---

## 5. Matrix 构建配置详解

### 5.1 matrix.strategy 配置说明

Matrix 策略允许在多个配置组合上并行运行 Job：

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        os: [ubuntu-latest, windows-2022, macos-14]
        rust: [1.75, 1.76, 1.77]
```

这将生成 3 × 3 = 9 个 Job。

### 5.2 fail-fast 配置说明

控制 Matrix 中某个 Job 失败时是否取消其他 Job：

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: true    # 一个失败，全部取消（默认）
      matrix:
        target: [a, b, c]

  # 禁用 fail-fast
  build:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false   # 一个失败，其他继续
      matrix:
        target: [a, b, c]
```

### 5.3 max-parallel 并行配置说明

限制 Matrix 并行执行的数量：

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      max-parallel: 2    # 最多同时运行 2 个
      matrix:
        target: [a, b, c, d]  # 4 个 Job 需分批执行
```

### 5.4 多维度 Matrix 示例

**实际项目参考**（build.yaml）：

```yaml
jobs:
  build:
    name: Build - ${{ matrix.job.name }}
    runs-on: ubuntu-22.04
    strategy:
      fail-fast: false
      matrix:
        job:
          - { name: "amd64",   target: "x86_64-unknown-linux-musl" }
          - { name: "arm64v8", target: "aarch64-unknown-linux-musl" }
          - { name: "armv7",   target: "armv7-unknown-linux-musleabihf" }
          - { name: "i386",    target: "i686-unknown-linux-musl" }

    steps:
      - name: Build
        run: cross build --release --target=${{ matrix.job.target }}
        env:
          CARGO_NET_GIT_FETCH_WITH_CLI: true
```

**包含 include/exclude 的复杂 Matrix**：

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-2022]
    rust: [1.75, 1.76]
    include:
      - os: ubuntu-latest
        rust: 1.77
        extra: true
    exclude:
      - os: windows-2022
        rust: 1.75
```

---

## 6. 环境变量和 Secrets 配置

### 6.1 env 全局环境变量配置

```yaml
env:
  CARGO_TERM_COLOR: always
  RUST_BACKTRACE: 1
  REGISTRY: ghcr.io
  GHCR_IMAGE: ghcr.io/changsongyang/rustdesk-pro-server
  DOCKERHUB_IMAGE: ycstech/rustdesk-pro-server
  LATEST_TAG: latest

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      CARGO_NET_GIT_FETCH_WITH_CLI: true  # Job 级覆盖
    steps:
      - run: echo $CARGO_TERM_COLOR
```

### 6.2 steps.env 局部环境变量配置

```yaml
steps:
  - name: Set environment variables
    env:
      BUILD_VERSION: '1.0.0'
      BUILD_DATE: ${{ github.event.created_at }}
    run: |
      echo "Version: $BUILD_VERSION"
      echo "Date: $BUILD_DATE"
```

### 6.3 secrets 配置和使用说明

Secrets 是加密的环境变量，在 UI 设置：

```yaml
steps:
  # 使用 secret
  - name: Docker login
    uses: docker/login-action@v2
    with:
      username: ${{ secrets.DOCKER_HUB_USERNAME }}
      password: ${{ secrets.DOCKER_HUB_PASSWORD }}
  
  # 使用 GitHub Token（自动提供）
  - name: Upload to GitHub
    uses: actions/upload-artifact@v4
    with:
      name: my-artifact
      path: ./dist
      retention-days: 30
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**内置 Secrets**：

| Secret | 说明 |
|--------|------|
| `GITHUB_TOKEN` | 自动生成的 GitHub API 令牌 |
| `secrets.GITHUB_TOKEN` | 同上（在新语法中推荐） |
| `GITHUB_REPOSITORY` | 仓库名称 `owner/repo` |
| `GITHUB_SHA` | 触发事件的提交 SHA |

### 6.4 GITHUB_ENV 和 GITHUB_OUTPUT 用法

**GITHUB_ENV**：设置后续步骤可用的环境变量

```yaml
steps:
  - name: Set environment variables
    run: |
      echo "BUILD_ID=$(date +%Y%m%d)" >> $GITHUB_ENV
      echo "GIT_TAG=${GITHUB_REF#refs/tags/}" >> $GITHUB_ENV
  
  - name: Use environment variable
    run: echo "Build ID is $BUILD_ID"
```

**GITHUB_OUTPUT**：设置 Job outputs

```yaml
steps:
  - name: Output status
    id: build-status
    run: |
      echo "status=success" >> $GITHUB_OUTPUT
      echo "artifact_name=binaries-linux-amd64" >> $GITHUB_OUTPUT
  
  # 后续步骤可使用
  - name: Use output
    run: echo "Artifact: ${{ steps.build-status.outputs.artifact_name }}"
```

**实际项目参考**（commercial-build-deploy.yml）：

```yaml
- name: Extract - Version Information
  id: vars
  run: |
    if [ "${{ github.event.inputs.version }}" != "" ]; then
      T=${{ github.event.inputs.version }}
    elif [ "${{ github.ref_type }}" = "tag" ]; then
      T=${GITHUB_REF#refs/tags/}
    else
      T="dev-${GITHUB_SHA::8}"
    fi
    echo "git_tag=$T" >> $GITHUB_OUTPUT
    echo "GIT_TAG=$T" >> $GITHUB_ENV
    
    VERSION=${T#pro-v}
    VERSION=${VERSION#pro-}
    VERSION=${VERSION#v}
    echo "deb_version=$VERSION" >> $GITHUB_OUTPUT
    echo "DEB_VERSION=$VERSION" >> $GITHUB_ENV
```

---

## 7. Artifacts 和缓存配置

### 7.1 actions/upload-artifact 配置说明

```yaml
- name: Upload Artifacts
  uses: actions/upload-artifact@v4
  with:
    name: binaries-${{ matrix.job.name }}    # 制品名称（唯一）
    path: |
      target/release/hbbr
      target/release/hbbs
      target/release/rustdesk-utils
    retention-days: 30                        # 保留天数（默认 90）
    compression-level: 9                       # 压缩级别（0-9）
    if-no-files-found: error                   # 未找到文件时：error/warn/ignore
```

### 7.2 actions/download-artifact 配置说明

```yaml
# 下载单个制品
- name: Download Artifacts
  uses: actions/download-artifact@v4
  with:
    name: binaries-linux-amd64
    path: ./downloads

# 下载所有制品
- name: Download All Artifacts
  uses: actions/download-artifact@v4
  with:
    path: artifacts

# 按 pattern 下载
- name: Download Debian Packages
  uses: actions/download-artifact@v4
  with:
    pattern: debian-package-*    # 使用通配符
    path: ./packages
```

### 7.3 actions/cache 配置说明

```yaml
# 缓存目录
- name: Cache cargo dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.cargo/bin/
      ~/.cargo/registry/index/
      ~/.cargo/git/
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
    restore-keys: |
      ${{ runner.os }}-cargo-

# 使用 Swatinem/rust-cache（推荐用于 Rust）
- name: Cache cargo dependencies
  uses: Swatinem/rust-cache@v2
  with:
    key: ${{ matrix.target }}    # 按目标架构缓存
```

### 7.4 依赖缓存最佳实践

```yaml
steps:
  # Rust 缓存（推荐）
  - name: Cache Rust dependencies
    uses: Swatinem/rust-cache@v2
    with:
      key: ${{ matrix.target }}

  # Node.js 缓存
  - name: Cache node_modules
    uses: actions/cache@v4
    with:
      path: node_modules
      key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-npm-

  # Python 缓存
  - name: Cache pip packages
    uses: actions/cache@v4
    with:
      path: ~/.cache/pip
      key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
```

---

## 8. 并行执行配置详解

### 8.1 Job 并行执行配置

默认情况下，独立 Job 并行执行：

```yaml
jobs:
  # 这些 Job 同时开始（并行）
  build-linux:
    runs-on: ubuntu-latest
  build-windows:
    runs-on: windows-2022
  build-macos:
    runs-on: macos-14
  
  # 依赖上述三个 Job
  test:
    needs: [build-linux, build-windows, build-macos]
    runs-on: ubuntu-latest
```

### 8.2 Step 并行执行配置

同一 Job 内的 Step 必须串行执行，无法并行。

如需并行执行不同任务，应创建独立的 Job：

```yaml
jobs:
  # 任务 A
  task-a:
    runs-on: ubuntu-latest
    steps:
      - run: task-a.sh
  
  # 任务 B（与任务 A 并行）
  task-b:
    runs-on: ubuntu-latest
    steps:
      - run: task-b.sh
  
  # 汇总任务（等待 A 和 B）
 汇总:
    needs: [task-a, task-b]
    runs-on: ubuntu-latest
    steps:
      - run: echo "All done"
```

### 8.3 依赖链和等待机制

```yaml
jobs:
  job-a:
    runs-on: ubuntu-latest
  
  # 等待 job-a
  job-b:
    needs: job-a
    runs-on: ubuntu-latest
  
  # 等待 job-a 和 job-b
  job-c:
    needs: [job-a, job-b]
    runs-on: ubuntu-latest
  
  # 等待 job-c
  job-d:
    needs: job-c
    runs-on: ubuntu-latest
```

**依赖链可视化**：

```
job-a ──→ job-b ──→ job-c ──→ job-d
                ↗
          job-a ─┘
```

---

## 9. 条件执行配置详解

### 9.1 基于变量条件执行

```yaml
jobs:
  deploy:
    needs: build
    # 仅在 main 分支执行
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."

  # 仅在 tag 推送时执行
  release:
    if: startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Creating release..."
```

### 9.2 基于步骤结果条件执行

```yaml
steps:
  - name: Build
    id: build
    run: |
      if [ "${{ github.event_name }}" == "pull_request" ]; then
        echo "status=skipped" >> $GITHUB_OUTPUT
        echo "Skipping build for PR"
        exit 0
      fi
      cargo build --release
      echo "status=success" >> $GITHUB_OUTPUT

  # 基于上一步结果执行
  - name: Deploy
    if: steps.build.outputs.status == 'success'
    run: echo "Deploying..."
```

### 9.3 复合条件表达式

```yaml
jobs:
  deploy:
    # 复合条件：main 分支 + tag 推送 + 不是 PR
    if: |
      github.ref == 'refs/heads/main' &&
      startsWith(github.event.head_commit.message, 'deploy') &&
      github.event_name != 'pull_request'
    runs-on: ubuntu-latest

  # 使用函数
  conditional-job:
    if: |
      always() ||
      (github.event_name == 'workflow_dispatch' && github.event.inputs.force == 'true')
    runs-on: ubuntu-latest
```

### 9.4 always() 和 cancelled() 用法

```yaml
jobs:
  # 无论结果如何都执行清理
  cleanup:
    needs: [build, test, deploy]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Cleanup
        run: rm -rf build/

  # 仅在取消时执行
  handle-cancellation:
    if: cancelled()
    runs-on: ubuntu-latest
    steps:
      - name: Handle cancellation
        run: echo "Workflow was cancelled"
```

**常用函数**：

| 函数 | 说明 |
|------|------|
| `success()` | 所有前置 Job/Step 成功 |
| `failure()` | 任一前置 Job/Step 失败 |
| `always()` | 无论成功、失败或取消都执行 |
| `cancelled()` | 工作流被取消 |
| `ancelled()` | 工作流被取消（简写） |
| `contains(github.event.head_commit.message, 'deploy')` | 提交信息包含指定字符串 |
| `startsWith(github.ref, 'refs/tags/')` | 引用是标签 |
| `endsWith(github.ref, 'v1.0.0')` | 引用以指定字符串结尾 |

---

## 10. 最佳实践总结

### 10.1 安全性最佳实践

```yaml
# 1. 最小权限原则 - 仅请求必要的权限
permissions:
  contents: write    # 仅需要写 contents
  packages: write    # 仅需要写 packages
  id-token: write    # OIDC 认证

# 2. 使用短时效 token
- name: Generate token
  uses: tibdex/github-app-token@v1
  with:
    app_id: ${{ secrets.APP_ID }}
    permissions: |
      contents: write

# 3. 不在日志中输出敏感信息
- name: Use secret
  run: |
    echo "::add-mask::${{ secrets.SECRET_KEY }}"
    echo "Processing with masked secret"

# 4. 使用环境变量而非硬编码
env:
  DOCKER_IMAGE: ${{ secrets.DOCKER_IMAGE }}

# 5. 验证输入参数
- name: Validate inputs
  run: |
    if [ -z "${{ github.event.inputs.version }}" ]; then
      echo "Error: version is required"
      exit 1
    fi
```

### 10.2 性能优化最佳实践

```yaml
# 1. 使用缓存
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.cargo/bin/
      ~/.cargo/registry/
    key: cargo-${{ hashFiles('**/Cargo.lock') }}

# 2. 使用 Swatinem/rust-cache（推荐）
- name: Cache Rust dependencies
  uses: Swatinem/rust-cache@v2

# 3. 只 checkout 需要的内容
- uses: actions/checkout@v4
  with:
    fetch-depth: 1      # 浅克隆
    submodules: false   # 不需要子模块时禁用

# 4. 禁用 fail-fast 以充分利用并行
strategy:
  fail-fast: false

# 5. 限制并行数（避免资源争抢）
strategy:
  max-parallel: 5

# 6. 使用更快的运行器
runs-on: ubuntu-latest    # 比 ubuntu-22.04 更快

# 7. 合并相关命令减少 Step
- name: Install and build
  run: |
    npm ci
    npm run build
```

### 10.3 错误处理最佳实践

```yaml
# 1. 显式设置退出码
- name: Validate
  run: |
    if ! validate.sh; then
      echo "Validation failed"
      exit 1
    fi

# 2. 使用 always() 确保清理
- name: Cleanup
  if: always()
  run: rm -rf build/

# 3. 捕获命令失败
- name: Build
  run: |
    set -e  # 任何命令失败立即退出
    cargo build --release

# 4. 提供有意义的错误信息
- name: Verify build result
  run: |
    if [ ! -f "target/release/myapp" ]; then
      echo "Error: Build failed - binary not found"
      exit 1
    fi

# 5. 验证制品存在
- name: Upload artifacts
  uses: actions/upload-artifact@v4
  with:
    path: ./dist
    if-no-files-found: error    # 明确处理缺失情况
```

### 10.4 可维护性最佳实践

```yaml
# 1. 使用清晰的命名
jobs:
  # 好的命名
  build-linux-amd64:
    name: Build Linux (amd64)
  
  # 不好的命名
  job1:

# 2. 添加注释说明
jobs:
  pre-build:
    name: P1 - Pre-Build
    # ================================================================================
    # 功能: 统一版本号管理和部署条件判断
    # 输入: github.ref, inputs.version
    # 输出: git_tag, should_deploy, build_id
    # 执行条件: 始终执行
    # 依赖: 无
    # ================================================================================

# 3. 使用常量而非魔法数字
env:
  MAX_PARALLEL: 5
  RETENTION_DAYS: 30

# 4. 模块化重复配置
# 不好：
steps:
  - uses: docker/login-action@v2
    with:
      username: user
      password: pass
  - uses: docker/login-action@v2
    with:
      username: user2
      password: pass2

# 5. 按执行顺序组织 Job
jobs:
  pre-build:      # 准备
  build:          # 构建
  test:           # 测试
  deploy:         # 部署

# 6. 使用 outputs 进行 Job 间通信
jobs:
  build:
    outputs:
      version: ${{ steps.vars.outputs.version }}
    steps:
      - id: vars
        run: echo "version=1.0.0" >> $GITHUB_OUTPUT
```

---

## 11. 完整参考示例

### 11.1 CI 工作流完整示例

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:

env:
  CARGO_TERM_COLOR: always
  RUST_BACKTRACE: 1

jobs:
  # 代码格式化检查
  fmt:
    name: "[P1] Rustfmt"
    runs-on: ubuntu-latest
    outputs:
      status: ${{ steps.fmt-status.outputs.status }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Install Rust toolchain with rustfmt
        uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt

      - name: Check formatting
        run: cargo fmt --manifest-path commercial/Cargo.toml -- --check

      - name: Report fmt status
        id: fmt-status
        run: |
          echo "status=success" >> $GITHUB_OUTPUT

  # 静态分析检查
  clippy:
    name: "[P2] Clippy"
    runs-on: ubuntu-latest
    outputs:
      status: ${{ steps.clippy-status.outputs.status }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Install Rust toolchain with clippy
        uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy

      - name: Cache cargo dependencies
        uses: Swatinem/rust-cache@v2

      - name: Run Clippy
        run: cargo clippy --manifest-path commercial/Cargo.toml --all-targets --no-deps -- -D warnings
        env:
          CARGO_NET_GIT_FETCH_WITH_CLI: true

      - name: Report clippy status
        id: clippy-status
        run: |
          echo "status=success" >> $GITHUB_OUTPUT

  # 单元测试
  test:
    name: "[P3] Test Suite"
    runs-on: ubuntu-latest
    outputs:
      status: ${{ steps.test-status.outputs.status }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@stable

      - name: Cache cargo dependencies
        uses: Swatinem/rust-cache@v2

      - name: Run tests
        run: cargo test --manifest-path commercial/Cargo.toml -- --nocapture
        env:
          CARGO_NET_GIT_FETCH_WITH_CLI: true
          DATABASE_URL: "sqlite::memory:"

      - name: Report test status
        id: test-status
        run: |
          echo "status=success" >> $GITHUB_OUTPUT

  # 编译验证
  build:
    name: "[P4] Build (${{ matrix.target }})"
    runs-on: ubuntu-latest
    outputs:
      status: ${{ steps.build-status.outputs.status }}
    strategy:
      fail-fast: false
      max-parallel: 5
      matrix:
        target:
          - x86_64-unknown-linux-gnu
          - x86_64-unknown-linux-musl
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@stable
        with:
          targets: ${{ matrix.target }}

      - name: Install musl toolchain
        if: contains(matrix.target, 'musl')
        run: |
          sudo apt-get update
          sudo apt-get install -y musl-tools

      - name: Cache cargo dependencies
        uses: Swatinem/rust-cache@v2
        with:
          key: ${{ matrix.target }}

      - name: Build
        run: cargo build --manifest-path commercial/Cargo.toml --release --target ${{ matrix.target }}
        env:
          CARGO_NET_GIT_FETCH_WITH_CLI: true

      - name: Report build status
        id: build-status
        run: |
          echo "status=success" >> $GITHUB_OUTPUT

  # 综合检查汇总
  summary:
    name: "[P5] CI Summary"
    needs: [fmt, clippy, test, build]
    runs-on: ubuntu-latest
    outputs:
      ci_status: ${{ steps.final-status.outputs.ci_status }}
      all_passed: ${{ steps.final-status.outputs.all_passed }}

    steps:
      - name: Collect task statuses
        id: collect-status
        run: |
          echo "=============================================="
          echo "         CI Pipeline Status Report            "
          echo "=============================================="
          echo "P1 - Rustfmt:      ${{ needs.fmt.outputs.status || 'unknown' }}"
          echo "P2 - Clippy:       ${{ needs.clippy.outputs.status || 'unknown' }}"
          echo "P3 - Test Suite:   ${{ needs.test.outputs.status || 'unknown' }}"
          echo "P4 - Build:        ${{ needs.build.outputs.status || 'unknown' }}"
          echo "=============================================="

      - name: Determine final CI status
        id: final-status
        run: |
          if [ "${{ needs.fmt.result }}" == "success" ] && \
             [ "${{ needs.clippy.result }}" == "success" ] && \
             [ "${{ needs.test.result }}" == "success" ] && \
             [ "${{ needs.build.result }}" == "success" ]; then
            echo "ci_status=success" >> $GITHUB_OUTPUT
            echo "all_passed=true" >> $GITHUB_OUTPUT
            echo "All CI checks passed - Ready for CD pipeline"
          else
            echo "ci_status=failed" >> $GITHUB_OUTPUT
            echo "all_passed=false" >> $GITHUB_OUTPUT
            echo "CI checks failed - Blocking CD pipeline"
          fi

      - name: CI Pipeline Complete
        if: success()
        run: |
          echo "=============================================="
          echo "         CI Pipeline Completed Successfully   "
          echo "=============================================="
          echo "All CI checks passed!"
          echo "- P1 Formatting: PASSED"
          echo "- P2 Static Analysis: PASSED"
          echo "- P3 Unit Tests: PASSED"
          echo "- P4 Build Validation: PASSED"
          echo "=============================================="

      - name: CI Pipeline Failed
        if: failure()
        run: |
          echo "=============================================="
          echo "         CI Pipeline Failed                   "
          echo "=============================================="
          echo "One or more CI checks failed"
          echo "CD pipeline execution blocked"
          echo "=============================================="
          exit 1
```

### 11.2 CD 工作流完整示例

```yaml
name: Commercial Build & Deploy

permissions:
  contents: write
  packages: write
  id-token: write

on:
  push:
    branches: [main]
    tags:
      - 'pro-v*'
      - 'pro-*'
  
  workflow_dispatch:
    inputs:
      version:
        description: '版本号 (e.g., pro-v1.0.0)'
        required: false
        type: string

env:
  CARGO_TERM_COLOR: always
  REGISTRY: ghcr.io
  GHCR_IMAGE: ghcr.io/changsongyang/rustdesk-pro-server
  DOCKERHUB_IMAGE: ycstech/rustdesk-pro-server
  LATEST_TAG: latest

jobs:
  # P1 - 构建准备
  pre-build:
    name: P1 - Pre-Build
    runs-on: ubuntu-22.04
    outputs:
      build_id: ${{ steps.build-id.outputs.build_id }}
      git_tag: ${{ steps.vars.outputs.git_tag }}
      deb_version: ${{ steps.vars.outputs.deb_version }}
      should_deploy: ${{ steps.deploy-check.outputs.should_deploy }}
    
    steps:
      - name: Checkout - Repository
        uses: actions/checkout@v5
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Generate - Build ID
        id: build-id
        run: |
          BUILD_ID=$(date +%Y%m%d-%H%M%S)-${GITHUB_SHA::8}
          echo "build_id=$BUILD_ID" >> $GITHUB_OUTPUT
          echo "BUILD_ID=$BUILD_ID" >> $GITHUB_ENV

      - name: Extract - Version Information
        id: vars
        run: |
          if [ "${{ github.event.inputs.version }}" != "" ]; then
            T=${{ github.event.inputs.version }}
          elif [ "${{ github.ref_type }}" = "tag" ]; then
            T=${GITHUB_REF#refs/tags/}
          else
            T="dev-${GITHUB_SHA::8}"
          fi
          echo "git_tag=$T" >> $GITHUB_OUTPUT
          echo "GIT_TAG=$T" >> $GITHUB_ENV
          
          VERSION=${T#pro-v}
          VERSION=${VERSION#pro-}
          VERSION=${VERSION#v}
          echo "deb_version=$VERSION" >> $GITHUB_OUTPUT

      - name: Determine - Deployment Status
        id: deploy-check
        run: |
          if [[ "${{ github.ref }}" == refs/tags/pro-* ]] || [[ "${{ github.event.inputs.version }}" != "" ]]; then
            echo "should_deploy=true" >> $GITHUB_OUTPUT
          else
            echo "should_deploy=false" >> $GITHUB_OUTPUT
          fi

  # P2 - Linux 构建（多架构并行）
  build-linux:
    name: P2 - Build Linux (${{ matrix.job.name }})
    needs: pre-build
    runs-on: ubuntu-22.04
    outputs:
      status: ${{ steps.build-status.outputs.status }}
    strategy:
      fail-fast: false
      max-parallel: 5
      matrix:
        job:
          - { name: "amd64",   target: "x86_64-unknown-linux-musl" }
          - { name: "arm64v8", target: "aarch64-unknown-linux-musl" }
          - { name: "armv7",   target: "armv7-unknown-linux-musleabihf" }
    
    steps:
      - name: Checkout - Repository
        uses: actions/checkout@v5
        with:
          submodules: recursive
      
      - name: Install - Rust Toolchain
        uses: dtolnay/rust-toolchain@stable
        with:
          toolchain: "1.96"
          targets: ${{ matrix.job.target }}
      
      - name: Install - Cross Tool
        run: cargo install cross --version 0.2.5
        timeout-minutes: 30
      
      - name: Cache - Cargo Dependencies
        uses: Swatinem/rust-cache@v2
        with:
          key: ${{ matrix.job.target }}
      
      - name: Compile - Build Binary
        run: |
          rm -f commercial/Cargo.lock
          cross build --manifest-path commercial/Cargo.toml --release --target=${{ matrix.job.target }}
        env:
          CARGO_NET_GIT_FETCH_WITH_CLI: true
        timeout-minutes: 60
      
      - name: Upload - Build Artifact
        uses: actions/upload-artifact@v5
        with:
          name: binaries-linux-${{ matrix.job.name }}
          path: |
            commercial/target/${{ matrix.job.target }}/release/rustdesk-pro
          if-no-files-found: error

  # P2 - Windows 构建
  build-windows:
    name: P2 - Build Windows
    needs: pre-build
    runs-on: windows-2022
    outputs:
      status: ${{ steps.build-status.outputs.status }}
    
    steps:
      - name: Checkout - Repository
        uses: actions/checkout@v5
        with:
          submodules: recursive
      
      - name: Install - Rust Toolchain
        uses: dtolnay/rust-toolchain@stable
        with:
          toolchain: "1.96"
          targets: x86_64-pc-windows-msvc
      
      - name: Cache - Cargo Dependencies
        uses: Swatinem/rust-cache@v2
      
      - name: Compile - Build Binary
        run: cargo build --manifest-path commercial/Cargo.toml --release --target=x86_64-pc-windows-msvc
        env:
          CARGO_NET_GIT_FETCH_WITH_CLI: true
        timeout-minutes: 60
      
      - name: Upload - Build Artifact
        uses: actions/upload-artifact@v5
        with:
          name: binaries-windows-x86_64
          path: |
            commercial\target\x86_64-pc-windows-msvc\release\rustdesk-pro.exe
          if-no-files-found: error

  # P3 - 构建汇总与验证
  build-summary:
    name: P3 - Build Summary
    needs: 
      - build-linux
      - build-windows
    runs-on: ubuntu-22.04
    outputs:
      build_status: ${{ steps.status.outputs.build_status }}
    
    steps:
      - name: Download - All Artifacts
        uses: actions/download-artifact@v5
        with:
          path: artifacts
      
      - name: Validate - Build Artifacts
        id: status
        run: |
          STATUS="success"
          for arch in amd64 arm64v8 armv7; do
            if [ ! -f "artifacts/binaries-linux-$arch/rustdesk-pro" ]; then
              STATUS="failed"
            fi
          done
          if [ ! -f "artifacts/binaries-windows-x86_64/rustdesk-pro.exe" ]; then
            STATUS="failed"
          fi
          echo "build_status=$STATUS" >> $GITHUB_OUTPUT
      
      - name: Fail - On Build Failure
        if: steps.status.outputs.build_status == 'failed'
        run: exit 1

  # P6 - Docker 镜像构建
  docker-build:
    name: P6 - Docker Build (${{ matrix.job.name }})
    needs: 
      - pre-build
      - build-summary
    if: needs.pre-build.outputs.should_deploy == 'true'
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      max-parallel: 5
      matrix:
        job:
          - { name: "amd64",   docker_platform: "linux/amd64" }
          - { name: "arm64v8", docker_platform: "linux/arm64" }
          - { name: "armv7",   docker_platform: "linux/arm/v7" }
    
    steps:
      - name: Checkout - Repository
        uses: actions/checkout@v5
        with:
          submodules: recursive
          fetch-depth: 0
      
      - name: Download - Build Artifacts
        uses: actions/download-artifact@v5
        with:
          name: binaries-linux-${{ matrix.job.name }}
          path: artifacts
      
      - name: Setup - QEMU
        uses: docker/setup-qemu-action@v3
      
      - name: Setup - Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login - GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Login - Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_PASSWORD }}
      
      - name: Build - Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./commercial/docker/Dockerfile.gha
          platforms: ${{ matrix.job.docker_platform }}
          push: true
          tags: |
            ${{ env.DOCKERHUB_IMAGE }}:${{ env.LATEST_TAG }}-${{ matrix.job.name }}
            ${{ env.DOCKERHUB_IMAGE }}:${{ needs.pre-build.outputs.git_tag }}-${{ matrix.job.name }}
            ${{ env.GHCR_IMAGE }}:${{ env.LATEST_TAG }}-${{ matrix.job.name }}
            ${{ env.GHCR_IMAGE }}:${{ needs.pre-build.outputs.git_tag }}-${{ matrix.job.name }}

  # P7 - Docker Manifest
  docker-manifest:
    name: P7 - Docker Manifest
    needs: 
      - pre-build
      - docker-build
    runs-on: ubuntu-latest
    if: needs.pre-build.outputs.should_deploy == 'true'
    
    steps:
      - name: Checkout - Repository
        uses: actions/checkout@v5
        with:
          fetch-depth: 0
      
      - name: Login - Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_PASSWORD }}
      
      - name: Login - GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: changsongyang
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Create - Docker Hub Version Manifest
        uses: Noelware/docker-manifest-action@0.4.3
        with:
          base-image: ${{ env.DOCKERHUB_IMAGE }}:${{ needs.pre-build.outputs.git_tag }}
          extra-images: ${{ env.DOCKERHUB_IMAGE }}:${{ needs.pre-build.outputs.git_tag }}-amd64,${{ env.DOCKERHUB_IMAGE }}:${{ needs.pre-build.outputs.git_tag }}-arm64v8,${{ env.DOCKERHUB_IMAGE }}:${{ needs.pre-build.outputs.git_tag }}-armv7
          push: true
      
      - name: Create - Docker Hub Latest Manifest
        uses: Noelware/docker-manifest-action@0.4.3
        with:
          base-image: ${{ env.DOCKERHUB_IMAGE }}:${{ env.LATEST_TAG }}
          extra-images: ${{ env.DOCKERHUB_IMAGE }}:${{ env.LATEST_TAG }}-amd64,${{ env.DOCKERHUB_IMAGE }}:${{ env.LATEST_TAG }}-arm64v8,${{ env.DOCKERHUB_IMAGE }}:${{ env.LATEST_TAG }}-armv7
          push: true
```

### 11.3 多阶段构建工作流示例

```yaml
name: Multi-Stage Build

on:
  push:
    branches: [main]
  pull_request:

env:
  CARGO_TERM_COLOR: always

jobs:
  # 阶段 1: 准备
  prepare:
    name: Stage 1 - Prepare
    runs-on: ubuntu-latest
    outputs:
      build_id: ${{ steps.vars.outputs.build_id }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Generate Build ID
        id: vars
        run: |
          BUILD_ID=$(date +%Y%m%d%H%M%S)
          echo "build_id=$BUILD_ID" >> $GITHUB_OUTPUT

      - name: Display Info
        run: |
          echo "Build ID: $BUILD_ID"
          echo "Triggered by: ${{ github.actor }}"
          echo "Event: ${{ github.event_name }}"

  # 阶段 2: 多平台并行构建
  build:
    name: Stage 2 - Build (${{ matrix.platform }})
    needs: prepare
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        platform:
          - linux/amd64
          - linux/arm64
          - windows/amd64
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Rust
        uses: dtolnay/rust-toolchain@stable
        with:
          targets: ${{ matrix.platform == 'linux/amd64' && 'x86_64-unknown-linux-musl' || matrix.platform == 'linux/arm64' && 'aarch64-unknown-linux-musl' || 'x86_64-pc-windows-msvc' }}
      
      - name: Build
        run: cargo build --release
      
      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: build-${{ matrix.platform }}-${{ needs.prepare.outputs.build_id }}
          path: target/release/*

  # 阶段 3: 测试
  test:
    name: Stage 3 - Test
    needs: build
    runs-on: ubuntu-latest
    
    steps:
      - name: Download Artifacts
        uses: actions/download-artifact@v4
        with:
          path: artifacts
      
      - name: Run Tests
        run: |
          echo "Testing all artifacts..."
          for dir in artifacts/build-*; do
            echo "Testing $dir"
          done

  # 阶段 4: 部署
  deploy:
    name: Stage 4 - Deploy
    needs: [prepare, test]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    
    steps:
      - name: Download Artifacts
        uses: actions/download-artifact@v4
        with:
          path: artifacts
      
      - name: Deploy
        run: |
          echo "Deploying with Build ID: ${{ needs.prepare.outputs.build_id }}"
          echo "Deploying to production..."

  # 阶段 5: 清理
  cleanup:
    name: Stage 5 - Cleanup
    needs: [prepare, deploy]
    if: always()
    runs-on: ubuntu-latest
    
    steps:
      - name: Cleanup
        run: |
          echo "Cleaning up..."
          echo "Build ID: ${{ needs.prepare.outputs.build_id }}"
          echo "Deploy status: ${{ needs.deploy.result }}"
```

---

## 附录：常用表达式参考

### GitHub 上下文变量

```yaml
# 仓库信息
${{ github.repository }}      # owner/repo
${{ github.repository_owner }} # owner

# 事件信息
${{ github.event_name }}      # push, pull_request, etc.
${{ github.ref }}             # refs/heads/main
${{ github.ref_name }}        # main
${{ github.ref_type }}       # branch or tag
${{ github.sha }}             # 提交 SHA
${{ github.actor }}          # 触发用户
${{ github.triggering_actor }} # 触发工作流的用户

# 工作流信息
${{ workflow }}               # 工作流名称
${{ run_id }}                 # 运行 ID
${{ run_number }}             # 运行编号
${{ job }}                    # Job 名称

# 环境信息
${{ runner.os }}              # Linux, Windows, macOS
${{ runner.arch }}            # X64, ARM64
${{ runner.temp }}/           # 临时目录
```

### 函数参考

| 函数 | 说明 | 示例 |
|------|------|------|
| `contains()` | 字符串包含 | `contains(github.event.head_commit.message, 'deploy')` |
| `startsWith()` | 字符串开头 | `startsWith(github.ref, 'refs/tags/')` |
| `endsWith()` | 字符串结尾 | `endsWith(github.ref, 'v1.0.0')` |
| `join()` | 数组转字符串 | `join(needs.*.result, ',')` |
| `toJSON()` | 对象转 JSON | `toJSON(github.event)` |
| `fromJSON()` | JSON 转对象 | `fromJSON('{"a":1}')` |
