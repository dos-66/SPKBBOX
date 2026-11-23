FROM eclipse-temurin:8-jre-jammy

ENV TZ=Asia/Shanghai \
    LANG=C.UTF-8 \
    CATALINA_OPTS="-Xms512m -Xmx1536m -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai"

# 应用包：使用时把自备的 Tomcat 目录放到 app/tomcat（不入库）
COPY tomcat /opt/tomcat

RUN mkdir -p /opt/tomcat/logs /opt/tomcat/temp /opt/tomcat/work /data/apm_file \
    && chmod +x /opt/tomcat/bin/*.sh

# 容器内把 127.0.0.1:1883 / 6379 转发到 compose 服务名（应用内地址硬编码）
RUN apt-get update && apt-get install -y --no-install-recommends socat \
    && rm -rf /var/lib/apt/lists/*

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

EXPOSE 8283 19527 9999/tcp 9999/udp

HEALTHCHECK --start-period=300s --interval=15s --timeout=5s --retries=20 \
  CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/8283' || exit 1

CMD ["/opt/start.sh"]