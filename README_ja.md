# FileSearch

FileSearch は、セルフホスト向けの高性能なオープンソース網盤リソース検索プロジェクトです。

> 現在のリポジトリ: `https://github.com/cosmaut/FileSearch`
>
> 元の上流プロジェクト: `https://github.com/Maishan-Inc/Limitless-search`

## クイックスタート

```bash
git clone https://github.com/cosmaut/FileSearch.git
cd FileSearch
docker-compose up -d
```

- Web UI: `http://localhost:3200`
- バックエンド API: Docker ネットワーク内で `http://backend:8888`

## 設定

- フロントエンドの Docker build 引数と実行時環境変数は、ルートの `docker-compose.yml` にまとめてあります
- `CHANNELS` や `ENABLED_PLUGINS` などのバックエンド設定も、ルートの `docker-compose.yml` で管理します
- Docker を使わずにフロントエンドをローカル実行する場合のみ `web/filesearch_web/.env.local` を作成してください

## ドキュメント

- 中国語 README: [README.md](README.md)
- バックエンド資料: [backend/filesearch/docs/README.md](backend/filesearch/docs/README.md)
- MCP 資料: [backend/filesearch/docs/MCP-SERVICE.md](backend/filesearch/docs/MCP-SERVICE.md)

## 注意

- このリポジトリは、あなた自身の `FileSearch` リネーム版デプロイブランチです
- 公開配布や商用利用の前に、元プロジェクトのライセンスと著作権表記を確認してください
