#!/bin/sh
TARGET_FILE="/opt/html/root/index.html"
mkdir -p /opt/html/root

cat << EOF > $TARGET_FILE
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Container Environment Variables</title>
</head>
<body>
    <h1>Переменные окружения контейнера Nginx</h1>
    <p>Сгенерировано автоматически при старте: <strong>$(date)</strong></p>
    <hr>
    <pre>
$(env | sort)
    </pre>
</body>
</html>
EOF
echo "Environment variables successfully written to $TARGET_FILE"
