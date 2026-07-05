#!/bin/bash

# Настройка локали для стабильной работы grep с кириллицей
export LC_ALL=ru_RU.UTF-8
export LANG=ru_RU.UTF-8

LOG_OK="success.log"
LOG_ERR="error.log"

# Функция для логирования результатов выполнения команд
log_status() {
    local exit_code=$1
    local success_msg=$2
    local error_msg=$3
    if [ $exit_code -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [OK] (код: $exit_code) $success_msg" >> "$LOG_OK"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') [FAIL] (код: $exit_code) $error_msg" >> "$LOG_ERR"
    fi
}

# Шаблон для вывода статистики curl в формате JSON via -w
CURL_JSON_FORMAT='{\n  "url_effective": "%{url_effective}",\n  "http_code": %{http_code},\n  "time_total": %{time_total},\n  "time_namelookup": %{time_namelookup},\n  "time_connect": %{time_connect},\n  "time_starttransfer": %{time_starttransfer},\n  "size_download": %{size_download},\n  "speed_download": %{speed_download}\n}\n'

# Проверка аргументов
if [ $# -lt 2 ]; then
    echo "Ошибка: нужно два аргумента"
    # По ТЗ: если пользователь не передал аргументы, это выводится на экран и в лог файл (не в лог ошибок)
    echo "$(date '+%Y-%m-%d %H:%M:%S') Ошибка: пользователь не передал аргументы скрипту" >> "$LOG_OK"
    exit 1
fi

SITE=$1
FILE_URL=$2

URL="https://avidreaders.ru/download/voyna-i-mir-tom-1.html?f=txt"
FINAL_URL="https://avidreaders.ru/api/get.php?b=80843&f=txt"

# --- 1. Скачивание «Война и мир» ---
echo "Скачивание книги..."
curl -L "$FINAL_URL" \
     -H "Referer: $URL" \
     -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' \
     -o "war_and_peace.zip"
STATUS=$?
log_status $STATUS "Книга 'Война и мир' успешно скачана" "Ошибка скачивания книги 'Война и мир'"
[ $STATUS -ne 0 ] && exit 1

# --- 2. Распаковка ---
echo "Распаковка архива..."
unzip -o -j war_and_peace.zip -d .
STATUS=$?
log_status $STATUS "Архив успешно распакован в папку book" "Ошибка распаковки архива war_and_peace.zip"
[ $STATUS -ne 0 ] && exit 1

rm -f war_and_peace.zip

# Находим распакованный текстовый файл
TEXT_FILE=$(find . -maxdepth 1 -type f -name "*.txt" | head -n 1)

# Исправление кодировки
iconv -f windows-1251 -t utf-8 "$TEXT_FILE" > "$TEXT_FILE.tmp" && mv "$TEXT_FILE.tmp" "$TEXT_FILE"
log_status $? "Кодировка файла успешно конвертирована в UTF-8" "Ошибка при изменении кодировки файла через iconv"

# Сбор и фильтрация слов (длиной > 5 символов, т.е. от 6)
WORDS=$(grep -oE '[а-яА-ЯёЁa-zA-Z]{6,}' "$TEXT_FILE" | awk '{print tolower($0)}')
TOP5=$(echo "$WORDS" | sort | uniq -c | sort -nr | head -n 5)

echo "----------------------------------------"
echo "TOP 5 WORD:"
echo "$TOP5"
echo "----------------------------------------"

# --- 3. Проверка логических условий на слова ---

# Проверка наличия слова «князь» в ТОП-5
if echo "$TOP5" | grep -q "князь"; then
    echo "Слово 'князь' найдено в ТОП-5. Выполняю запрос к ya.ru..."
    curl -s -o /dev/null -w "$CURL_JSON_FORMAT" "https://ya.ru"
    log_status $? "Запрос статистики для ya.ru выполнен" "Ошибка при запросе статистики к ya.ru"
fi

# Проверка отсутствия слова «говорил» в ТОП-5
if ! echo "$TOP5" | grep -q "говорил"; then
    echo "Слова 'говорил' НЕТ в ТОП-5. Выполняю запрос к google.coom..."
    # Используем max-time, так как домен google.coom может не отвечать или вешать сессию
    curl -s -m 5 -o /dev/null -w "$CURL_JSON_FORMAT" "https://google.coom"
    log_status $? "Запрос статистики для google.coom выполнен" "Ошибка при запросе статистики к google.coom"
fi

# --- 4. Запрос к сайту из первого аргумента ($SITE) ---
echo "Выполняю запрос к сайту из аргумента 1 ($SITE)..."
curl -s -o /dev/null -w "$CURL_JSON_FORMAT" "$SITE"
log_status $? "Запрос статистики для сайта $SITE выполнен" "Ошибка при запросе статистики к сайту $SITE"

# --- 5. Работа со вторым аргументом ($FILE_URL) и папкой download ---
DOWNLOAD_DIR="download"

if [ ! -d "$DOWNLOAD_DIR" ]; then
    mkdir -p "$DOWNLOAD_DIR"
    STATUS=$?
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Создана папка $DOWNLOAD_DIR" >> "$LOG_OK"
    log_status $STATUS "Папка $DOWNLOAD_DIR успешно создана" "Не удалось создать папку $DOWNLOAD_DIR"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Папка $DOWNLOAD_DIR уже существует" >> "$LOG_OK"
fi

# Выделяем имя файла из URL
DOWNLOADED_FILE_NAME=$(basename "$FILE_URL" | cut -d? -f1)
# Если имя файла определить не удалось, даем дефолтное
[ -z "$DOWNLOADED_FILE_NAME" ] && DOWNLOADED_FILE_NAME="downloaded_file.tmp"

TARGET_PATH="$DOWNLOAD_DIR/$DOWNLOADED_FILE_NAME"

echo "Скачивание файла из аргумента 2 в папку $DOWNLOAD_DIR..."
curl -L "$FILE_URL" -o "$TARGET_PATH"
STATUS=$?
log_status $STATUS "Файл из аргумента 2 успешно скачан в $TARGET_PATH" "Ошибка скачивания файла из аргумента 2"

# --- 6. Вывод статистики скачанного файла ---
if [ $STATUS -eq 0 ] && [ -f "$TARGET_PATH" ]; then
    echo "----------------------------------------"
    echo "СТАТИСТИКА СКАЧАННОГО ФАЙЛА:"
    
    # Получаем данные через stat (совместимо с GNU/Linux)
    OWNER=$(stat -c '%U' "$TARGET_PATH")
    GROUP=$(stat -c '%G' "$TARGET_PATH")
    PERMS=$(stat -c '%a (%A)' "$TARGET_PATH")
    SIZE=$(stat -c '%s байт' "$TARGET_PATH")
    
    # Пути
    FULL_PATH=$(realpath "$TARGET_PATH")
    # Относительный путь от скрипта
    SCRIPT_DIR=$(dirname "$(realpath "$0")")
    # Переходим в папку скрипта и вычисляем относительный путь
    RELATIVE_PATH=$(realpath --relative-to="$SCRIPT_DIR" "$FULL_PATH")

    echo "Владелец: $OWNER"
    echo "Группа владельца: $GROUP"
    echo "Права доступа: $PERMS"
    echo "Размер файла: $SIZE"
    echo "Относительный путь от скрипта: $RELATIVE_PATH"
    echo "Полный путь от корня ФС: $FULL_PATH"
    echo "----------------------------------------"
fi
