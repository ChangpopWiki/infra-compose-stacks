#!/usr/bin/env sh

set -o errexit
set -o nounset

if [ -f "${CROWDSEC_API_KEY_FILE}" ] && [ -s "${CROWDSEC_API_KEY_FILE}" ]; then
    echo "==> CrowdSec API 키 발견, CrowdSec 연동 활성화"
    CROWDSEC_API_KEY="$(cat "${CROWDSEC_API_KEY_FILE}")"
    export CROWDSEC_API_KEY
else
    echo "==> 경고: CrowdSec API 키가 없습니다. (${CROWDSEC_API_KEY_FILE})." >&2
    echo "==> ../crowdsec/generate_api_key.sh 을 통해 키를 생성할 수 있습니다." >&2
fi

# log 마운트 디렉토리 권한 보장
mkdir -p /log
chown root:1000 /log
chmod 2775 /log

# Caddy 실행
exec caddy run --config /etc/caddy/Caddyfile