# FileSearch

FileSearch 是一個高效能的開源網盤資源搜尋專案，適合自架部署使用。

> 當前倉庫：`https://github.com/cosmaut/FileSearch`
>
> 原始上游專案：`https://github.com/Maishan-Inc/Limitless-search`

## 快速開始

```bash
git clone https://github.com/cosmaut/FileSearch.git
cd FileSearch
docker-compose up -d
```

- Web 介面：`http://localhost:3200`
- 後端 API：Docker 網路內可用 `http://backend:8888`

## 配置說明

- 前端 Docker 建置參數與執行期環境變數統一配置在根目錄 `docker-compose.yml`
- 後端的 `CHANNELS`、`ENABLED_PLUGINS` 等變數也在根目錄 `docker-compose.yml`
- 如果你是本地直接執行前端而不是使用 Docker，才需要建立 `web/filesearch_web/.env.local`

## 文件入口

- 簡體中文說明：[README.md](README.md)
- 後端文件：[backend/filesearch/docs/README.md](backend/filesearch/docs/README.md)
- MCP 文件：[backend/filesearch/docs/MCP-SERVICE.md](backend/filesearch/docs/MCP-SERVICE.md)

## 注意事項

- 此倉庫是你自己的 `FileSearch` 改名部署分支
- 如果要公開散佈或商業使用，請先確認原專案授權與版權說明
