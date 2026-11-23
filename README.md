# SPKBBOX：APM 数字标牌后台 · 容器化部署骨架

一个把「Tomcat 应用 + MySQL + Redis + EMQX + Nginx」组合成单机容器栈的部署骨架，用于替代传统的 Windows 安装包部署方式。

> 本仓库是**部署骨架**，不包含任何商业应用二进制、前端产物、数据库导出或客户数据。使用时需自备应用包（见 `app/README.md`）与初始化 SQL（见 `sql/README.md`）。

## 架构

```
                 ┌──────────────────────────────┐
  浏览器  ──────▶│ nginx :80 / :19520           │
                 │  ├─ /            前端静态资源  │
                 │  ├─ /apm_file    素材/缩略图   │
                 │  └─ /apm-web/ ──▶ apm-web:8283│
                 └──────────────────────────────┘
                                 │
        ┌────────────┬───────────┼───────────┬────────────┐
        ▼            ▼           ▼           ▼
   apm-web       mysql:5.7    redis:6.2   emqx:4.3.15
   :8283/:19527  :3317        :6379       :1883/:18083
   :9999/udp
```

- `apm-web`：Tomcat 8 + JRE 8，内置 Netty 长连接端口 19527 与 UDP 9999
- `nginx`：反向代理 + 静态资源，素材目录与后端共享同一宿主目录
- `mysql`：业务库（utf8 / `lower_case_table_names=1`）
- `redis`：缓存与队列
- `emqx`：MQTT Broker（应用内 MQTT 地址硬编码为 `127.0.0.1`，由容器内 `socat` 转发）

## 端口

| 端口 | 服务 | 用途 |
| --- | --- | --- |
| 80 | nginx | 后台 Web 入口 |
| 19520 | nginx | 素材/静态资源备用入口 |
| 8283 | apm-web | 应用 HTTP |
| 19527 | apm-web | 终端长连接（TCP） |
| 9999/udp | apm-web | 终端 UDP |
| 3317 | mysql | 数据库（宿主映射） |
| 6379 | redis | 缓存 |
| 1883 | emqx | MQTT |
| 18083 | emqx | EMQX 控制台 |

## 快速开始

1. 准备目录：

```bash
mkdir -p apm_file apm-logs mysql-data redis-data emqx-data nginx conf app/tomcat sql html
```

2. 放入你自己的应用与前端（仓库不含）：

- `app/tomcat/`：Tomcat 8 目录（含 `webapps/<你的应用>`）
- `html/`：前端编译产物（`index.html` + `static/`）
- `sql/apmw.sql`：数据库初始化脚本

3. 配置环境变量：

```bash
cp .env.example .env
# 修改 .env 中的密码、Cookie、宿主 IP
```

4. 配置应用参数：

```bash
cp conf/set.properties.example conf/set.properties
# 按实际环境填写 ServerIp / nginxIp / 数据库与 Redis 连接
```

5. 构建并启动：

```bash
docker compose build apm-web
docker compose up -d
docker compose ps          # 等待 apm-web 变为 healthy（首次约 2-3 分钟）
```

6. 访问 `http://<宿主IP>/`，使用数据库中的管理员账号登录。

## 目录说明

```
.
├── docker-compose.yml          # 五服务编排
├── .env.example                # 环境变量模板（密码/Cookie/宿主 IP）
├── app/
│   ├── Dockerfile              # Tomcat + JRE8 + socat
│   ├── start.sh                # 容器启动：socat 转发 1883/6379 后拉起 Tomcat
│   └── README.md               # 应用包放置说明（不含二进制）
├── nginx/
│   ├── apm.conf                # 站点配置（静态、素材、反代）
│   └── nginx.conf              # 主配置
├── conf/
│   └── set.properties.example  # 应用配置模板（占位值）
├── sql/
│   └── README.md               # 初始化脚本放置说明（不含数据）
└── scripts/
    ├── backup.sh               # 备份镜像/库/素材/配置为 tar.gz
    └── restore.sh              # 从备份包恢复
```

## 容器镜像

应用镜像已发布到 GitHub Container Registry，包名 `spkbbox`，**私有**（需授权账号拉取）：

| Tag | 说明 |
| --- | --- |
| `ghcr.io/dos-66/spkbbox:latest` | 最新构建 |
| `ghcr.io/dos-66/spkbbox:20261123` | 按日期标记 |

digest：`sha256:c613e06983c3e7f5fa7d79e4beeaa290f2c962ecc991aca3b90b43f86f7e949a`

拉取前先登录（token 需 `read:packages` 权限）：

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u <你的GitHub用户名> --password-stdin
docker pull ghcr.io/dos-66/spkbbox:latest
```

也可在 `docker-compose.yml` 里直接用镜像替代本地构建：

```yaml
apm-web:
  image: ghcr.io/dos-66/spkbbox:latest
  # build: ./app   # 本地构建时保留
```

镜像内含应用二开代码，故设为私有包；本仓库公开部分仍只有编排与脚本。

## 备份与恢复

```bash
./scripts/backup.sh                 # 生成 backup-<日期>/ 与 tar.gz
./scripts/restore.sh <备份目录>      # 加载镜像、恢复数据、启动容器
```

脚本会导出 MySQL 全库（`mysqldump`）、打包 `html`/`apm_file`/配置，并 `docker save` 五个镜像。

## 已知限制

- 应用内 MQTT / Redis 地址硬编码为 `127.0.0.1`，因此容器内用 `socat` 把 1883/6379 转发到 compose 服务名；如后续版本支持配置化，可移除 `socat`。
- Office 文档转换、图片处理等能力依赖宿主机或额外镜像（LibreOffice / ImageMagick），本骨架未内置。
- `nginx.conf` 中 `user root` 仅用于容器内读取共享素材目录的简化配置，生产环境建议改为非 root 用户并调整目录权限。

## 许可

MIT（仅覆盖本仓库的编排与脚本；不含任何商业应用代码）。