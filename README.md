# IPFS DHT Explorer


## Related projects
- mindmax GeoLite2
- https://github.com/andrew/libp2p-dht-scrape-aas
- https://github.com/andrew/libp2p-dht-scrape-client

## Alternative scrapers
- https://github.com/wiberlin/ipfs-crawler
- https://github.com/whyrusleeping/ipfs-counter
- https://github.com/ipfs-shipyard/ipfs-counter


## Docker

Build the image:

```
docker build -t ipfsshipyard/ipfs_dht_explorer:latest .
```

Push it to docker hub

```
docker push ipfsshipyard/ipfs_dht_explorer:latest
```

To access the rails console:

```
docker-compose exec app rails console
```

Export the postgres database

```
docker exec -u postgres ipfs_dht_explorer_database.service.explorer.internal_1 pg_dump -Fc postgres > db.dump
```
