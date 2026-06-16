# GitHub Actions Workflow - 运维文档

**工作流文件**：`commercial-build-deploy.yml`
**目标读者**：运维工程师、DevOps 工程师、SRE

---

## 1. 维护指南

### 1.1 日常维护任务

| 任务 | 频率 | 操作 |
|-----|------|------|
| 检查工作流运行状态 | 每日 | GitHub Actions 标签页 |
| 审查失败日志 | 每次失败 | 下载 artifacts 查看日志 |
| 更新 Actions 版本 | 每月 | 修改 `uses:` 字段 |
| 更新 Runner 版本 | 季度 | 修改 `runs-on:` 字段 |
| 审查依赖项 | 每月 | 检查 Cargo.lock |
| 验证 Secrets 有效性 | 每月 | 手动触发测试 |

### 1.2 版本更新流程

```bash
# 1. 拉取最新代码
cd "c:\Users\ycsit\Downloads\rustdesk\rustdesk-server"
git pull origin main

# 2. 编辑工作流文件
code .github/workflows/commercial-build-deploy.yml

# 3. 验证 YAML 语法
# 使用 GitHub Actions 内置的 YAML 验证器

# 4. 提交更改
git add .github/workflows/commercial-build-deploy.yml
git commit -m "chore: 更新 Actions 版本"

# 5. 推送到远程
git push changsongyang main
```

### 1.3 修改任务依赖关系

**场景**：添加新的依赖关系

```yaml
# 步骤 1：编辑目标任务的 needs 字段
my-new-job:
  needs:
    - pre-build
    - code-quality
    - build-linux  # 新增依赖
```

**场景**：移除任务之间的依赖

```yaml
# 步骤 1：编辑目标任务的 needs 字段
my-job:
  needs:
    - pre-build
  # 移除其他依赖，使其与 pre-build 同时执行
```

### 1.4 添加新的矩阵项

```yaml
# 在 matrix.job 中添加新条目
matrix:
  job:
    - { name: "amd64",   target: "x86_64-unknown-linux-musl" }
    - { name: "arm64v8", target: "aarch64-unknown-linux-musl" }
    - { name: "new-arch", target: "new-target-triple" }  # 新增
```

**注意事项**：
- 新增的 `name` 必须唯一
- `target` 必须是有效的 Rust target triple
- 验证 cross-compilation 工具链可用

---

## 2. 故障排除指南

### 2.1 常见问题及解决方案

#### 问题 1: workflow 不触发

**症状**：推送代码后工作流未运行

**可能原因**：
- 推送的分支不在触发器配置中
- workflow 文件有语法错误
- 仓库 Actions 被禁用

**排查步骤**：
```bash
# 1. 检查推送的分支
git branch --show-current

# 2. 验证 workflow 文件语法
# 在 GitHub 仓库的 Actions 页面查看是否有错误

# 3. 检查仓库设置
# Settings -> Actions -> General -> Allow all actions
```

#### 问题 2: pre-build 失败

**症状**：P1 任务失败，输出 `Error: Process completed with exit code 1`

**可能原因**：
- 环境变量未正确设置
- Git Tag 格式不匹配
- 输入参数缺失

**排查步骤**：
1. 查看 pre-build 的 Debug 日志
2. 检查 `GITHUB_REF` 和 `GITHUB_EVENT_NAME` 是否正确
3. 验证 `inputs.trigger_type` 和 `inputs.version` 值

#### 问题 3: Debian 包构建失败

**症状**：`dpkg-deb: error: parsing file 'debian-package/DEBIAN/control'`

**可能原因**：
- 版本号不符合 Debian 规范（必须以数字开头）
- control 文件格式错误

**解决方案**：
```bash
# 检查版本号格式
echo $DEB_VERSION

# 预期格式（以数字开头）
# 1.0.0
# 0.0.20260616123456.abc12345

# 错误格式
# dev-abc12345
# pro-v1.0.0 (在移除前缀前)
```

#### 问题 4: Docker 构建失败 - Dockerfile 缺失

**症状**：`failed to read dockerfile: open Dockerfile.extended: no such file or directory`

**解决方案**：
```bash
# 创建缺失的 Dockerfile
touch commercial/docker/Dockerfile.extended
```

#### 问题 5: 开发构建跳过 P5-P8 任务

