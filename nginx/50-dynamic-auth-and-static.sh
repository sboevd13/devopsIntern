#!/bin/sh
mkdir -p /opt/html/root

# Генерируем .htpasswd из переменных окружения контейнера
if [ -n "$BASIC_AUTH_PASSWORD" ]; then
    htpasswd -mbc /etc/nginx/.htpasswd "$REQ_USER" "$BASIC_AUTH_PASSWORD"
fi

# Генерируем базовую статику
echo "<html><head><meta charset=\"UTF-8\"></head><body>" > /opt/html/root/static.html
echo "<h1>Самое популярное слово: ${POPULAR_WORD:-князь} (Частота: ${WORD_FREQUENCY:-1245})</h1>" >> /opt/html/root/static.html
echo "<hr><h2>Вывод /etc/os-release:</h2><pre>" >> /opt/html/root/static.html
cat /etc/os-release >> /opt/html/root/static.html
echo "</pre></body></html>" >> /opt/html/root/static.html

# Запускаем твой второй скрипт
/usr/local/bin/generate-env-html.sh
