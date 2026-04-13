# FileSearch

FileSearch is a high-performance open-source netdisk resource search project for self-hosted deployment.

> Current repository: `https://github.com/cosmaut/FileSearch`
>
> Original upstream project: `https://github.com/Maishan-Inc/Limitless-search`

## Quick Start

```bash
git clone https://github.com/cosmaut/FileSearch.git
cd FileSearch
docker-compose up -d
```

- Web UI: `http://localhost:3200`
- Backend API: available inside Docker network at `http://backend:8888`

## Configuration

- Frontend Docker build args and runtime variables are configured in the root `docker-compose.yml`
- Backend variables such as `CHANNELS` and `ENABLED_PLUGINS` are also configured in the root `docker-compose.yml`
- If you run the frontend locally without Docker, create `web/filesearch_web/.env.local` only when needed

## Documentation

- Chinese README: [README.md](README.md)
- Backend docs: [backend/filesearch/docs/README.md](backend/filesearch/docs/README.md)
- MCP docs: [backend/filesearch/docs/MCP-SERVICE.md](backend/filesearch/docs/MCP-SERVICE.md)

## Notice

- This repository is your renamed deployment branch of the project
- Please review the original license and upstream copyright notes before public redistribution or commercial usage