**症状**：分支推送后，只有 P1-P4 执行，P5-P8 全部跳过

**根本原因**：`pre-build` 的 `artifact-control` 步骤将 `should_build_*` 设置为 `false`

**解决方案**：
检查 [commercial-build-deploy.yml](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/commercial-build-deploy.yml#L267) 第267-317行的 `artifact-control` 步骤：

```yaml
# 正确配置（所有构建都生成产物）
SHOULD_BUILD_DEB="${{ inputs.build_deb || 'true' }}"
SHOULD_BUILD_DOCKER="${{ inputs.build_docker || 'true' }}"
```

#### 问题 6: 任务超时

**症状**：`Error: The operation was canceled.`

**解决方案**：
- 增加任务的 `timeout-minutes` 值
- 优化构建步骤以减少执行时间
- 考虑使用矩阵拆分长时间任务

#### 问题 7: 镜像推送失败

**症状**：`denied: requested access to the resource is denied`

**可能原因**：
- 缺少 `packages: write` 权限
- GHCR 认证失败
- 镜像名称不符合规范

**解决方案**：
```yaml
# 确保 workflow 开头有正确的权限
permissions:
  contents: write
  packages: write
  pull-requests: read
```

### 2.2 日志分析技巧

#### 启用调试日志

在仓库的 Secrets 中添加：
- `ACTIONS_STEP_DEBUG`: `true`
- `ACTIONS_RUNNER_DEBUG`: `true`

#### 关键日志关键词

| 关键词 | 含义 |
|-------|------|
| `[INFO]` | 普通信息日志 |
| `[ERROR]` | 错误日志 |
| `Build Status:` | 构建状态汇总 |
| `should_deploy:` | 部署决策 |
| `should_build_deb:` | DEB 包构建决策 |
| `P1 - Pre-Build` | 预构建阶段 |
| `P3 - Build` | 构建阶段 |
| `P5 - Debian` | Debian 包阶段 |

#### 常见错误模式

```bash
# 查找错误日志
gh run view --log-failed

# 下载日志
gh run download <run-id>

# 查看特定任务
gh run view --job=<job-id>
```

### 2.3 紧急回滚

**场景**：发布的关键版本有问题，需要快速回滚

```bash
# 方法 1：创建紧急修复分支并推送 tag
git checkout main
git pull
# 应用紧急修复
git commit -m "hotfix: 紧急修复"
git tag pro-v1.0.1
git push origin pro-v1.0.1

# 方法 2：手动触发旧版本的重新构建
# 在 GitHub Actions 页面选择 "Run workflow"
# 选择 trigger_type=tag
# 选择上一个稳定的 git_tag
```

---

## 3. 性能优化

### 3.1 缓存策略

#### Cargo 缓存

使用 `Swatinem/rust-cache` 自动管理：

```yaml
- name: Cache - Cargo Dependencies
  uses: Swatinem/rust-cache@v2
  with:
    key: ${{ runner.os }}-cargo-${{ matrix.job.target }}
```

#### Docker 缓存

使用 GitHub Actions 缓存：

```yaml
- name: Build - Docker Image
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### 3.2 并行化优化

**已实现的并行**：
- P1 (pre-build) 与 P2 (code-quality) 并行
- P3a (build-linux) 多架构矩阵内并行
- P3b (build-windows) 与 P3a 并行
- P7a (docker-build-base) 与 P7b (docker-build-extended) 并行

**进一步优化建议**：
1. 将 build-linux 和 build-windows 完全独立
2. 将 deb-package 与 docker-build 并行启动
3. 考虑拆分 docker-build 为更细粒度的任务

### 3.3 资源限制

| 资源 | 限制 | 应对策略 |
|-----|------|---------|
| 并发任务数 | 5 | 合理设计矩阵 |
| 单任务超时 | 默认 6h | 设置合理的 timeout-minutes |
| Artifact 大小 | 500MB | 清理中间产物 |
| API 速率限制 | 1000/h | 缓存 API 调用结果 |

---

## 4. 安全最佳实践

### 4.1 Secrets 管理

```bash
# 添加新的 Secret
gh secret set MY_SECRET

# 查看现有 Secrets（仅名称）
gh secret list

# 删除 Secret
gh secret remove MY_SECRET
```

### 4.2 权限最小化

```yaml
# 在 workflow 开头明确指定权限
permissions:
  contents: write
  packages: write
  pull-requests: read
```

### 4.3 第三方 Action 审计

- 定期审查使用的第三方 Action
- 固定 Action 到具体的 commit SHA（而非标签）
- 订阅 Action 的安全公告

```yaml
# 推荐：固定到 commit SHA
- uses: actions/checkout@a1b2c3d4...  # 具体 SHA
```

### 4.4 镜像安全扫描

工作流已集成 Trivy 扫描：

```yaml
- name: Scan - Docker Image Vulnerabilities
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.DOCKERHUB_IMAGE }}:${{ env.GIT_TAG }}'
    format: 'sarif'
    severity: 'CRITICAL,HIGH'
