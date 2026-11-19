#!/bin/bash
# 사용법: ./scripts/run.sh <command> <env> [flutter 추가 인자...]
# command: run, apk, aab, ios, ipa
# env: dev, prod
#
# 환경별 env 파일(.env.development / .env.production)을 서브모듈에서 복호화하고
# --dart-define-from-file로 앱에 넘긴다. 공용 .env는 쓰지 않는다.
# 앱 안에서 개발/운영 웹을 전환할 수 있으므로, 두 환경의 카카오 키는
# 각 env 파일에서 꺼내 KAKAO_NATIVE_APP_KEY_DEV/PROD로 함께 넘긴다.
set -euo pipefail

COMMAND=${1:-run}
ENV=${2:-dev}
shift $(( $# < 2 ? $# : 2 ))

FLUTTER=${FLUTTER:-fvm flutter}
SOPS_DIR="git.environment-variables/application.flutter"

case $ENV in
  dev)  ENV_FILE=".env.development" ;;
  prod) ENV_FILE=".env.production" ;;
  *) echo "Unknown env: $ENV (use: dev, prod)"; exit 1 ;;
esac

cd "$(dirname "$0")/.."

if [ ! -f "$SOPS_DIR/dev.sops.env" ] || [ ! -f "$SOPS_DIR/prod.sops.env" ]; then
  echo "📦 Initializing git submodule..."
  git submodule update --init git.environment-variables
fi

# 없거나 서브모듈보다 오래된 env 파일만 복호화한다.
decrypt_env() {
  local sops_file=$1 env_file=$2
  if [ ! -f "$env_file" ] || [ "$sops_file" -nt "$env_file" ]; then
    echo "🔐 Decrypting $sops_file → $env_file"
    sops -d --input-type dotenv --output-type dotenv "$sops_file" > "$env_file"
  fi
}

decrypt_env "$SOPS_DIR/dev.sops.env" .env.development
decrypt_env "$SOPS_DIR/prod.sops.env" .env.production

kakao_key_of() {
  local key
  key=$(sed -n 's/^KAKAO_NATIVE_APP_KEY=//p' "$1" | tail -1)
  if [ -z "$key" ]; then
    echo "❌ $1에 KAKAO_NATIVE_APP_KEY가 없습니다." >&2
    exit 1
  fi
  echo "$key"
}

KAKAO_KEY_DEV=$(kakao_key_of .env.development)
KAKAO_KEY_PROD=$(kakao_key_of .env.production)

DEFINES=(
  "--dart-define-from-file=$ENV_FILE"
  "--dart-define=KAKAO_NATIVE_APP_KEY_DEV=$KAKAO_KEY_DEV"
  "--dart-define=KAKAO_NATIVE_APP_KEY_PROD=$KAKAO_KEY_PROD"
)

case $COMMAND in
  run) $FLUTTER run "${DEFINES[@]}" "$@" ;;
  apk) $FLUTTER build apk "${DEFINES[@]}" "$@" ;;
  aab) $FLUTTER build appbundle "${DEFINES[@]}" "$@" ;;
  ios) $FLUTTER build ios "${DEFINES[@]}" "$@" ;;
  ipa) $FLUTTER build ipa "${DEFINES[@]}" "$@" ;;
  *) echo "Unknown command: $COMMAND (use: run, apk, aab, ios, ipa)"; exit 1 ;;
esac
