FROM nginx:alpine

# Устанавливаем apache2-utils, чтобы внутри контейнера была утилита htpasswd (для создания паролей)
RUN apk add --no-cache apache2-utils

# Принимаем имя пользователя как аргумент сборки (по ТЗ)
ARG BASIC_AUTH_USER=admin
ENV REQ_USER=$BASIC_AUTH_USER

# Копируем наш SSL-сертификат в доверенные внутри контейнера (по ТЗ)
COPY ./certs/devops.crt /usr/local/share/ca-certificates/devops.crt
RUN update-ca-certificates

# Копируем шаблон конфигурации Nginx внутрь образа
COPY ./nginx/default.conf.template /etc/nginx/templates/default.conf.template

# Копируем скрипт генерации index.html с переменными окружения
COPY ./nginx/generate-env-html.sh /usr/local/bin/generate-env-html.sh
RUN chmod +x /usr/local/bin/generate-env-html.sh

# Создаем скрипт, который выполнится при старте контейнера
RUN echo '#!/bin/sh' > /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo 'mkdir -p /opt/html/root' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo 'if [ -n "$BASIC_AUTH_PASSWORD" ]; then' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo '  htpasswd -bc /etc/nginx/.htpasswd "$REQ_USER" "$BASIC_AUTH_PASSWORD"' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo 'fi' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo 'echo "<html><head><meta charset=\"UTF-8\"></head><body>" > /opt/html/root/static.html' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo 'echo "<h1>Самое популярное слово: ${POPULAR_WORD:-князь} (Частота: ${WORD_FREQUENCY:-1245})</h1>" >> /opt/html/root/static.html' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo 'echo "<hr><h2>Вывод /etc/os-release:</h2><pre>" >> /opt/html/root/static.html' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo 'cat /etc/os-release >> /opt/html/root/static.html' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo 'echo "</pre></body></html>" >> /opt/html/root/static.html' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    echo '/usr/local/bin/generate-env-html.sh' >> /docker-entrypoint.d/50-dynamic-auth-and-static.sh && \
    chmod +x /docker-entrypoint.d/50-dynamic-auth-and-static.sh
