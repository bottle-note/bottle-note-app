# ============================================
# 🚀 초기 설정 & 클린업
# ============================================

# Flutter 명령어 (FVM 사용)
FLUTTER := fvm flutter
DART := fvm dart

# 서브모듈 경로
ENV_SUBMODULE := git.environment-variables/application.flutter

# 실행/빌드 스크립트 (환경별 env 복호화 + --dart-define-from-file)
RUN := ./scripts/run.sh

# 워크스페이스 초기화 (새 워크스페이스에서 처음 실행)
setup:
	@echo "======워크스페이스 초기화 중...======"
	git submodule update --init --recursive
	@fvm flutter --version || (echo "❌ FVM이 설치되지 않았습니다. brew install fvm 실행 후 fvm use 3.32.8 실행하세요." && exit 1)
	@which sops > /dev/null || (echo "❌ SOPS가 설치되지 않았습니다. brew install sops 실행하세요." && exit 1)
	$(FLUTTER) pub get
	@echo "✅ 초기화 완료! (env 파일은 make run-dev 등 실행 시 자동 복호화)"

# ============================================
# 🔐 배포 비밀값 (서명·App Store Connect)
# ============================================

# release.sops.env → .env.release (없거나 sops 파일이 더 최신일 때)
.env.release: $(ENV_SUBMODULE)/release.sops.env
	@echo "======배포 비밀값 복호화 중...======"
	sops -d --input-type dotenv --output-type dotenv $< > $@
	@echo "✅ .env.release 복호화 완료!"

$(ENV_SUBMODULE)/release.sops.env:
	git submodule update --init git.environment-variables

decrypt-env-release: .env.release

# Android 서명 설정 (.env.release → secrets/)
setup-signing: .env.release
	@echo "======Android 서명 설정 중...======"
	@mkdir -p secrets
	@KEYSTORE_PASSWORD=$$(grep '^KEYSTORE_PASSWORD=' .env.release | cut -d '=' -f2); \
	KEY_PASSWORD=$$(grep '^KEY_PASSWORD=' .env.release | cut -d '=' -f2); \
	KEY_ALIAS=$$(grep '^KEY_ALIAS=' .env.release | cut -d '=' -f2); \
	KEYSTORE_BASE64=$$(grep '^KEYSTORE_BASE64=' .env.release | sed 's/^KEYSTORE_BASE64=//'); \
	if [ -z "$$KEYSTORE_PASSWORD" ] || [ -z "$$KEY_PASSWORD" ] || [ -z "$$KEY_ALIAS" ] || [ -z "$$KEYSTORE_BASE64" ]; then \
		echo "❌ .env.release에 Android Signing 값이 누락되었습니다."; \
		echo "   필요한 값: KEYSTORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS, KEYSTORE_BASE64"; \
		exit 1; \
	fi; \
	echo "storePassword=$$KEYSTORE_PASSWORD" > secrets/key.properties; \
	echo "keyPassword=$$KEY_PASSWORD" >> secrets/key.properties; \
	echo "keyAlias=$$KEY_ALIAS" >> secrets/key.properties; \
	echo "storeFile=upload-keystore.jks" >> secrets/key.properties; \
	echo "$$KEYSTORE_BASE64" | base64 --decode > secrets/upload-keystore.jks
	@echo "✅ Android 서명 설정 완료!"

# 전체 클린 빌드 (문제 발생시 사용)
fresh:
	@echo "======전체 클린 빌드 시작...======"
	$(FLUTTER) clean
	$(FLUTTER) pub get
	@echo "✅ 클린 빌드 완료!"

# iOS 캐시 완전 정리 (iOS 빌드 문제시 사용)
clean-ios:
	@echo "======iOS 캐시 완전 정리 중...======"
	cd ios && rm -rf Pods Podfile.lock .symlinks
	cd ios && pod cache clean --all
	$(FLUTTER) clean
	$(FLUTTER) pub get
	cd ios && pod install
	@echo "✅ iOS 캐시 정리 완료!"

# iOS 캐시 빠른 정리 (pod만 재설치)
clean-ios-quick:
	@echo "======iOS Pod 재설치 중...======"
	cd ios && rm -rf Pods Podfile.lock
	cd ios && pod install
	@echo "✅ Pod 재설치 완료!"

# Android 캐시 정리
clean-android:
	@echo "======Android 캐시 정리 중...======"
	cd android && ./gradlew clean
	$(FLUTTER) clean
	$(FLUTTER) pub get
	@echo "✅ Android 캐시 정리 완료!"

# ============================================
# 🏷️ 버전 관리 (cider)
# ============================================

# 현재 버전 확인
version:
	@dart pub global run cider version

# 빌드 번호만 +1 (1.0.5+23 → 1.0.5+24)
bump-build:
	@echo "======빌드 번호 증가 중...======"
	@dart pub global run cider bump build
	@echo "✅ 새 버전: $$(dart pub global run cider version)"