```

**审查扫描结果**：
1. 下载 `trivy-results.sarif` artifact
2. 使用 SARIF 查看器分析
3. 根据严重程度决定是否阻断发布

---

## 5. 监控与告警

### 5.1 工作流状态监控

**推荐工具**：
- GitHub Actions 徽章
- 第三方监控服务（如 Datadog、New Relic）
- 自定义 webhook 通知

### 5.2 失败告警

```yaml
# 在 workflow 末尾添加
- name: Notify - Failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Workflow ${{ github.workflow }} failed on ${{ github.ref }}"
      }
```

### 5.3 关键指标

| 指标 | 阈值 | 告警级别 |
|-----|------|---------|
| 工作流成功率 | < 80% | 警告 |
| 平均执行时间 | > 60 分钟 | 警告 |
| 关键任务失败 | 任意 | 严重 |
| 镜像安全扫描 | CRITICAL > 0 | 严重 |

---

## 6. 变更管理

### 6.1 变更流程

```
1. 创建变更请求（PR）
   ↓
2. 团队审查
   ↓
3. 测试（手动触发测试运行）
   ↓
4. 合并到 main
   ↓
5. 监控生产环境
```

### 6.2 重大变更检查清单

- [ ] 已更新相关文档
- [ ] 已通知相关干系人
- [ ] 已在测试分支验证
- [ ] 已准备回滚计划
- [ ] 已配置临时监控

### 6.3 文档更新要求

每次重大变更后，必须更新：
- 本文档（运维文档）
- [WORKFLOW_IMPLEMENTATION.md](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/docs/WORKFLOW_IMPLEMENTATION.md)
- [WORKFLOW_USER_GUIDE.md](file:///C:/Users/ycsit/Downloads/rustdesk/rustdesk-server/.github/workflows/docs/WORKFLOW_USER_GUIDE.md)
- 规格文档（`spec.md`）

---

## 7. 联系与支持

### 7.1 内部支持

- **工作流所有者**：DevOps 团队
- **业务联系人**：产品团队
- **紧急联系**：on-call 工程师

### 7.2 外部资源

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Docker Buildx 文档](https://docs.docker.com/buildx/)
- [Debian 包规范](https://www.debian.org/doc/debian-policy/ch-controlfields.html)

---

## 8. 附录

### 8.1 完整任务列表

| # | 任务 ID | 类型 | 描述 |
|---|---------|------|------|
| 1 | pre-build | 准备 | 版本管理、触发检测 |
| 2 | code-quality | 检查 | Rustfmt、Clippy |
| 3 | build-linux | 构建 | Linux 多架构 |
| 4 | build-windows | 构建 | Windows x86_64 |
| 5 | build-summary | 汇总 | 验证产物 |
| 6 | deb-package | 产物 | Debian 包构建 |
| 7 | github-release | 发布 | GitHub Release |
| 8 | docker-build-base | 产物 | 基础 Docker 镜像 |
| 9 | docker-build-extended | 产物 | 拓展 Docker 镜像 |
| 10 | docker-manifest-base | 产物 | 基础镜像清单 |
| 11 | docker-manifest-extended | 产物 | 拓展镜像清单 |
| 12 | deploy-summary | 部署 | 最终汇总 |

### 8.2 故障排除快速参考

| 症状 | 检查点 | 命令 |
|-----|-------|------|
| 工作流未触发 | 分支名匹配 | `git branch --show-current` |
| 构建失败 | 查看日志 | `gh run view --log` |
| 镜像推送失败 | Token 权限 | `gh auth status` |
| 版本号错误 | 触发方式 | 查看 Debug 日志 |
| 超时 | timeout-minutes | 检查任务配置 |
