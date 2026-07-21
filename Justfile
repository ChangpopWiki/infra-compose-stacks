default:
    just --list

up *args="--detach":
    docker compose up {{args}}

down *args:
    docker compose down {{args}}

logs *args:
    docker compose logs {{args}}

exec *args:
    docker compose exec {{args}}

init:
    ./crowdsec/generate_api_key.sh