# 패치 버전 +1 (1.0.5+23 → 1.0.6+24)
bump-patch:
	@echo "======패치 버전 증가 중...======"
	@dart pub global run cider bump patch
	@echo "✅ 새 버전: $$(dart pub global run cider version)"

# 마이너 버전 +1 (1.0.5+23 → 1.1.0+24)
bump-minor:
	@echo "======마이너 버전 증가 중...======"
	@dart pub global run cider bump minor
	@echo "✅ 새 버전: $$(dart pub global run cider version)"

# 메이저 버전 +1 (1.0.5+23 → 2.0.0+24)
bump-major:
	@echo "======메이저 버전 증가 중...======"
	@dart pub global run cider bump major
	@echo "✅ 새 버전: $$(dart pub global run cider version)"

# ============================================
# 🚀 실행 (scripts/run.sh <cmd> <dev|prod>)
# ============================================

# 프로덕션 환경 실행
run:
	$(RUN) run prod

# 개발 환경 실행
run-dev:
	$(RUN) run dev

# 로컬 웹서버(localhost:3000) 연결 실행
run-local:
	$(RUN) run dev --dart-define=USE_LOCAL_WEBVIEW=true

# 프로덕션 환경 실행 (별칭)
run-prod: run

# ============================================
# 🔨 빌드
# ============================================

# 개발 환경 빌드 (Android APK)
build-dev-android:
	$(RUN) apk dev

# 프로덕션 환경 빌드 (Android APK)
build-prod-android: setup-signing
	$(RUN) apk prod --release

# 프로덕션 환경 빌드 (Android AAB - Play Store용)
build-prod-android-aab: setup-signing
	$(RUN) aab prod --release

# 개발 환경 빌드 (iOS)
build-dev-ios:
	$(RUN) ios dev

# 프로덕션 환경 빌드 (iOS)
build-prod-ios:
	$(RUN) ios prod --release

# ============================================
# 🍎 iOS 배포 (Fastlane)
# ============================================

# iOS 배포 도구 설치 (최초 1회)
setup-ios-deploy:
	@echo "======iOS 배포 도구 설치 중...======"
	@which bundle > /dev/null || (echo "❌ Bundler가 없습니다. gem install bundler 실행하세요." && exit 1)
	cd ios && bundle install
	@echo "✅ Fastlane 설치 완료!"

# .env.release에서 ASC 인증 환경변수 검증 헬퍼
_load-asc-env: .env.release
	@ASC_KEY_ID=$$(grep '^ASC_KEY_ID=' .env.release | sed 's/^ASC_KEY_ID=//'); \
	ASC_ISSUER_ID=$$(grep '^ASC_ISSUER_ID=' .env.release | sed 's/^ASC_ISSUER_ID=//'); \
	ASC_KEY_BASE64=$$(grep '^ASC_KEY_BASE64=' .env.release | sed 's/^ASC_KEY_BASE64=//'); \
	if [ -z "$$ASC_KEY_ID" ] || [ -z "$$ASC_ISSUER_ID" ] || [ -z "$$ASC_KEY_BASE64" ]; then \
		echo "❌ .env.release에 App Store Connect API 키 정보가 누락되었습니다."; \
		echo "   필요한 값: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_BASE64"; \
		echo ""; \
		echo "   [설정 방법]"; \
		echo "   1. App Store Connect → 사용자 및 액세스 → 통합 → API 키 생성"; \
		echo "   2. .p8 파일을 base64 인코딩: base64 -i AuthKey_XXXX.p8"; \
		echo "   3. .env.release에 추가:"; \
		echo "      ASC_KEY_ID=키ID"; \
		echo "      ASC_ISSUER_ID=발급자ID"; \
		echo "      ASC_KEY_BASE64=base64인코딩값"; \
		exit 1; \
	fi

# IPA 빌드 (내부 헬퍼 - Fastfile에서 호출)
_build-ios-ipa:
	@echo "======iOS IPA 빌드 중...======"
	$(RUN) ipa prod --release --export-options-plist=ios/ExportOptions.plist 2>/dev/null || \
	$(RUN) ipa prod --release
	@echo "✅ IPA 빌드 완료!"

# TestFlight 배포
deploy-ios-testflight: _load-asc-env
	@echo "======iOS TestFlight 배포 중...======"
	@# IPA 빌드
	$(MAKE) _build-ios-ipa
	@# Fastlane 실행 (환경변수 전달: base64 디코딩하여 키 내용 전달)
	@export ASC_KEY_ID=$$(grep '^ASC_KEY_ID=' .env.release | sed 's/^ASC_KEY_ID=//'); \
	export ASC_ISSUER_ID=$$(grep '^ASC_ISSUER_ID=' .env.release | sed 's/^ASC_ISSUER_ID=//'); \
	export ASC_KEY_CONTENT=$$(grep '^ASC_KEY_BASE64=' .env.release | sed 's/^ASC_KEY_BASE64=//' | base64 --decode); \
	IPA_FILE=$$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1); \
	if [ -z "$$IPA_FILE" ]; then echo "❌ IPA 파일을 찾을 수 없습니다. 빌드를 확인하세요."; exit 1; fi; \
	export IPA_PATH=$$(pwd)/$$IPA_FILE; \
	cd ios && bundle exec fastlane beta
	@echo "✅ TestFlight 배포 완료!"

