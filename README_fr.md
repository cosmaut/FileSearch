# FileSearch

FileSearch est un projet open source haute performance de recherche de ressources netdisk, adapte au deploiement auto-heberge.

> Depot actuel : `https://github.com/cosmaut/FileSearch`
>
> Projet upstream d'origine : `https://github.com/Maishan-Inc/Limitless-search`

## Demarrage rapide

```bash
git clone https://github.com/cosmaut/FileSearch.git
cd FileSearch
docker-compose up -d
```

- Interface Web : `http://localhost:3200`
- API backend : disponible dans le reseau Docker via `http://backend:8888`

## Configuration

- Les variables de build frontend et les variables runtime sont centralisees dans le `docker-compose.yml` a la racine
- Les variables backend comme `CHANNELS` et `ENABLED_PLUGINS` sont egalement configurees dans le `docker-compose.yml` racine
- Si vous lancez le frontend localement sans Docker, creez `web/filesearch_web/.env.local` uniquement si necessaire

## Documentation

- README chinois : [README.md](README.md)
- Documentation backend : [backend/filesearch/docs/README.md](backend/filesearch/docs/README.md)
- Documentation MCP : [backend/filesearch/docs/MCP-SERVICE.md](backend/filesearch/docs/MCP-SERVICE.md)

## Remarque

- Ce depot correspond a votre branche de deploiement renommee `FileSearch`
- Verifiez la licence et les mentions de copyright du projet d'origine avant toute redistribution publique ou usage commercial
