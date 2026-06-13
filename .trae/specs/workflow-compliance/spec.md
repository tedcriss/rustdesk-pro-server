# Workflow合规化规范管理方案 - 产品需求文档

## Overview
- **Summary**: 制定一套全面的合规化规范管理方案，用于管理RustDesk项目workflow打包版本（包括社区版和商业版）的完整生命周期，涵盖构建打包、Docker镜像管理、触发机制和安全审计等方面。
- **Purpose**: 确保所有CI/CD流程符合公司安全合规要求，提供标准化的操作流程和明确的责任界定。
- **Target Users**: 开发团队、运维团队、安全团队、项目管理者

## Goals
- 建立标准化的构建打包流程，确保代码质量和版本一致性
- 制定Docker镜像安全标准和发布流程
- 明确自动触发与手动触发的规范和权限控制
- 实现完整的操作审计和合规追踪

## Non-Goals (Out of Scope)
- 不涉及具体业务逻辑的实现
- 不涉及基础设施部署自动化
- 不涉及第三方服务的接入配置

## Background & Context
- 当前存在版本号管理不一致问题
- Docker构建触发机制存在缺陷
- 缺少统一的合规审计机制
- 需要区分社区版(open-source)和商业版(commercial)的发布流程

## Functional Requirements
- **FR-1**: 构建打包流程标准化，包含代码检查、单元测试、集成测试、版本号生成和打包输出
- **FR-2**: Docker镜像构建标准，包含标签命名规则、安全扫描和镜像仓库发布
- **FR-3**: 自动触发规范，包含触发条件、分支策略和环境隔离
- **FR-4**: 手动触发控制机制，包含权限审批、触发前检查和操作审计
- **FR-5**: 社区版与商业版的差异化管理

## Non-Functional Requirements
- **NFR-1**: 安全性：所有流程必须符合公司安全合规要求
- **NFR-2**: 可追溯性：所有操作必须有完整的审计记录
- **NFR-3**: 可验证性：所有合规检查点必须可验证
- **NFR-4**: 可扩展性：规范必须支持未来扩展

## Constraints
- **Technical**: GitHub Actions环境、Docker容器技术
- **Business**: 公司安全合规政策、审计要求
- **Dependencies**: GitHub Secrets管理、镜像仓库服务

## Assumptions
- GitHub Actions环境已配置
- 必要的Secrets已在仓库中配置
- 团队成员已具备基本的CI/CD知识

## Acceptance Criteria

### AC-1: 构建打包流程标准化
- **Given**: 代码提交到main分支
- **When**: 触发CI工作流
- **Then**: 依次执行代码格式检查、静态分析、单元测试、集成测试、版本号生成、打包输出
- **Verification**: `programmatic`

### AC-2: Docker镜像标签规范
- **Given**: 构建Docker镜像
- **When**: 执行docker-build任务
- **Then**: 镜像标签必须符合`{prefix}-{version}-{arch}`格式，且包含latest标签
- **Verification**: `programmatic`

### AC-3: 镜像安全扫描
- **Given**: Docker镜像构建完成
- **When**: 执行安全扫描任务
- **Then**: 必须通过Trivy安全扫描，CRITICAL和HIGH级别漏洞必须为零
- **Verification**: `programmatic`

### AC-4: 自动触发条件控制
- **Given**: 代码推送到版本库
- **When**: 触发push事件
- **Then**: 只有符合规则的分支(tag: pro-v*, pro-*)才能触发CD流程
- **Verification**: `programmatic`

### AC-5: 手动触发权限控制
- **Given**: 用户尝试手动触发工作流
- **When**: 执行workflow_dispatch
- **Then**: 必须满足前置检查条件，且有完整的操作记录
- **Verification**: `human-judgment`

### AC-6: 操作审计记录
- **Given**: 任何工作流执行
- **When**: 工作流完成
- **Then**: 必须记录触发人、触发时间、执行结果和关键参数
- **Verification**: `human-judgment`

### AC-7: 社区版与商业版隔离
- **Given**: 不同版本的代码提交
- **When**: 触发构建流程
- **Then**: 社区版和商业版的构建流程相互独立，输出产物隔离
- **Verification**: `programmatic`

## Open Questions
- [ ] 是否需要集成企业级权限管理系统？
- [ ] 是否需要与公司现有的审计系统对接？
- [ ] 是否需要多环境部署支持（dev/staging/prod）？
