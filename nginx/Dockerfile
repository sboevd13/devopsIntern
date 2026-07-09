FROM nginx:alpine

RUN apk add --no-cache apache2-utils

ARG BASIC_AUTH_USER=admin
ENV REQ_USER=$BASIC_AUTH_USER

COPY ./certs/devops.crt /usr/local/share/ca-certificates/devops.crt
RUN update-ca-certificates

COPY ./nginx/default.conf.template /etc/nginx/templates/default.conf.template

COPY ./nginx/generate-env-html.sh /usr/local/bin/generate-env-html.sh
RUN chmod +x /usr/local/bin/generate-env-html.sh

# Копируем SSL-сертификаты и ключи прямо внутрь образа
COPY ./certs/devops.crt /etc/nginx/ssl/devops.crt
COPY ./certs/devops.key /etc/nginx/ssl/devops.key

# Копируем скрипт инициализации из папки nginx
COPY ./nginx/50-dynamic-auth-and-static.sh /docker-entrypoint.d/50-dynamic-auth-and-static.sh
RUN chmod +x /docker-entrypoint.d/50-dynamic-auth-and-static.sh
