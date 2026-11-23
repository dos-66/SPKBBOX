#!/bin/bash
# 备份容器栈：镜像 + 数据库 + 前端 + 素材 + 配置，打包为 tar.gz
# 用法：./scripts/backup.sh [输出目录]
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

STAMP=$(date +%Y%m%d-%H%M)
OUT_DIR="${1:-backup-$STAMP}"
mkdir -p "$OUT_DIR"/{db,files,images}

echo "[1/5] 导出数据库"
docker exec apm-mysql sh -c \
    'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --databases "${MYSQL_DATABASE:-apmw}" \
     --single-transaction --routines --triggers --default-character-set=utf8mb4' \
    > "$OUT_DIR/db/apmw.sql"

echo "[2/5] 打包前端 / 素材 / 配置"
tar -cf "$OUT_DIR/files/html.tar" html
tar -cf "$OUT_DIR/files/apm_file.tar" apm_file
tar -cf "$OUT_DIR/files/config.tar" conf docker-compose.yml nginx sql

echo "[3/5] 保存镜像"
for img in apm-web:local mysql:5.7 redis:6.2 nginx:1.21.1 emqx/emqx:4.3.15; do
    name=$(echo "$img" | tr '/:' '__')
    docker save -o "$OUT_DIR/images/${name}.tar" "$img"
done

echo "[4/5] 生成恢复脚本"
cp scripts/restore.sh "$OUT_DIR/restore.sh"
chmod +x "$OUT_DIR/restore.sh"

echo "[5/5] 打包"
tar -czf "${OUT_DIR}.tar.gz" "$OUT_DIR"
echo "完成：${OUT_DIR}.tar.gz"
sha256sum "${OUT_DIR}.tar.gz" || true