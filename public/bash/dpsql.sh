#!/bin/bash

if [ -z "$1" ]; then
  echo "Postgres docker terminal usage: $0 <CONTAINER_ID>"
  exit 1
fi

docker exec -it "$1" psql -U postgres -d postgres