# TestFlight 배포 (별칭)
deploy-ios: deploy-ios-testflight

# App Store 제출
deploy-ios-appstore: _load-asc-env
	@echo "======iOS App Store 제출 중...======"
	@# IPA 빌드
	$(MAKE) _build-ios-ipa
	@# Fastlane 실행 (환경변수 전달: base64 디코딩하여 키 내용 전달)
	@export ASC_KEY_ID=$$(grep '^ASC_KEY_ID=' .env.release | sed 's/^ASC_KEY_ID=//'); \
	export ASC_ISSUER_ID=$$(grep '^ASC_ISSUER_ID=' .env.release | sed 's/^ASC_ISSUER_ID=//'); \
	export ASC_KEY_CONTENT=$$(grep '^ASC_KEY_BASE64=' .env.release | sed 's/^ASC_KEY_BASE64=//' | base64 --decode); \
	IPA_FILE=$$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1); \
	if [ -z "$$IPA_FILE" ]; then echo "❌ IPA 파일을 찾을 수 없습니다. 빌드를 확인하세요."; exit 1; fi; \
	export IPA_PATH=$$(pwd)/$$IPA_FILE; \
	cd ios && bundle exec fastlane release
	@echo "✅ App Store 제출 완료!"

# ============================================
# 📋 도움말
# ============================================

help:
	@echo ""
	@echo "🍾 Bottle Note Flutter 프로젝트 명령어"
	@echo ""
	@echo "📦 초기 설정 & 클린업:"
	@echo "  make setup          - 워크스페이스 초기화 (서브모듈 + pub get)"
	@echo "  make setup-signing  - Android 서명 설정 (.env.release → secrets/)"
	@echo "  make fresh          - 전체 클린 빌드"
	@echo "  make clean-ios      - iOS 캐시 완전 정리"
	@echo "  make clean-ios-quick - iOS Pod만 재설치"
	@echo "  make clean-android  - Android 캐시 정리"
	@echo ""
	@echo "🔐 환경 변수 (SOPS):"
	@echo "  앱 env(.env.development / .env.production)는 run/build 시 scripts/run.sh가 자동 복호화"
	@echo "  make decrypt-env-release - 배포 비밀값(서명·ASC) 복호화 → .env.release"
	@echo ""
	@echo "🏷️ 버전 관리:"
	@echo "  make version        - 현재 버전 확인"
	@echo "  make bump-build     - 빌드 번호 +1 (1.0.5+23 → 1.0.5+24)"
	@echo "  make bump-patch     - 패치 버전 +1 (1.0.5 → 1.0.6)"
	@echo "  make bump-minor     - 마이너 버전 +1 (1.0.5 → 1.1.0)"
	@echo "  make bump-major     - 메이저 버전 +1 (1.0.5 → 2.0.0)"
	@echo ""
	@echo "🚀 실행:"
	@echo "  make run            - 프로덕션 환경 실행 (FLAVOR=prod)"
	@echo "  make run-dev        - 개발 환경 실행 (FLAVOR=dev)"
	@echo "  make run-local      - 로컬 웹서버 연결 (localhost:3000)"
	@echo "  make run-prod       - 프로덕션 환경 실행 (별칭)"
	@echo ""
	@echo "🔨 빌드:"
	@echo "  make build-dev-android    - 개발 APK 빌드"
	@echo "  make build-prod-android   - 프로덕션 APK 빌드"
	@echo "  make build-prod-android-aab - 프로덕션 AAB 빌드"
	@echo "  make build-dev-ios        - 개발 iOS 빌드"
	@echo "  make build-prod-ios       - 프로덕션 iOS 빌드"
	@echo ""
	@echo "🍎 iOS 배포 (Fastlane):"
	@echo "  make setup-ios-deploy       - Fastlane 설치 (최초 1회)"
	@echo "  make deploy-ios             - TestFlight 배포 (별칭)"
	@echo "  make deploy-ios-testflight  - TestFlight 배포"
	@echo "  make deploy-ios-appstore    - App Store 제출"
	@echo ""
	@echo "  [사전 준비]"
	@echo "  1. App Store Connect → 사용자 및 액세스 → 통합 → API 키 생성"
	@echo "  2. .p8 파일을 base64 인코딩: base64 -i AuthKey_XXXX.p8"
	@echo "  3. environment-variables의 application.flutter/release.sops.env에 ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_BASE64 추가"
	@echo ""

.PHONY: setup setup-signing decrypt-env-release fresh clean-ios clean-ios-quick clean-android \
        version bump-build bump-patch bump-minor bump-major \
        run run-dev run-local run-prod \
        build-dev-android build-prod-android build-prod-android-aab \
        build-dev-ios build-prod-ios \
        setup-ios-deploy _load-asc-env _build-ios-ipa \
        deploy-ios deploy-ios-testflight deploy-ios-appstore help
