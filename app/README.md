# app 目录说明

本目录只包含**容器化封装**，不包含应用二进制。

使用前请自备 Tomcat 8 目录并放到 `app/tomcat/`，结构要求：

```
app/
├── Dockerfile
├── start.sh
└── tomcat/                 # 自备，不入库
    ├── bin/catalina.sh
    ├── conf/
    ├── lib/
    └── webapps/
        └── apm-web/        # 你的应用（含 WEB-INF/classes/set.properties 挂载点）
```

要点：

- Tomcat 需为 8.x + JRE 8 可运行版本；
- 应用需暴露 HTTP 8283、终端长连接 19527、UDP 9999；
- `WEB-INF/classes/set.properties` 由 compose 从 `conf/set.properties` 挂载覆盖；
- 应用内若把 MQTT/Redis 地址写死为 `127.0.0.1`，依赖 `start.sh` 的 socat 转发即可工作。

`.gitignore` 已排除 `app/tomcat/`，避免把商业应用代码提交到公开仓库。