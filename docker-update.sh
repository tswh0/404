#!/bin/bash

docker compose down
docker compose pull
docker compose up -d
docker image prune -f

echo
echo "done :)"
echo