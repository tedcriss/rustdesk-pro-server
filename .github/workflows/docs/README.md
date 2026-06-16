# GitHub Actions Workflow 文档索引

本目录包含 `commercial-build-deploy.yml` 工作流的完整文档。

## 文档列表

### 1. [WORKFLOW_IMPLEMENTATION.md](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/docs/WORKFLOW_IMPLEMENTATION.md)
**目标读者**：开发团队、架构师、技术负责人

**内容**：
- 工作流架构设计
- 关键组件详解
- 条件逻辑说明
- 集成点说明
- 性能指标
- 错误码定义
- 扩展点指南

### 2. [WORKFLOW_OPERATIONS.md](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/docs/WORKFLOW_OPERATIONS.md)
**目标读者**：运维工程师、DevOps 工程师、SRE

**内容**：
- 日常维护指南
- 故障排除手册
- 性能优化建议
- 安全最佳实践
- 监控与告警
- 变更管理流程
- 紧急回滚流程

### 3. [WORKFLOW_USER_GUIDE.md](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/docs/WORKFLOW_USER_GUIDE.md)
**目标读者**：开发人员、产品经理、最终用户

**内容**：
- 工作流简介
- 快速开始指南
- 输入要求说明
- 预期输出说明
- 最佳实践
- 常见问题解答 (FAQ)

## 文档使用建议

| 角色 | 推荐阅读顺序 |
|-----|------------|
| 新成员 | WORKFLOW_USER_GUIDE → WORKFLOW_IMPLEMENTATION → WORKFLOW_OPERATIONS |
| 开发人员 | WORKFLOW_USER_GUIDE → WORKFLOW_IMPLEMENTATION |
| 运维人员 | WORKFLOW_OPERATIONS → WORKFLOW_IMPLEMENTATION |
| 架构师 | WORKFLOW_IMPLEMENTATION → WORKFLOW_OPERATIONS |

## 文档维护

- **更新频率**：每次工作流重大变更后
- **负责人**：DevOps 团队
- **审查周期**：季度审查
- **反馈渠道**：仓库 Issues
