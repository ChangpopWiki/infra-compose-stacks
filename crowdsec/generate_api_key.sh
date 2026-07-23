#!/usr/bin/env bash
#
# crowdsec에서 bouncer API 키를 발급받아 reverse-proxy의 secrets 디렉터리에 저장합니다.

set -o errexit
set -o nounset
set -o pipefail

log() { echo "==> $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

BOUNCER_NAME="caddy-bouncer"
SECRET_PATH="../reverse-proxy/var/secrets/crowdsec_api_key"

# sudo로 실행됐다면(SUDO_UID/SUDO_GID는 sudo가 자동 설정) 스크립트 종료 시
# 생성된 파일의 소유권을 원래 호출한 사용자로 되돌립니다.
restore_ownership() {
    if [ -n "${SUDO_UID:-}" ] && [ -n "${SUDO_GID:-}" ]; then
        chown --recursive "${SUDO_UID}:${SUDO_GID}" "$(dirname "${SECRET_PATH}")"
    fi
}
trap restore_ownership EXIT

log "CrowdSec API 키 발급 및 저장 스크립트 시작"

if [ -f "${SECRET_PATH}" ] && [ -s "${SECRET_PATH}" ]; then
    log "이미 키가 존재합니다, 건너뜁니다: ${SECRET_PATH}"
    exit 0
fi

# Compose secrets가 파일 없이 up 되면 그 자리에 root 소유 디렉터리를 만들어버립니다.
if [ -d "${SECRET_PATH}" ]; then
    log "${SECRET_PATH} 가 디렉터리로 잘못 생성되어 있습니다, 제거를 시도합니다"
    if ! rmdir "${SECRET_PATH}" 2>/dev/null; then
        log "제거에 실패했습니다 — sudo로 다시 실행해주세요" >&2
        exit 1
    fi
fi

log "crowdsec이 준비될 때까지 기다리는 중..."
docker compose up --detach --wait crowdsec

log "bouncer 키를 발급받습니다: ${BOUNCER_NAME}"
mkdir --parents "$(dirname "${SECRET_PATH}")"

# 키 파일만 사라지고 DB엔 등록이 남아있는 경우를 대비해, 지우고 재발급합니다.
docker compose exec --no-TTY crowdsec \
    cscli bouncers delete "${BOUNCER_NAME}" --output raw >/dev/null 2>&1 || true

if ! touch "${SECRET_PATH}" 2>/dev/null; then
    log "${SECRET_PATH} 에 쓰기 권한이 없습니다 — sudo로 다시 실행해주세요" >&2
    exit 1
fi

docker compose exec --no-TTY crowdsec \
    cscli bouncers add "${BOUNCER_NAME}" --output raw > "${SECRET_PATH}"
chmod 600 "${SECRET_PATH}"

log "완료했습니다: ${SECRET_PATH}"
log "이제 전체 스택을 올려주세요: docker compose --project-directory .. up --detach"