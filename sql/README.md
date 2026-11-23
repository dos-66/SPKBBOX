# sql 目录说明

本目录用于放置**你自己的**数据库初始化脚本，仓库不包含任何数据库导出。

使用方法：

1. 把应用的初始化 SQL 放到 `sql/apmw.sql`；
2. `docker compose up -d` 时，MySQL 首次启动会自动执行 `/docker-entrypoint-initdb.d` 下的脚本（compose 已把 `./sql` 挂载到该目录，只读）；
3. 仅在 `mysql-data/` 为空（首次启动）时执行；已有数据不会重复导入。

注意：

- 脚本建议使用 `utf8mb4`，与 compose 中的 `--character-set-server=utf8` 保持一致；
- 若库表名包含大小写混用，`--lower-case-table-names=1` 已开启；
- 导入大库（数百 MB）时，首次启动时间会明显变长，请以 `docker compose logs -f apm-mysql` 观察进度；
- 数据库导出属于敏感数据，不要提交到本仓库（`.gitignore` 已排除 `sql/*.sql`）。