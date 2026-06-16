# GitHub Actions Workflow - 实现文档

**工作流文件**：`commercial-build-deploy.yml`
**路径**：[commercial-build-deploy.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-build-deploy.yml)
**版本**：v1.0
**最后更新**：2026-06-16

---

## 1. 概述

本文档详细描述 RustDesk Pro Server 的 CI/CD 工作流架构、关键组件、条件逻辑和集成点，供开发团队和运维人员参考。

### 1.1 工作流目的

该工作流实现了 RustDesk Pro Server 商业版的完整持续集成和持续部署流程，包括：

- 多平台代码构建（Linux x86_64/ARM64/ARMv7、Windows x86_64）
- 代码质量检查（Rustfmt、Clippy）
- 多种产物生成（Debian 包、Docker 镜像）
- 自动版本管理和多渠道发布
- 灵活的手动触发控制

### 1.2 工作流标识

| 属性 | 值 |
|-----|---|
| 名称 | Commercial Build and Deploy |
| 文件名 | `commercial-build-deploy.yml` |
| 触发类型 | 推送（自动）+ 工作流派发（手动） |
| 并发模式 | 分组排队 |

---

## 2. 架构设计

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                     触发器层 (Triggers)                      │
│  ┌──────────────────┐              ┌──────────────────┐    │
│  │  Push (自动触发)  │              │ workflow_dispatch │    │
│  │  - 分支推送       │              │   (手动触发)      │    │
│  │  - 标签推送       │              │                  │    │
│  └────────┬─────────┘              └────────┬─────────┘    │
└───────────┼──────────────────────────────────┼──────────────┘
            │                                  │
            └──────────────┬───────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   并行执行层 (P1-P2)                          │
│  ┌─────────────────────┐      ┌─────────────────────┐       │
│  │  P1 - Pre-Build      │      │ P2 - Code Quality   │       │
│  │  - 版本号提取        │      │ - Rustfmt 检查      │       │
│  │  - 触发类型判断      │      │ - Clippy 静态分析   │       │
│  │  - 产物控制逻辑      │      │ - 类型检查          │       │
│  │  - 输出参数设置      │      │ - 代码格式化验证    │       │
│  └──────────┬──────────┘      └──────────┬──────────┘       │
└─────────────┼─────────────────────────────┼─────────────────┘
              │                             │
              └─────────────┬───────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   构建执行层 (P3-P4)                          │
│  ┌──────────────────────┐    ┌──────────────────────┐       │
│  │ P3a - Build Linux     │    │ P3b - Build Windows  │       │
│  │  - amd64              │    │  - x86_64            │       │
│  │  - arm64v8            │    │                      │       │
│  │  - armv7              │    │                      │       │
│  └──────────┬──────────┘    └──────────┬──────────┘       │
│             │                            │                  │
│             └────────────┬───────────────┘                  │
│                          ▼                                  │
│              ┌──────────────────────┐                       │
│              │ P4 - Build Summary   │                       │
│              │  - 验证所有产物       │                       │
│              │  - 汇总构建状态       │                       │
│              └──────────┬──────────┘                       │
└─────────────────────────┼──────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   产物生成层 (P5-P8)                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ P5 - DEB  │  │ P7a-Base │  │ P7b-Ext  │  │ P6-Rel   │    │
│  │  Package  │  │  Docker  │  │  Docker  │  │ GitHub   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌──────────────────────┐
              │  P9 - Deploy Summary │
              │   最终汇总与通知      │
              └──────────────────────┘
