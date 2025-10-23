## List running containers
`docker container ps`

## List all containers
`docker container ps --all`

## Restart containers
`docker restart $(docker ps -q)`

## Run specific container
`docker start my-ubuntu-container`
`docker start a1f8b7c2d9e6`

## Stop specific container
`docker stop my-nginx-container`
`docker stop b6f4e15b3c59`

# Restart specific container
`docker restart my-nginx-container`
`docker restart b6f4e15b3c59`

## Run all stopped containers
`docker start $(docker ps -a -q)`

## Run Postgres CLI
`docker exec -it CONTAINER_ID psql -U postgres -d postgres`

