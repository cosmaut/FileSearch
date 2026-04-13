# FileSearch

FileSearch - это высокопроизводительный open-source проект для поиска ресурсов в облачных дисках, предназначенный для самостоятельного развертывания.

> Текущий репозиторий: `https://github.com/cosmaut/FileSearch`
>
> Исходный upstream-проект: `https://github.com/Maishan-Inc/Limitless-search`

## Быстрый старт

```bash
git clone https://github.com/cosmaut/FileSearch.git
cd FileSearch
docker-compose up -d
```

- Web-интерфейс: `http://localhost:3200`
- Backend API: доступен внутри Docker-сети по адресу `http://backend:8888`

## Конфигурация

- Параметры сборки фронтенда и runtime-переменные настраиваются в корневом `docker-compose.yml`
- Переменные backend, такие как `CHANNELS` и `ENABLED_PLUGINS`, также задаются в корневом `docker-compose.yml`
- Если вы запускаете фронтенд локально без Docker, создайте `web/filesearch_web/.env.local` только при необходимости

## Документация

- Китайский README: [README.md](README.md)
- Документация backend: [backend/filesearch/docs/README.md](backend/filesearch/docs/README.md)
- Документация MCP: [backend/filesearch/docs/MCP-SERVICE.md](backend/filesearch/docs/MCP-SERVICE.md)

## Важно

- Этот репозиторий является вашей собственной переименованной веткой развертывания `FileSearch`
- Перед публичным распространением или коммерческим использованием проверьте лицензию и авторские примечания исходного проекта