```

### 2.2 任务层次结构

| 阶段 | 任务 ID | 任务名称 | 并行类型 | 优先级 |
|-----|---------|---------|---------|--------|
| 准备 | P1 | pre-build | 与 P2 并行 | 高 |
| 准备 | P2 | code-quality | 与 P1 并行 | 高 |
| 构建 | P3a | build-linux | 矩阵内并行 | 中 |
| 构建 | P3b | build-windows | 与 P3a 并行 | 中 |
| 汇总 | P4 | build-summary | 等待所有构建 | 中 |
| 产物 | P5 | deb-package | 矩阵内并行 | 低 |
| 产物 | P6 | github-release | 等待 P5 | 低 |
| 产物 | P7a | docker-build-base | 矩阵内并行 | 低 |
| 产物 | P7b | docker-build-extended | 矩阵内并行 | 低 |
| 产物 | P8a | docker-manifest-base | 等待 P7a | 低 |
| 产物 | P8b | docker-manifest-extended | 等待 P7b | 低 |
| 部署 | P9 | deploy-summary | 等待所有产物 | 最高 |

---

## 3. 关键组件详解

### 3.1 触发器配置

#### 自动触发器

**分支推送触发**（开发构建）：
```yaml
push:
  branches:
    - main
    - master
    - develop
    - development
    - feature/**
    - feat/**
    - fix/**
    - bugfix/**
    - hotfix/**
    - release/**
    - dev/**
    - wip/**
```

**标签推送触发**（生产构建）：
```yaml
push:
  tags:
    - pro-v*
    - pro-*
```

#### 手动触发器

```yaml
workflow_dispatch:
  inputs:
    trigger_type:        # 触发类型选择
      type: choice
      options:
        - branch_with_version  # 带版本号的分支
        - branch_no_version    # 不带版本号的分支
        - tag                  # 标签
    
    version:             # 手动指定的版本号
      type: string
      required: false
    
    git_tag:             # 手动选择已有标签
      type: string
      required: false
    
    build_deb:           # 是否构建 Debian 包
      type: boolean
      default: true
    
    build_docker:        # 是否构建 Docker 镜像
      type: boolean
      default: true
    
    docker_image_type:   # Docker 镜像类型
      type: choice
      options:
        - both        # 基础 + 拓展
        - base        # 仅基础
        - extended    # 仅拓展
      default: both
```

### 3.2 版本管理组件

#### 版本号提取规则

| 输入来源 | 处理逻辑 | 输出 |
|---------|---------|------|
| Git Tag | 直接使用 tag 名 | `git_tag=pro-v1.0.0` |
| 手动 version | 使用输入值 | `git_tag=v1.0.0` |
| 手动 git_tag | 使用输入值 | `git_tag=pro-v1.0.0` |
| 分支推送 | 生成开发版本 | `git_tag=dev-{SHA前8位}` |

#### Debian 版本标准化

```bash
VERSION=${T#pro-v}        # 移除 pro-v 前缀
VERSION=${VERSION#pro-}   # 移除 pro- 前缀
VERSION=${VERSION#v}      # 移除 v 前缀

# 验证是否符合 Debian 版本规范
if [[ ! "$VERSION" =~ ^[0-9] ]]; then
  DEBIAN_VERSION="0.0.$(date +%Y%m%d%H%M%S).${GITHUB_SHA::8}"
fi
```

### 3.3 产物控制组件

#### 控制变量

| 变量名 | 类型 | 说明 | 默认值 |
|-------|------|------|--------|
| `should_deploy` | boolean | 是否执行部署 | 基于构建类型 |
| `should_build_deb` | boolean | 是否构建 DEB 包 | true |
| `should_build_base_image` | boolean | 是否构建基础镜像 | true |
| `should_build_extended_image` | boolean | 是否构建拓展镜像 | true |

#### 决策矩阵

| 触发方式 | build_type | should_build_deb | should_build_base | should_build_extended |
|---------|-----------|------------------|-------------------|----------------------|
| push tag | prod | true | true | true |
| push branch | dev | true | true | true |
| branch_with_version | prod | true | true | true |
| branch_no_version | dev | true | true | true |
| manual tag | prod | true | true | true |

### 3.4 矩阵构建配置

#### Linux 构建矩阵

```yaml
matrix:
  job:
    - { name: "amd64",   target: "x86_64-unknown-linux-musl" }
    - { name: "arm64v8", target: "aarch64-unknown-linux-musl" }
    - { name: "armv7",   target: "armv7-unknown-linux-musleabihf" }
```

#### Docker 构建矩阵

```yaml
matrix:
  job:
    - { name: "amd64",   docker_platform: "linux/amd64" }
    - { name: "arm64v8", docker_platform: "linux/arm64" }
    - { name: "armv7",   docker_platform: "linux/arm/v7" }
```

---

## 4. 条件逻辑详解

### 4.1 任务执行条件

| 任务 | 执行条件 |
|-----|---------|
| `pre-build` | 始终执行 |
| `code-quality` | 始终执行（与 pre-build 并行） |
| `build-linux` | `pre-build` AND `code-quality` 都成功 |
| `build-windows` | `pre-build` AND `code-quality` 都成功 |
| `build-summary` | `pre-build`、`build-linux`、`build-windows` 都完成 |
| `deb-package` | `should_build_deb == 'true'` AND `has_artifacts == 'true'` |
| `docker-build-base` | `should_build_base_image == 'true'` AND `has_artifacts == 'true'` |
| `docker-build-extended` | `should_build_extended_image == 'true'` AND `has_artifacts == 'true'` |
| `github-release` | `should_build_deb == 'true'` AND `has_artifacts == 'true'` |
| `deploy-summary` | `should_deploy == 'true'` |

### 4.2 失败处理策略

| 失败位置 | 后续任务 | 策略 |
|---------|---------|------|
| pre-build 失败 | 所有任务 | 全部跳过 |
| code-quality 失败 | build-* | 跳过构建 |
| build-linux 部分失败 | build-summary | 继续执行，标记部分失败 |
| build-windows 失败 | build-summary | 继续执行，标记部分失败 |
| deb-package 失败 | 后续任务 | 部分跳过 |

---

## 5. 集成点

### 5.1 外部服务集成

| 服务 | 用途 | 认证方式 |
|-----|------|---------|
| GitHub Container Registry (GHCR) | 存储 Docker 镜像 | GITHUB_TOKEN |
| Docker Hub | 存储 Docker 镜像 | secrets.DOCKER_HUB_USERNAME/PASSWORD |
| GitHub Releases | 存储发布产物 | GITHUB_TOKEN |
| Trivy | 镜像安全扫描 | 内置 |

### 5.2 必需的 Secrets

| Secret 名称 | 用途 | 是否必需 |
|------------|------|---------|
| `GITHUB_TOKEN` | 自动提供 | 是 |
| `DOCKER_HUB_USERNAME` | Docker Hub 登录 | 可选 |
| `DOCKER_HUB_PASSWORD` | Docker Hub 登录 | 可选 |

### 5.3 必需的权限

```yaml
permissions:
  contents: write        # 创建 Release
  packages: write        # 推送 Docker 镜像
  pull-requests: read    # 读取 PR 信息
```

---

## 6. 输出与产物

### 6.1 任务输出 (Outputs)

| 任务 | 输出名称 | 类型 | 说明 |
|-----|---------|------|------|
| pre-build | `build_id` | string | 唯一构建 ID |
| pre-build | `git_tag` | string | Git 标签 |
| pre-build | `deb_version` | string | Debian 版本号 |
| pre-build | `build_type` | string | 构建类型（prod/dev） |
| pre-build | `should_deploy` | boolean | 是否部署 |
| pre-build | `should_build_deb` | boolean | 是否构建 DEB |
| pre-build | `should_build_base_image` | boolean | 是否构建基础镜像 |
| pre-build | `should_build_extended_image` | boolean | 是否构建拓展镜像 |

### 6.2 生成的产物

| 产物类型 | 命名格式 | 存储位置 |
|---------|---------|---------|
| Linux 二进制 | `binaries-linux-{arch}` | GitHub Artifacts |
| Windows 二进制 | `binaries-windows-x86_64` | GitHub Artifacts |
| Debian 包 | `rustdesk-pro-server_{version}_{arch}.deb` | GitHub Artifacts + Release |
| 基础 Docker 镜像 | `{registry}/rustdesk-pro-server:{tag}-{arch}` | GHCR + Docker Hub |
| 拓展 Docker 镜像 | `{registry}/rustdesk-pro-server:{tag}-extended-{arch}` | GHCR + Docker Hub |
| Trivy 扫描报告 | `trivy-results.sarif` | GitHub Artifacts |

---

## 7. 性能指标

### 7.1 执行时间目标

| 阶段 | 目标时间 | 实际时间（参考） |
|-----|---------|----------------|
| P1-P2（并行） | < 3 分钟 | 2-3 分钟 |
| P3（构建） | < 25 分钟 | 15-20 分钟 |
| P4（汇总） | < 2 分钟 | 1-2 分钟 |
| P5-P7（产物） | < 15 分钟 | 10-15 分钟 |
| P9（部署汇总） | < 2 分钟 | 1 分钟 |
| **总计** | **< 50 分钟** | **30-40 分钟** |

### 7.2 资源使用

| 资源类型 | 用途 | 规格 |
|---------|------|------|
| GitHub Actions Runner | 所有任务 | ubuntu-22.04 / windows-2022 |
| 并发任务数 | 受限于 GitHub 计划 | 最多 5 个并行 |
| 缓存策略 | Cargo 依赖 | Swatinem/rust-cache |

---

## 8. 错误码定义

| 错误码 | 描述 | 触发条件 |
|-------|------|---------|
| P001 | 预构建失败 | 版本号提取失败 |
| P002 | 代码质量检查失败 | Rustfmt/Clippy 错误 |
| P003 | Linux 构建失败 | 编译错误 |
| P004 | Windows 构建失败 | 编译错误 |
| P005 | Debian 包构建失败 | dpkg-deb 错误 |
| P006 | Docker 构建失败 | buildx 错误 |
| P007 | Release 创建失败 | GitHub API 错误 |
| P008 | 镜像推送失败 | Registry 错误 |

---

## 9. 扩展点

### 9.1 添加新的构建架构

```yaml
matrix:
  job:
    - { name: "amd64",   target: "x86_64-unknown-linux-musl" }
    - { name: "arm64v8", target: "aarch64-unknown-linux-musl" }
    - { name: "armv7",   target: "armv7-unknown-linux-musleabihf" }
    - { name: "riscv64", target: "riscv64gc-unknown-linux-gnu" }  # 新增
```

### 9.2 添加新的产物类型

1. 在 pre-build 中添加 `should_build_xxx` output
2. 添加新的 job，配置适当的依赖
3. 更新 deploy-summary 的依赖列表

### 9.3 集成新的 Registry

在 `docker-build-*` 任务中添加新的 login-action 和 push 目标。

---

## 10. 最佳实践

1. **版本号管理**：始终使用语义化版本（SemVer）
2. **缓存策略**：使用 Swatinem/rust-cache 加速构建
3. **并行执行**：最大化任务并行度以缩短总时间
4. **错误处理**：关键任务使用 `continue-on-error: false`
5. **日志记录**：所有关键步骤添加 `[INFO]`/`[ERROR]` 标记
6. **安全扫描**：使用 Trivy 扫描 Docker 镜像
7. **可观测性**：使用 GitHub Actions 摘要功能汇总结果
