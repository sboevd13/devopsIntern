#!/bin/sh

# Путь к нашему index.html внутри контейнера
TARGET_FILE="/opt/html/root/index.html"

# Создаем структуру HTML-файла и пишем туда вывод команды env
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
