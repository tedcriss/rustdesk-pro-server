# RustDesk Server 商业版使用手册

| 项目 | 值 |
|-----|---|
| **文档版本** | v1.0 |
| **适用产品** | RustDesk Pro Server |
| **最后更新** | 2026-06-16 |
| **文档状态** | 正式发布 |

---

## 目录

1. [产品概述](#1-产品概述)
2. [系统要求](#2-系统要求)
3. [安装部署](#3-安装部署)
4. [配置指南](#4-配置指南)
5. [功能使用](#5-功能使用)
6. [运维管理](#6-运维管理)
7. [故障排除](#7-故障排除)
8. [附录](#8-附录)

---

## 1. 产品概述

### 1.1 商业版简介

RustDesk Server 商业版是面向企业客户的远程控制服务端解决方案，在社区版基础上提供企业级功能增强、安全加固和管理工具。

**核心价值**：
- 企业级安全：TLS 加密、细粒度访问控制、完整审计日志
- 高可用架构：多节点部署、负载均衡、自动故障转移
- 集中管理：Web 控制台、批量操作、实时监控
- 专业支持：7×24 技术支持、SLA 保障

**目标用户**：
- 企业 IT 部门
- MSSP 安全服务商
- 大型组织运维团队
- 需要合规远程控制解决方案的机构

### 1.2 核心功能

| 功能类别 | 功能项 | 说明 |
|---------|--------|------|
| **用户管理** | 用户账户 | 创建、修改、删除用户账户 |
| | 角色权限 | 管理员/操作员/查看者三级权限 |
| | 组织架构 | 用户分组、部门管理 |
| **设备管理** | 设备注册 | 审批流程、设备白名单 |
| | 设备分组 | 灵活分组、标签管理 |
| | 状态监控 | 实时在线状态、资源使用 |
| **授权管理** | 许可证 | 密钥生成、验证、订阅管理 |
| | 版本分级 | 基础版/专业版/企业版 |
| **安全增强** | 审计日志 | 完整操作记录、查询导出 |
| | 会话录制 | 可选录制、存储管理 |
| | 访问策略 | IP 白名单、时间策略 |
| **高可用** | 集群部署 | 多节点、负载均衡 |
| | 数据同步 | 实时同步、故障转移 |
| | 备份恢复 | 自动备份、一键恢复 |

### 1.3 版本对比

| 功能 | 社区版 | 商业基础版 | 商业专业版 | 商业企业版 |
|------|--------|------------|------------|------------|
| **核心功能** | | | | |
| P2P 连接 | ✅ | ✅ | ✅ | ✅ |
| 中继服务 | ✅ | ✅ | ✅ | ✅ |
| **用户管理** | | | | |
| 用户账户 | ❌ | ✅ | ✅ | ✅ |
| 角色权限 | ❌ | ✅ | ✅ | ✅ |
| 组织架构 | ❌ | ❌ | ✅ | ✅ |
| **设备管理** | | | | |
| 设备注册审批 | ❌ | ✅ | ✅ | ✅ |
| 设备分组 | ❌ | ✅ | ✅ | ✅ |
| 状态监控 | ❌ | ❌ | ✅ | ✅ |
| **安全** | | | | |
| 审计日志 | ❌ | 7天 | 30天 | 90天 |
| 会话录制 | ❌ | ❌ | ✅ | ✅ |
| IP 白名单 | ❌ | ❌ | ✅ | ✅ |
| **支持** | | | | |
| 技术支持 | 社区 | 邮件 | 邮件+电话 | 7×24 专属 |
| SLA | ❌ | 99.5% | 99.9% | 99.99% |

### 1.4 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                      客户端连接层                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │ Windows   │  │ macOS    │  │ Linux    │                 │
│  │ 客户端    │  │ 客户端    │  │ 客户端    │                 │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                 │
└───────┼─────────────┼─────────────┼────────────────────────┘
        │             │             │
        └─────────────┬┴─────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    RustDesk Pro Server                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    控制平面                             │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────┐          │  │
│  │  │ Web API │  │ 用户管理 │  │ 许可证服务   │          │  │
│  │  └────┬────┘  └────┬────┘  └──────┬──────┘          │  │
│  └───────┼────────────┼──────────────┼───────────────────┘  │
│  ┌───────┼────────────┼──────────────┼───────────────────┐  │
│  │       │       数据平面              │                  │  │
│  │  ┌────▼────┐  ┌────▼────┐  ┌──────▼──────┐          │  │
│  │  │  hbbs   │  │  hbbr   │  │  数据库     │          │  │
│  │  │ (ID/Reg)│  │ (Relay) │  │ (SQLite/PG) │          │  │
│  │  └─────────┘  └─────────┘  └─────────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**核心组件说明**：

| 组件 | 名称 | 功能 |
|------|------|------|
| `hbbs` | ID/Rendezvous Server | 客户端身份注册、认证、P2P 打洞协调、NAT 类型检测 |
| `hbbr` | Relay Server | 中继数据转发、带宽限制、黑名单管理 |
| `rustdesk-pro-server` | 商业版管理服务 | 用户管理、设备管理、授权管理、审计日志 |

---

## 2. 系统要求

### 2.1 硬件要求

#### 2.1.1 单节点部署

| 规格 | 最低配置 | 推荐配置 | 高性能配置 |
|------|----------|----------|------------|
| **CPU** | 2 核 | 4 核 | 8 核 |
| **内存** | 2 GB | 4 GB | 8 GB |
| **存储** | 20 GB SSD | 50 GB SSD | 100 GB SSD |
| **网络** | 100 Mbps | 1 Gbps | 10 Gbps |

**适用场景**：
- 最低配置：支持 50 并发连接
- 推荐配置：支持 200 并发连接
- 高性能配置：支持 500+ 并发连接

#### 2.1.2 集群部署（3 节点）

| 规格 | 开发/测试 | 生产标准 | 生产高可用 |
|------|-----------|----------|-----------|
| **CPU** | 4 核/节点 | 8 核/节点 | 16 核/节点 |
| **内存** | 4 GB/节点 | 8 GB/节点 | 16 GB/节点 |
| **存储** | 100 GB SSD | 200 GB SSD | 500 GB SSD |
| **网络** | 1 Gbps | 10 Gbps | 10 Gbps |
| **节点数** | 3 | 3 | 5+ |

### 2.2 软件要求

#### 2.2.1 操作系统

| 操作系统 | 版本 | 支持状态 |
|----------|------|----------|
| **Ubuntu** | 20.04 / 22.04 / 24.04 | ✅ 完全支持 |
| **Debian** | 10 / 11 / 12 | ✅ 完全支持 |
| **CentOS** | 7 / 8 | ✅ 完全支持 |
| **Rocky Linux** | 8 / 9 | ✅ 完全支持 |
| **AlmaLinux** | 8 / 9 | ✅ 完全支持 |
| **Fedora** | 38 / 39 / 40 | ✅ 完全支持 |
| **Windows Server** | 2019 / 2022 | ✅ 完全支持 |

#### 2.2.2 运行时环境

| 环境 | 版本要求 | 说明 |
|------|----------|------|
| **Docker** | 20.10+ | 容器化部署必需 |
| **Docker Compose** | 2.0+ | docker-compose 部署必需 |
| **Kubernetes** | 1.21+ | K8s 部署必需 |
| **kubectl** | 与 K8s 匹配 | K8s 管理必需 |

#### 2.2.3 数据库（可选）

| 数据库 | 版本 | 用途 |
|--------|------|------|
| **SQLite** | 3.x | 默认内置，适合单节点 |
| **PostgreSQL** | 14+ | 集群部署必需 |

### 2.3 网络要求

#### 2.3.1 端口要求

| 端口 | 服务 | 协议 | 用途 | 必需 |
|------|------|------|------|------|
| 21114 | hbbs | TCP | 心跳服务 | ✅ |
| 21115 | hbbs | TCP | API 服务 | ✅ |
| 21116 | hbbs | TCP/UDP | Rendezvous | ✅ |
| 21117 | hbbr | TCP | Relay 服务 | ✅ |
| 21118 | hbbs | TCP | 备用端口 | ❌ |
| 21119 | hbbs | TCP | 备用端口 | ❌ |

#### 2.3.2 防火墙配置

**Linux (iptables)**：
```bash
# 允许必需端口
iptables -A INPUT -p tcp --dport 21114 -j ACCEPT
iptables -A INPUT -p tcp --dport 21115 -j ACCEPT
iptables -A INPUT -p tcp --dport 21116 -j ACCEPT
iptables -A INPUT -p udp --dport 21116 -j ACCEPT
iptables -A INPUT -p tcp --dport 21117 -j ACCEPT
```

**Linux (firewalld)**：
```bash
# 添加服务规则
firewall-cmd --permanent --add-port=21114/tcp
firewall-cmd --permanent --add-port=21115/tcp
firewall-cmd --permanent --add-port=21116/tcp
firewall-cmd --permanent --add-port=21116/udp
firewall-cmd --permanent --add-port=21117/tcp
firewall-cmd --reload
```

**Windows Firewall**：
```powershell
# 添加入站规则
New-NetFirewallRule -DisplayName "RustDesk Server" -Direction Inbound `
  -Protocol TCP -LocalPort 21114,21115,21116,21117 -Action Allow
New-NetFirewallRule -DisplayName "RustDesk Server UDP" -Direction Inbound `
  -Protocol UDP -LocalPort 21116 -Action Allow
```

#### 2.3.3 NAT 和端口转发

如果服务器在 NAT 后面，确保以下端口可从公网访问：

```
Internet ──► NAT Gateway ──► RustDesk Server
                │
                └──► 21114/tcp (映射到内网)
                └──► 21115/tcp (映射到内网)
                └──► 21116/tcp,udp (映射到内网)
                └──► 21117/tcp (映射到内网)
```

---

## 3. 安装部署

### 3.1 Docker 部署

#### 3.1.1 环境准备

```bash
# 1. 安装 Docker（如果尚未安装）
curl -fsSL https://get.docker.com | sh

# 2. 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 3. 验证 Docker 安装
docker --version
docker-compose --version
```

#### 3.1.2 单容器部署

```bash
# 拉取最新镜像
docker pull rustdesk/rustdesk-pro-server:latest

# 运行容器
docker run -d \
  --name rustdesk-pro \
  --restart always \
  -p 21114:21114 \
  -p 21115:21115 \
  -p 21116:21116 \
  -p 21117:21117 \
  -v rustdesk-data:/data \
  rustdesk/rustdesk-pro-server:latest
```

**使用自定义配置**：
```bash
# 创建配置目录
mkdir -p /opt/rustdesk/config

# 创建环境变量文件
cat > /opt/rustdesk/config/.env << 'EOF'
# 许可证密钥
RUSTDESK_LICENSE=your-license-key-here

# 数据库配置
DB_TYPE=sqlite
DB_PATH=/data/rustdesk.db

# 日志级别
LOG_LEVEL=info
EOF

# 运行容器
docker run -d \
  --name rustdesk-pro \
  --restart always \
  -p 21114:21114 \
  -p 21115:21115 \
  -p 21116:21116 \
  -p 21117:21117 \
  -v /opt/rustdesk/config:/config \
  -v rustdesk-data:/data \
  --env-file /opt/rustdesk/config/.env \
  rustdesk/rustdesk-pro-server:latest
```

#### 3.1.3 Docker Compose 部署

**创建 docker-compose.yml**：
```yaml
version: '3.8'

services:
  rustdesk-pro:
    image: rustdesk/rustdesk-pro-server:latest
    container_name: rustdesk-pro
    restart: always
    ports:
      - "21114:21114"
      - "21115:21115"
      - "21116:21116"
      - "21116:21116/udp"
      - "21117:21117"
    volumes:
      - ./data:/data
      - ./config:/config
    environment:
      - RUSTDESK_LICENSE=${RUSTDESK_LICENSE}
      - DB_TYPE=sqlite
      - LOG_LEVEL=info
    networks:
      - rustdesk-net

networks:
  rustdesk-net:
    driver: bridge
```

**启动服务**：
```bash
# 创建配置目录
mkdir -p /opt/rustdesk/{config,data}

# 设置权限
chmod 755 /opt/rustdesk/data

# 启动服务
cd /opt/rustdesk
docker-compose up -d

# 查看日志
docker-compose logs -f
```

#### 3.1.4 验证部署

```bash
# 检查容器状态
docker ps | grep rustdesk-pro

# 检查端口监听
ss -tlnp | grep 2111

# 测试 API 服务
curl http://localhost:21115/status

# 获取服务器公钥
cat /opt/rustdesk/data/id_ed25519.pub
```

### 3.2 Kubernetes 部署

#### 3.2.1 前置条件

```bash
# 确认 kubectl 配置
kubectl cluster-info
kubectl get nodes

# 确认 Helm（可选）
helm version
```

#### 3.2.2 使用 Helm 部署

```bash
# 添加 Helm 仓库
helm repo add rustdesk-pro https://charts.rustdesk-pro.com
helm repo update

# 创建命名空间
kubectl create namespace rustdesk-pro

# 安装商业版
helm install rustdesk-pro rustdesk-pro/rustdesk-pro-server \
  --namespace rustdesk-pro \
  --set license.key=${RUSTDESK_LICENSE} \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set service.type=LoadBalancer \
  --set ingress.enabled=true \
  --set ingress.host=rustdesk-pro.example.com
```

#### 3.2.3 使用 YAML 清单部署

**创建命名空间和 ConfigMap**：
```yaml
# rustdesk-pro-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: rustdesk-pro
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rustdesk-pro-config
  namespace: rustdesk-pro
data:
  DB_TYPE: "postgresql"
  LOG_LEVEL: "info"
```

**创建 Deployment**：
```yaml
# rustdesk-pro-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rustdesk-pro
  namespace: rustdesk-pro
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rustdesk-pro
  template:
    metadata:
      labels:
        app: rustdesk-pro
    spec:
      containers:
      - name: rustdesk-pro
        image: rustdesk/rustdesk-pro-server:latest
        ports:
        - containerPort: 21114
          name: hbbs-tcp
        - containerPort: 21115
          name: hbbs-api
        - containerPort: 21116
          name: hbbs-rdv
        - containerPort: 21117
          name: hbbr-relay
        env:
        - name: RUSTDESK_LICENSE
          valueFrom:
            secretKeyRef:
              name: rustdesk-pro-license
              key: license-key
        - name: DB_TYPE
          valueFrom:
            configMapKeyRef:
              name: rustdesk-pro-config
              key: DB_TYPE
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: rustdesk-pro-pvc
```

**创建 Service**：
```yaml
# rustdesk-pro-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: rustdesk-pro
  namespace: rustdesk-pro
spec:
  type: LoadBalancer
  ports:
  - name: hbbs-tcp
    port: 21114
    targetPort: 21114
  - name: hbbs-api
    port: 21115
    targetPort: 21115
  - name: hbbs-rdv
    port: 21116
    targetPort: 21116
  - name: hbbr-relay
    port: 21117
    targetPort: 21117
  selector:
    app: rustdesk-pro
```

**应用清单**：
```bash
kubectl apply -f rustdesk-pro-namespace.yaml
kubectl apply -f rustdesk-pro-deployment.yaml
kubectl apply -f rustdesk-pro-service.yaml
```

#### 3.2.4 验证部署

```bash
# 检查 Pod 状态
kubectl get pods -n rustdesk-pro

# 检查 Service 状态
kubectl get svc -n rustdesk-pro

# 查看日志
kubectl logs -n rustdesk-pro deployment/rustdesk-pro

# 获取外部 IP（等待 LoadBalancer 分配）
kubectl get svc -n rustdesk-pro -w
```

### 3.3 直接安装

#### 3.3.1 Linux 二进制安装

```bash
# 1. 下载二进制文件
# 生产版本格式: rustdesk-pro-server-pro-vX.Y.Z-linux-amd64.zip
# 开发版本格式: rustdesk-pro-server-dev-vX.Y.Z.date.commit-linux-amd64.zip
curl -LO https://github.com/rustdesk/rustdesk-server/releases/download/pro-v1.0.3/rustdesk-pro-server-pro-v1.0.3-linux-amd64.zip

# 2. 验证文件完整性（推荐）
curl -LO https://github.com/rustdesk/rustdesk-server/releases/download/pro-v1.0.3/checksums.txt
sha256sum -c checksums.txt --ignore-missing

# 3. 解压
unzip rustdesk-pro-server-pro-v1.0.3-linux-amd64.zip
cd rustdesk-pro-server

# 4. 安装
sudo ./install.sh

# 5. 配置
sudo systemctl edit rustdesk-pro-hbbs
# 添加环境变量：
# [Service]
# Environment="RUSTDESK_LICENSE=your-license-key"

# 6. 启动服务
sudo systemctl start rustdesk-pro-hbbs
sudo systemctl start rustdesk-pro-hbbr

# 7. 设置开机自启
sudo systemctl enable rustdesk-pro-hbbs
sudo systemctl enable rustdesk-pro-hbbr
```

#### 3.3.1.1 构建物命名规范

| 构建物类型 | 命名格式 | 示例 |
|-----------|---------|------|
| Linux ZIP (amd64) | `rustdesk-pro-server-{version}-linux-amd64.zip` | `rustdesk-pro-server-pro-v1.0.3-linux-amd64.zip` |
| Linux ZIP (arm64v8) | `rustdesk-pro-server-{version}-linux-arm64v8.zip` | `rustdesk-pro-server-pro-v1.0.3-linux-arm64v8.zip` |
| Linux ZIP (armv7) | `rustdesk-pro-server-{version}-linux-armv7.zip` | `rustdesk-pro-server-pro-v1.0.3-linux-armv7.zip` |
| Windows ZIP | `rustdesk-pro-server-{version}-windows-x86_64.zip` | `rustdesk-pro-server-pro-v1.0.3-windows-x86_64.zip` |
| Debian DEB (amd64) | `rustdesk-pro-server-{debian_version}-amd64.deb` | `rustdesk-pro-server-1.0.3-amd64.deb` |
| Debian DEB (arm64) | `rustdesk-pro-server-{debian_version}-arm64.deb` | `rustdesk-pro-server-1.0.3-arm64.deb` |
| Debian DEB (armhf) | `rustdesk-pro-server-{debian_version}-armhf.deb` | `rustdesk-pro-server-1.0.3-armhf.deb` |
| 校验和文件 | `checksums.txt` | `checksums.txt` |
| 构建信息 | `build-info.json` | `build-info.json` |

#### 3.3.1.2 版本号格式说明

| 版本类型 | 格式 | 示例 |
|---------|------|------|
| 生产版本 | `pro-v{major}.{minor}.{patch}` | `pro-v1.0.3` |
| 开发版本 | `dev-v{major}.{minor}.{patch}.{date}.{commit}` | `dev-v0.0.0.20260617.abc12345` |

#### 3.3.2 Linux 手动配置

```bash
# 1. 创建用户
sudo useradd -r -s /sbin/nologin rustdesk

# 2. 创建目录
sudo mkdir -p /opt/rustdesk/{bin,config,data,logs}
sudo chown -R rustdesk:rustdesk /opt/rustdesk

# 3. 复制二进制文件
sudo cp hbbs hbbr /opt/rustdesk/bin/
sudo chmod +x /opt/rustdesk/bin/*

# 4. 创建 systemd 服务文件
sudo cat > /etc/systemd/system/rustdesk-pro-hbbs.service << 'EOF'
[Unit]
Description=RustDesk Pro Server (hbbs)
After=network.target

[Service]
Type=simple
User=rustdesk
Group=rustdesk
ExecStart=/opt/rustdesk/bin/hbbs -k _
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 5. 重新加载 systemd
sudo systemctl daemon-reload

# 6. 启动服务
sudo systemctl start rustdesk-pro-hbbs
```

#### 3.3.3 Windows 安装

**使用 PowerShell**：
```powershell
# 1. 下载 Windows 版本
# 生产版本格式: rustdesk-pro-server-pro-vX.Y.Z-windows-x86_64.zip
Invoke-WebRequest -Uri "https://github.com/rustdesk/rustdesk-server/releases/download/pro-v1.0.3/rustdesk-pro-server-pro-v1.0.3-windows-x86_64.zip" -OutFile "rustdesk-pro-server.zip"

# 2. 验证文件完整性（推荐）
Invoke-WebRequest -Uri "https://github.com/rustdesk/rustdesk-server/releases/download/pro-v1.0.3/checksums.txt" -OutFile "checksums.txt"

# 3. 解压
Expand-Archive -Path "rustdesk-pro-server.zip" -DestinationPath "C:\Program Files\RustDesk Pro Server"

# 4. 创建配置目录
New-Item -ItemType Directory -Force -Path "C:\ProgramData\RustDesk Pro"

# 5. 创建服务（使用 nssm）
# 下载 nssm: https://nssm.cc/release/nssm-2.24.zip
# 解压后复制 nssm.exe 到系统 PATH

# 6. 创建 hbbs 服务
nssm install RustDeskProHbbs "C:\Program Files\RustDesk Pro Server\hbbs.exe" "-k _"
nssm set RustDeskProHbbs AppDirectory "C:\Program Files\RustDesk Pro Server"
nssm set RustDeskProHbbs Description "RustDesk Pro ID/Rendezvous Server"
nssm set RustDeskProHbbs Start SERVICE_AUTO_START

# 7. 创建 hbbr 服务
nssm install RustDeskProHbbr "C:\Program Files\RustDesk Pro Server\hbbr.exe" "-k _"
nssm set RustDeskProHbbr AppDirectory "C:\Program Files\RustDesk Pro Server"
nssm set RustDeskProHbbr Description "RustDesk Pro Relay Server"
nssm set RustDeskProHbbr Start SERVICE_AUTO_START

# 8. 启动服务
nssm start RustDeskProHbbs
nssm start RustDeskProHbbr
```

---

## 4. 配置指南

### 4.1 基础配置

#### 4.1.1 环境变量配置

| 变量名 | 必需 | 默认值 | 说明 |
|--------|------|--------|------|
| `RUSTDESK_LICENSE` | ✅ | - | 许可证密钥 |
| `DB_TYPE` | ❌ | `sqlite` | 数据库类型：`sqlite` 或 `postgresql` |
| `DB_PATH` | ❌ | `/data/rustdesk.db` | SQLite 数据库路径 |
| `DB_HOST` | ❌ | `localhost` | PostgreSQL 主机 |
| `DB_PORT` | ❌ | `5432` | PostgreSQL 端口 |
| `DB_NAME` | ❌ | `rustdesk` | PostgreSQL 数据库名 |
| `DB_USER` | ❌ | `rustdesk` | PostgreSQL 用户 |
| `DB_PASSWORD` | ❌ | - | PostgreSQL 密码 |
| `LOG_LEVEL` | ❌ | `info` | 日志级别：`trace`, `debug`, `info`, `warn`, `error` |
| `API_PORT` | ❌ | `21115` | API 服务端口 |
| `RELAY_PORT` | ❌ | `21117` | 中继服务端口 |

#### 4.1.2 配置文件

配置文件位于 `/config/config.toml`（Docker）或 `/opt/rustdesk/config/config.toml`（直接安装）。

```toml
# 基本设置
[server]
# 服务器 ID（自动生成，无需配置）
# id = "your-server-id"

# API 服务配置
[server.api]
host = "0.0.0.0"
port = 21115
tls_enabled = true
tls_cert = "/config/tls/cert.pem"
tls_key = "/config/tls/key.pem"

# 中继服务配置
[server.relay]
host = "0.0.0.0"
port = 21117
max_connections = 1000
bandwidth_limit = "10MB/s"

# 数据库配置
[database]
type = "sqlite"
path = "/data/rustdesk.db"
# type = "postgresql"
# host = "localhost"
# port = 5432
# name = "rustdesk"
# user = "rustdesk"
# password = "password"

# 日志配置
[logging]
level = "info"
path = "/logs"
max_size = "100MB"
max_backups = 10
```

#### 4.1.3 许可证配置

```bash
# 方式 1：环境变量
export RUSTDESK_LICENSE="PRO-XXXX-XXXX-XXXX-XXXX"

# 方式 2：配置文件
# 在 config.toml 中添加：
[license]
key = "PRO-XXXX-XXXX-XXXX-XXXX"
```

### 4.2 高级配置

#### 4.2.1 PostgreSQL 数据库配置

```toml
[database]
type = "postgresql"
host = "db.example.com"
port = 5432
name = "rustdesk_pro"
user = "rustdesk_user"
password = "secure_password"
pool_size = 20
ssl_mode = "require"
```

**创建数据库和用户**：
```sql
-- 连接到 PostgreSQL
psql -U postgres

-- 创建数据库
CREATE DATABASE rustdesk_pro;

-- 创建用户
CREATE USER rustdesk_user WITH PASSWORD 'secure_password';

-- 授权
GRANT ALL PRIVILEGES ON DATABASE rustdesk_pro TO rustdesk_user;
\c rustdesk_pro
GRANT ALL ON SCHEMA public TO rustdesk_user;
```

#### 4.2.2 TLS/SSL 配置

```bash
# 生成自签名证书（测试用）
mkdir -p /opt/rustdesk/config/tls
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/rustdesk/config/tls/key.pem \
  -out /opt/rustdesk/config/tls/cert.pem \
  -subj "/CN=rustdesk-pro.example.com"

# 使用 Let's Encrypt 证书（生产用）
# 请先确保域名已正确配置
```

```toml
[server.api.tls]
enabled = true
cert = "/config/tls/fullchain.pem"
key = "/config/tls/privkey.pem"
```

#### 4.2.3 集群配置

```toml
[cluster]
enabled = true
node_id = "node-1"
nodes = [
  "node-1=https://node1.example.com:21115",
  "node-2=https://node2.example.com:21115",
  "node-3=https://node3.example.com:21115"
]
sync_interval = 5  # 秒
heartbeat_timeout = 30  # 秒
```

#### 4.2.4 带宽限制

```toml
[relay]
max_connections = 1000
max_bandwidth = "100MB/s"
per_user_bandwidth = "10MB/s"
per_device_bandwidth = "5MB/s"
```

### 4.3 安全配置

#### 4.3.1 IP 白名单

```toml
[security]
# 启用 IP 白名单
ip_whitelist_enabled = true
ip_whitelist = [
  "10.0.0.0/8",
  "172.16.0.0/12",
  "192.168.0.0/16",
  "203.0.113.0/24"
]
```

#### 4.3.2 访问时间策略

```toml
[security.access_time]
enabled = true
# 允许访问的时间段（UTC）
allowed_start = "08:00"
allowed_end = "20:00"
# 允许访问的日期（0=周日, 1=周一, ...）
allowed_days = [1, 2, 3, 4, 5]  # 工作日
```

#### 4.3.3 双因素认证

```toml
[security.two_factor]
enabled = true
# TOTP 颁发者名称
issuer = "RustDesk Pro"
# 验证码有效期（秒）
validity_period = 30
```

---

## 5. 功能使用

### 5.1 用户管理

#### 5.1.1 Web 控制台访问

**访问地址**：`https://rustdesk-pro.example.com:21115`

**初始登录**：
- 用户名：`admin`
- 密码：`admin`（首次登录后必须更改）

#### 5.1.2 创建用户

**通过 Web 控制台**：
1. 登录 Web 控制台
2. 进入「用户管理」→「用户列表」
3. 点击「创建用户」
4. 填写表单：
   - 用户名：必填，唯一标识
   - 邮箱：必填，用于登录
   - 密码：必填（首次创建可设置临时密码）
   - 角色：选择角色（管理员/操作员/查看者）
   - 部门：可选，关联部门
5. 点击「创建」

**通过 API**：
```bash
curl -X POST "https://rustdesk-pro.example.com:21115/api/v1/users" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john.doe",
    "email": "john.doe@example.com",
    "password": "SecurePass123!",
    "role": "operator",
    "department": "IT"
  }'
```

#### 5.1.3 角色权限

| 权限 | 管理员 | 操作员 | 查看者 |
|------|--------|--------|--------|
| 系统配置 | ✅ 完全 | ❌ | ❌ |
| 用户管理 | ✅ 完全 | ✅ 创建/修改 | ❌ |
| 设备管理 | ✅ 完全 | ✅ 完全 | ✅ 只读 |
| 查看日志 | ✅ 完全 | ✅ 完全 | ✅ 只读 |
| 会话管理 | ✅ 完全 | ✅ 完全 | ❌ |
| 许可证管理 | ✅ 完全 | ❌ | ❌ |

### 5.2 设备管理

#### 5.2.1 设备注册审批

**启用设备审批**：
1. 进入「系统设置」→「设备管理」
2. 开启「启用设备注册审批」
3. 设置审批策略：
   - 自动审批：同部门设备自动通过
   - 手动审批：所有设备需审批

**审批操作**：
1. 进入「设备管理」→「待审批」
2. 查看设备信息：
   - 设备 ID
   - 设备名称
   - 注册时间
   - 注册用户
3. 选择操作：
   - 批准：设备获得完整访问权限
   - 拒绝：设备无法连接
   - 挂起：设备进入观察列表

#### 5.2.2 设备分组

**创建分组**：
1. 进入「设备管理」→「设备分组」
2. 点击「创建分组」
3. 填写分组信息：
   - 分组名称：必填
   - 父分组：可选，创建子分组
   - 描述：可选
4. 点击「创建」

**分配设备到分组**：
- 手动分配：在设备详情页选择分组
- 规则分配：设置自动分配规则

### 5.3 授权管理

#### 5.3.1 许可证激活

**激活步骤**：
1. 收到许可证密钥（格式：`PRO-XXXX-XXXX-XXXX-XXXX`）
2. 进入 Web 控制台「系统设置」→「许可证」
3. 点击「激活许可证」
4. 输入许可证密钥
5. 点击「激活」

**验证激活状态**：
```bash
curl "https://rustdesk-pro.example.com:21115/api/v1/license/status" \
  -H "Authorization: Bearer ${API_TOKEN}"
```

响应示例：
```json
{
  "valid": true,
  "license_type": "professional",
  "expires_at": "2027-06-16T23:59:59Z",
  "max_devices": 100,
  "current_devices": 42
}
```

#### 5.3.2 许可证类型

| 类型 | 功能 | 适用场景 |
|------|------|---------|
| 基础版 | 50 设备 | 小型团队 |
| 专业版 | 200 设备 | 中型企业 |
| 企业版 | 无限制 | 大型组织 |

### 5.4 审计日志

#### 5.4.1 查看审计日志

**通过 Web 控制台**：
1. 进入「审计」→「操作日志」
2. 使用筛选条件：
   - 时间范围
   - 用户
   - 操作类型
   - 资源类型
3. 点击「查询」
4. 查看详情或导出

**通过 API**：
```bash
curl "https://rustdesk-pro.example.com:21115/api/v1/audit/logs?from=2026-06-01&to=2026-06-16&type=user.login" \
  -H "Authorization: Bearer ${API_TOKEN}"
```

响应示例：
```json
{
  "total": 1523,
  "page": 1,
  "page_size": 50,
  "logs": [
    {
      "id": "log-001",
      "timestamp": "2026-06-16T10:23:45Z",
      "user": "admin",
      "action": "user.login",
      "resource": "web-console",
      "result": "success",
      "ip_address": "192.168.1.100",
      "details": {
        "browser": "Chrome 125.0",
        "os": "Windows 11"
      }
    }
  ]
}
```

#### 5.4.2 日志保留策略

| 版本 | 日志保留 | 导出 |
|------|---------|------|
| 基础版 | 7 天 | ❌ |
| 专业版 | 30 天 | ✅ CSV/JSON |
| 企业版 | 90 天 | ✅ CSV/JSON/Syslog |

---

## 6. 运维管理

### 6.1 监控告警

#### 6.1.1 Prometheus 指标

**启用指标端点**：
```toml
[monitoring]
enabled = true
metrics_port = 21120
```

**Prometheus 配置**：
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'rustdesk-pro'
    static_configs:
      - targets: ['rustdesk-pro.example.com:21120']
    scrape_interval: 15s
```

**关键指标**：

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `rustdesk_hbbs_connections` | Gauge | 当前连接数 |
| `rustdesk_hbbr_relay_connections` | Gauge | 中继连接数 |
| `rustdesk_api_requests_total` | Counter | API 请求总数 |
| `rustdesk_api_request_duration_seconds` | Histogram | API 响应时间 |
| `rustdesk_license_devices` | Gauge | 已注册设备数 |

#### 6.1.2 告警规则

```yaml
# alertmanager.yml
groups:
  - name: rustdesk-pro
    rules:
      # 连接数告警
      - alert: HighConnectionLoad
        expr: rustdesk_hbbs_connections > 800
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "RustDesk 连接数过高"
          description: "当前连接数 {{ $value }}，超过阈值 800"

      # 中继负载告警
      - alert: HighRelayLoad
        expr: rustdesk_hbbr_relay_connections > 500
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "RustDesk 中继负载过高"
          description: "中继连接数 {{ $value }}，超过阈值 500"

      # API 响应时间告警
      - alert: HighAPILatency
        expr: histogram_quantile(0.95, rustdesk_api_request_duration_seconds) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "RustDesk API 响应时间过长"
          description: "P95 响应时间 {{ $value }}s，超过阈值 1s"
```

### 6.2 备份恢复

#### 6.2.1 自动备份

**配置备份任务**：
```toml
[backup]
enabled = true
schedule = "0 2 * * *"  # 每天凌晨 2:00
retention_days = 30
path = "/backup"
compression = true
```

**备份内容**：
- 数据库文件
- 配置文件
- 许可证信息
- 用户数据

#### 6.2.2 手动备份

```bash
# 1. 停止服务
docker-compose down

# 2. 备份数据目录
tar -czf backup-$(date +%Y%m%d).tar.gz /opt/rustdesk/data

# 3. 备份配置文件
cp -r /opt/rustdesk/config ./config-backup-$(date +%Y%m%d)

# 4. 备份数据库（如果是 PostgreSQL）
pg_dump -U rustdesk_user -d rustdesk_pro > db-backup-$(date +%Y%m%d).sql
```

#### 6.2.3 恢复操作

```bash
# 1. 停止服务
docker-compose down

# 2. 恢复数据目录
tar -xzf backup-20260616.tar.gz -C /

# 3. 恢复配置文件
cp -r ./config-backup-20260616/* /opt/rustdesk/config/

# 4. 恢复数据库
psql -U rustdesk_user -d rustdesk_pro < db-backup-20260616.sql

# 5. 重启服务
docker-compose up -d
```

### 6.3 升级维护

#### 6.3.1 版本检查

```bash
# 检查当前版本
docker exec rustdesk-pro rustdesk-pro --version

# 或者查看日志
docker logs rustdesk-pro 2>&1 | head -20
```

#### 6.3.2 升级步骤

**Docker 部署**：
```bash
# 1. 拉取新版本镜像
docker pull rustdesk/rustdesk-pro-server:latest

# 2. 备份当前数据（见 6.2.2）

# 3. 更新 docker-compose.yml 中的镜像版本
# image: rustdesk/rustdesk-pro-server:latest

# 4. 重启服务
docker-compose down
docker-compose up -d

# 5. 验证升级
docker exec rustdesk-pro rustdesk-pro --version
docker logs rustdesk-pro --tail 50
```

**Kubernetes 部署**：
```bash
# 1. 更新 Helm chart
helm repo update
helm upgrade rustdesk-pro rustdesk-pro/rustdesk-pro-server \
  --namespace rustdesk-pro \
  --set image.tag=v1.2.0

# 2. 验证升级
kubectl rollout status deployment/rustdesk-pro -n rustdesk-pro
kubectl logs -n rustdesk-pro -l app=rustdesk-pro --tail 50
```

#### 6.3.3 回滚操作

**Docker 回滚**：
```bash
# 1. 停止当前服务
docker-compose down

# 2. 使用备份版本镜像（如果有标签）
docker pull rustdesk/rustdesk-pro-server:v1.1.0

# 3. 修改 docker-compose.yml
# image: rustdesk/rustdesk-pro-server:v1.1.0

# 4. 恢复备份数据
tar -xzf backup-20260615.tar.gz -C /

# 5. 重启服务
docker-compose up -d
```

**Kubernetes 回滚**：
```bash
# 回滚到上一个版本
kubectl rollout undo deployment/rustdesk-pro -n rustdesk-pro

# 回滚到指定版本
kubectl rollout undo deployment/rustdesk-pro -n rustdesk-pro --to-revision=2
```

---

## 7. 故障排除

### 7.1 常见问题

#### Q1: 客户端无法连接到服务器

**可能原因**：
1. 服务器端口未开放
2. 防火墙阻止连接
3. 许可证无效
4. 服务器负载过高

**排查步骤**：

```bash
# 1. 检查端口状态
ss -tlnp | grep 2111
netstat -tlnp | grep 2111

# 2. 检查防火墙规则
iptables -L -n | grep 2111
firewall-cmd --list-all

# 3. 测试端口连通性
telnet your-server.com 21116
nc -zv your-server.com 21117

# 4. 检查服务日志
docker logs rustdesk-pro | grep -i error
```

**解决方案**：
- 开放必需端口（见 2.3.1）
- 检查许可证状态
- 增加服务器资源

#### Q2: 设备注册被拒绝

**可能原因**：
1. 设备审批功能已启用
2. 设备数量超过许可证限制
3. IP 不在白名单内

**排查步骤**：

```bash
# 1. 检查许可证状态
curl "https://rustdesk-pro.example.com:21115/api/v1/license/status" \
  -H "Authorization: Bearer ${API_TOKEN}"

# 2. 检查待审批设备列表
curl "https://rustdesk-pro.example.com:21115/api/v1/devices/pending" \
  -H "Authorization: Bearer ${API_TOKEN}"

# 3. 检查 IP 白名单配置
cat /opt/rustdesk/config/config.toml | grep -A10 ip_whitelist
```

**解决方案**：
- 审批待处理设备
- 升级许可证增加设备数
- 更新 IP 白名单配置

#### Q3: P2P 连接失败，强制走中继

**可能原因**：
1. NAT 类型限制
2. 网络策略阻止直连
3. 防火墙阻止 UDP

**排查步骤**：

```bash
# 1. 检查 NAT 类型
# 客户端日志中查看 NAT 类型信息

# 2. 测试 UDP 连通性
nc -u -zv your-server.com 21116

# 3. 检查服务器 UDP 配置
cat /opt/rustdesk/config/config.toml | grep -A5 relay
```

**解决方案**：
- 配置 STUN 服务器改善 NAT 穿透
- 确保防火墙允许 UDP 21116
- 使用中继作为备用方案

#### Q4: Web 控制台无法访问

**可能原因**：
1. API 服务未启动
2. TLS 证书过期
3. 端口被占用

**排查步骤**：

```bash
# 1. 检查 API 服务状态
curl http://localhost:21115/status

# 2. 检查端口占用
lsof -i :21115
netstat -tlnp | grep 21115

# 3. 检查证书有效期
openssl x509 -in /opt/rustdesk/config/tls/cert.pem -noout -dates
```

**解决方案**：
- 重启 API 服务
- 更新 TLS 证书
- 更换端口

#### Q5: 数据库连接失败

**可能原因**：
1. PostgreSQL 未启动
2. 连接参数错误
3. 权限不足

**排查步骤**：

```bash
# 1. 检查 PostgreSQL 状态
systemctl status postgresql
docker ps | grep postgres

# 2. 测试数据库连接
psql -h localhost -U rustdesk_user -d rustdesk_pro

# 3. 检查连接日志
tail -n 50 /var/log/postgresql/postgresql-*.log
```

**解决方案**：
- 启动 PostgreSQL 服务
- 修正配置文件中的数据库参数
- 检查用户权限

### 7.2 日志分析

#### 7.2.1 日志位置

| 部署方式 | 日志位置 |
|---------|---------|
| Docker | `docker logs rustdesk-pro` |
| Kubernetes | `kubectl logs -n rustdesk-pro -l app=rustdesk-pro` |
| 直接安装 | `/opt/rustdesk/logs/` |

#### 7.2.2 日志级别配置

```toml
[logging]
level = "debug"  # trace, debug, info, warn, error
```

#### 7.2.3 常用日志分析命令

```bash
# 查看错误日志
docker logs rustdesk-pro 2>&1 | grep -i error

# 实时查看日志
docker logs -f rustdesk-pro

# 查看最近 100 行
docker logs rustdesk-pro --tail 100

# 搜索特定时间范围
docker logs --since "2026-06-16T10:00:00" rustdesk-pro

# 统计错误类型
docker logs rustdesk-pro 2>&1 | grep -i error | awk '{print $NF}' | sort | uniq -c
```

### 7.3 性能优化

#### 7.3.1 系统参数优化

**Linux 内核参数**（`/etc/sysctl.conf`）：
```bash
# 网络参数
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000

# 文件描述符限制
fs.file-max = 655360

# 应用
sysctl -p
```

**用户限制**（`/etc/security/limits.conf`）：
```
rustdesk soft nofile 65536
rustdesk hard nofile 65536
rustdesk soft nproc 4096
rustdesk hard nproc 4096
```

#### 7.3.2 Docker 资源限制

```yaml
# docker-compose.yml
services:
  rustdesk-pro:
    image: rustdesk/rustdesk-pro-server:latest
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

---

## 8. 附录

### 8.1 命令参考

#### 8.1.1 服务管理命令

| 操作 | Docker | systemd |
|------|--------|---------|
| 启动 | `docker-compose up -d` | `systemctl start rustdesk-pro` |
| 停止 | `docker-compose down` | `systemctl stop rustdesk-pro` |
| 重启 | `docker-compose restart` | `systemctl restart rustdesk-pro` |
| 状态 | `docker-compose ps` | `systemctl status rustdesk-pro` |
| 日志 | `docker-compose logs -f` | `journalctl -u rustdesk-pro -f` |

#### 8.1.2 客户端命令

```bash
# 连接远程设备
rustdesk <device-id>

# 查看设备列表
rustdesk --list-devices

# 测试服务器连接
rustdesk --test-server your-server.com
```

### 8.2 配置参数速查表

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `API_PORT` | int | 21115 | API 服务端口 |
| `RELAY_PORT` | int | 21117 | 中继服务端口 |
| `DB_TYPE` | string | sqlite | 数据库类型 |
| `LOG_LEVEL` | string | info | 日志级别 |
| `MAX_CONNECTIONS` | int | 1000 | 最大连接数 |
| `BANDWIDTH_LIMIT` | string | - | 带宽限制 |

### 8.3 术语表

| 术语 | 英文 | 定义 |
|------|------|------|
| hbbs | ID/Rendezvous Server | 身份注册与连接协调服务器 |
| hbbr | Relay Server | 中继转发服务器 |
| P2P | Peer-to-Peer | 点对点直连 |
| NAT | Network Address Translation | 网络地址转换 |
| STUN | STUN | NAT 类型检测协议 |
| TURN | TURN | 中继协议 |
| TLS | Transport Layer Security | 传输层安全协议 |
| SLA | Service Level Agreement | 服务等级协议 |

### 8.4 联系方式

| 类型 | 信息 |
|------|------|
| **技术支持邮箱** | support@rustdesk.com |
| **商务合作邮箱** | sales@rustdesk.com |
| **官方网站** | https://rustdesk.com |
| **文档中心** | https://docs.rustdesk.com |
| **GitHub Issues** | https://github.com/rustdesk/rustdesk-server/issues |

---

**文档版本**: v1.0  
**适用产品**: RustDesk Pro Server  
**最后更新**: 2026-06-16
