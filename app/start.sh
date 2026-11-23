#!/bin/sh
set -e
umask 0000

MQTT_HOST="${MQTT_HOST:-emqx}"
REDIS_HOST="${REDIS_HOST:-redis}"

# 应用内 MQTT 与 Redis 地址均硬编码为 127.0.0.1，
# 这里在容器内把 1883 / 6379 转发到 compose 中的服务名。
socat TCP-LISTEN:1883,fork,reuseaddr "TCP:${MQTT_HOST}:1883" &
socat TCP-LISTEN:6379,fork,reuseaddr "TCP:${REDIS_HOST}:6379" &

exec /opt/tomcat/bin/catalina.sh run