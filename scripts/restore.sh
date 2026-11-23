#!/bin/sh
# 从备份目录恢复容器栈
# 用法：./restore.sh <备份目录>
set -e
cd "$(dirname "$0")"

if [ ! -d images ]; then
    echo "请在备份目录内执行（应包含 images/ db/ files/）" >&2
    exit 1
fi

echo "[1/5] 加载镜像"
for f in images/*.tar; do
    echo "  - $f"
    docker load -i "$f"
done

echo "[2/5] 恢复数据目录"
tar -xf files/apm_file.tar -C .
tar -xf files/html.tar -C .
tar -xf files/config.tar -C .
mkdir -p apm-logs redis-data emqx-data mysql-data

echo "[3/5] 启动容器"
docker compose up -d

echo "[4/5] 等待 MySQL 健康"
for i in $(seq 1 90); do
    st=$(docker inspect -f '{{.State.Health.Status}}' apm-mysql 2>/dev/null || echo starting)
    [ "$st" = "healthy" ] && break
    sleep 5
done
echo "  mysql=$st"

echo "[5/5] 状态"
docker compose ps
echo "完成：访问 http://<宿主IP>/"