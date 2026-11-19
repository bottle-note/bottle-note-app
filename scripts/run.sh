#!/bin/bash
# 사용법: ./scripts/run.sh <command> <env> [flutter 추가 인자...]
# command: run, apk, aab, ios, ipa
# env: dev, prod
#
# 환경별 env 파일(.env.development / .env.production)을 서브모듈에서 복호화하고
# --dart-define-from-file로 앱에 넘긴다. 공용 .env는 쓰지 않는다.
set -euo pipefail

COMMAND=${1:-run}
ENV=${2:-dev}
shift $(( $# < 2 ? $# : 2 ))

FLUTTER=${FLUTTER:-fvm flutter}
SOPS_DIR="git.environment-variables/application.flutter"

case $ENV in
  dev)  SOPS_FILE="$SOPS_DIR/dev.sops.env";  ENV_FILE=".env.development" ;;
  prod) SOPS_FILE="$SOPS_DIR/prod.sops.env"; ENV_FILE=".env.production" ;;
  *) echo "Unknown env: $ENV (use: dev, prod)"; exit 1 ;;
esac

cd "$(dirname "$0")/.."

if [ ! -f "$SOPS_FILE" ]; then
  echo "📦 Initializing git submodule..."
  git submodule update --init git.environment-variables
fi

if [ ! -f "$ENV_FILE" ] || [ "$SOPS_FILE" -nt "$ENV_FILE" ]; then
  echo "🔐 Decrypting $ENV environment → $ENV_FILE"
  sops -d --input-type dotenv --output-type dotenv "$SOPS_FILE" > "$ENV_FILE"
fi

DEFINE="--dart-define-from-file=$ENV_FILE"

case $COMMAND in
  run) $FLUTTER run "$DEFINE" "$@" ;;
  apk) $FLUTTER build apk "$DEFINE" "$@" ;;
  aab) $FLUTTER build appbundle "$DEFINE" "$@" ;;
  ios) $FLUTTER build ios "$DEFINE" "$@" ;;
  ipa) $FLUTTER build ipa "$DEFINE" "$@" ;;
  *) echo "Unknown command: $COMMAND (use: run, apk, aab, ios, ipa)"; exit 1 ;;
esac
