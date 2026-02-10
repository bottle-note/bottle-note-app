# ============================================
# 🚀 초기 설정 & 클린업
# ============================================

# Flutter 명령어 (FVM 사용)
FLUTTER := fvm flutter
DART := fvm dart

# 서브모듈 경로
ENV_SUBMODULE := git.environment-variables/application.flutter

# 워크스페이스 초기화 (새 워크스페이스에서 처음 실행)
setup:
	@echo "======워크스페이스 초기화 중...======"
	@# 서브모듈 초기화
	git submodule update --init --recursive
	@# FVM 버전 확인
	@fvm flutter --version || (echo "❌ FVM이 설치되지 않았습니다. brew install fvm 실행 후 fvm use 3.32.8 실행하세요." && exit 1)
	@# SOPS 확인
	@which sops > /dev/null || (echo "❌ SOPS가 설치되지 않았습니다. brew install sops 실행하세요." && exit 1)
	@# env 복호화 (dev 기본)
	@if [ ! -f ".env.dev" ]; then \
		echo "⚠️  .env.dev 없음 → 서브모듈에서 복호화..."; \
		$(MAKE) prepare-env-dev; \
	else \
		echo "✅ .env.dev 파일 발견"; \
	fi
	$(FLUTTER) pub get
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs
	@echo "✅ 초기화 완료!"

# ============================================
# 🔐 SOPS 복호화 (서브모듈에서 env 파일 가져오기)
# ============================================

# 개발 환경 env 복호화
decrypt-env-dev:
	@echo "======개발 환경 env 복호화 중...======"
	@if [ ! -d "git.environment-variables" ]; then \
		echo "❌ 서브모듈이 없습니다. git submodule update --init --recursive 실행하세요."; \
		exit 1; \
	fi
	sops -d $(ENV_SUBMODULE)/dev.sops.env > .env.dev
	@echo "✅ .env.dev 복호화 완료!"

# 프로덕션 환경 env 복호화
decrypt-env-prod:
	@echo "======프로덕션 환경 env 복호화 중...======"
	@if [ ! -d "git.environment-variables" ]; then \
		echo "❌ 서브모듈이 없습니다. git submodule update --init --recursive 실행하세요."; \
		exit 1; \
	fi
	sops -d $(ENV_SUBMODULE)/prod.sops.env > .env.prod
	@echo "✅ .env.prod 복호화 완료!"

# envied용 .env 파일 준비 (dev 환경)
prepare-env-dev: decrypt-env-dev
	cp .env.dev .env
	@echo "✅ .env 파일 준비 완료 (dev)"

# envied용 .env 파일 준비 (prod 환경)
prepare-env-prod: decrypt-env-prod
	cp .env.prod .env
	@echo "✅ .env 파일 준비 완료 (prod)"

# Android 서명 설정 (.env.prod에서 secrets 폴더 생성)
setup-signing:
	@echo "======Android 서명 설정 중...======"
	@if [ ! -f ".env.prod" ]; then \
		echo "❌ .env.prod 파일이 없습니다."; \
		echo "   cp .env.example .env.prod 로 생성 후 값을 입력하세요."; \
		exit 1; \
	fi
	@# .env.prod에서 값 읽기
	@mkdir -p secrets
	@KEYSTORE_PASSWORD=$$(grep '^KEYSTORE_PASSWORD=' .env.prod | cut -d '=' -f2); \
	KEY_PASSWORD=$$(grep '^KEY_PASSWORD=' .env.prod | cut -d '=' -f2); \
	KEY_ALIAS=$$(grep '^KEY_ALIAS=' .env.prod | cut -d '=' -f2); \
	KEYSTORE_BASE64=$$(grep '^KEYSTORE_BASE64=' .env.prod | cut -d '=' -f2); \
	if [ -z "$$KEYSTORE_PASSWORD" ] || [ -z "$$KEY_PASSWORD" ] || [ -z "$$KEY_ALIAS" ] || [ -z "$$KEYSTORE_BASE64" ]; then \
		echo "❌ .env.prod에 Android Signing 값이 누락되었습니다."; \
		echo "   필요한 값: KEYSTORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS, KEYSTORE_BASE64"; \
		exit 1; \
	fi; \
	echo "storePassword=$$KEYSTORE_PASSWORD" > secrets/key.properties; \
	echo "keyPassword=$$KEY_PASSWORD" >> secrets/key.properties; \
	echo "keyAlias=$$KEY_ALIAS" >> secrets/key.properties; \
	echo "storeFile=upload-keystore.jks" >> secrets/key.properties; \
	echo "$$KEYSTORE_BASE64" | base64 --decode > secrets/upload-keystore.jks; \
	echo "✅ secrets/key.properties 생성 완료"; \
	echo "✅ secrets/upload-keystore.jks 생성 완료"
	@echo "✅ Android 서명 설정 완료!"

# 전체 클린 빌드 (문제 발생시 사용)
fresh:
	@echo "======전체 클린 빌드 시작...======"
	$(FLUTTER) clean
	$(FLUTTER) pub get
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs
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

# 빌드 러너만 실행
codegen:
	@echo "======코드 생성 중...======"
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs
	@echo "✅ 코드 생성 완료!"

# 빌드 러너 watch 모드
codegen-watch:
	@echo "======코드 생성 watch 모드 시작...======"
	$(FLUTTER) pub run build_runner watch --delete-conflicting-outputs

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
# 🔧 환경 빌드
# ============================================

# 개발 환경용 env 파일 빌드
build-env-dev:
	@echo "======개발 환경용 env 파일 빌드 중...======"
	DART_DEFINES="FLAVOR=dev" $(FLUTTER) pub run build_runner build
	@echo "✅ 개발 환경용 env 파일 빌드 완료!"

# 프로덕션 환경용 env 파일 빌드
build-env-prod:
	@echo "======프로덕션 환경용 env 파일 빌드 중...======"
	DART_DEFINES="FLAVOR=prod" $(FLUTTER) pub run build_runner build --delete-conflicting-outputs
	@echo "✅ 프로덕션 환경용 env 파일 빌드 완료!"

# ============================================
# 🔧 내부 헬퍼 (환경 준비)
# ============================================

# 개발 환경 준비 (서브모듈에서 복호화 + codegen)
_ensure-env-dev:
	@if [ ! -f ".env.dev" ]; then \
		echo "⚠️  .env.dev 없음 → 서브모듈에서 복호화..."; \
		$(MAKE) prepare-env-dev; \
	fi
	@if [ ! -f "lib/utils/env/env.g.dart" ]; then \
		echo "⚠️  env.g.dart 없음 → 코드 생성 실행..."; \
		$(FLUTTER) pub get; \
		$(FLUTTER) pub run build_runner build --delete-conflicting-outputs; \
	fi

# 프로덕션 환경 준비 (서브모듈에서 복호화 + secrets 생성 + codegen)
_ensure-env-prod:
	@if [ ! -f ".env.prod" ]; then \
		echo "⚠️  .env.prod 없음 → 서브모듈에서 복호화..."; \
		$(MAKE) prepare-env-prod; \
	fi
	@# secrets 폴더 자동 생성 (GitHub Actions처럼)
	@echo "🔐 secrets 폴더 준비 중..."
	@mkdir -p secrets
	@KEYSTORE_PASSWORD=$$(grep '^KEYSTORE_PASSWORD=' .env.prod | cut -d '=' -f2); \
	KEY_PASSWORD=$$(grep '^KEY_PASSWORD=' .env.prod | cut -d '=' -f2); \
	KEY_ALIAS=$$(grep '^KEY_ALIAS=' .env.prod | cut -d '=' -f2); \
	KEYSTORE_BASE64=$$(grep '^KEYSTORE_BASE64=' .env.prod | cut -d '=' -f2); \
	if [ -n "$$KEYSTORE_PASSWORD" ] && [ -n "$$KEY_PASSWORD" ] && [ -n "$$KEY_ALIAS" ] && [ -n "$$KEYSTORE_BASE64" ]; then \
		echo "storePassword=$$KEYSTORE_PASSWORD" > secrets/key.properties; \
		echo "keyPassword=$$KEY_PASSWORD" >> secrets/key.properties; \
		echo "keyAlias=$$KEY_ALIAS" >> secrets/key.properties; \
		echo "storeFile=upload-keystore.jks" >> secrets/key.properties; \
		echo "$$KEYSTORE_BASE64" | base64 --decode > secrets/upload-keystore.jks 2>/dev/null || true; \
		echo "✅ secrets 폴더 준비 완료"; \
	else \
		echo "⚠️  Android Signing 값 누락 - secrets 생성 스킵 (iOS 빌드는 가능)"; \
	fi
	@if [ ! -f "lib/utils/env/env.g.dart" ]; then \
		echo "⚠️  env.g.dart 없음 → 코드 생성 실행..."; \
		$(FLUTTER) pub get; \
		$(FLUTTER) pub run build_runner build --delete-conflicting-outputs; \
	fi

# ============================================
# 🚀 실행
# ============================================

# 프로덕션 환경 실행
run: _ensure-env-prod
	@echo "======프로덕션 환경 실행중... (FLAVOR=prod)======"
	$(FLUTTER) run --dart-define=FLAVOR=prod

# 개발 환경 실행
run-dev: _ensure-env-dev
	@echo "======개발 환경 실행중... (FLAVOR=dev)======"
	$(FLUTTER) run --dart-define=FLAVOR=dev

# 로컬 웹서버(localhost:3000) 연결 실행
run-local: _ensure-env-dev
	@echo "======로컬 웹서버 연결 실행중... (WebView → localhost:3000)======"
	$(FLUTTER) run --dart-define=FLAVOR=dev --dart-define=USE_LOCAL_WEBVIEW=true

# 프로덕션 환경 실행 (별칭)
run-prod: _ensure-env-prod
	@echo "======프로덕션 환경 실행중... (FLAVOR=prod)======"
	$(FLUTTER) run --dart-define=FLAVOR=prod

# ============================================
# 🔨 빌드
# ============================================

# 개발 환경 빌드 (Android APK)
build-dev-android: _ensure-env-dev
	@echo "======개발 환경 빌드 중 (Android APK)...======"
	$(FLUTTER) build apk --dart-define=FLAVOR=dev
	@echo "✅ 빌드 완료!"

# 프로덕션 환경 빌드 (Android APK)
build-prod-android: _ensure-env-prod
	@echo "======프로덕션 환경 빌드 중 (Android APK)...======"
	$(FLUTTER) build apk --release --dart-define=FLAVOR=prod
	@echo "✅ 빌드 완료!"

# 프로덕션 환경 빌드 (Android AAB - Play Store용)
build-prod-android-aab: _ensure-env-prod
	@echo "======프로덕션 환경 AAB 빌드 중 (Android)...======"
	$(FLUTTER) build appbundle --release --dart-define=FLAVOR=prod
	@echo "✅ AAB 빌드 완료!"

# 개발 환경 빌드 (iOS)
build-dev-ios: _ensure-env-dev
	@echo "======개발 환경 빌드 중 (iOS)...======"
	$(FLUTTER) build ios --dart-define=FLAVOR=dev
	@echo "✅ 빌드 완료!"

# 프로덕션 환경 빌드 (iOS)
build-prod-ios: _ensure-env-prod
	@echo "======프로덕션 환경 빌드 중 (iOS)...======"
	$(FLUTTER) build ios --release --dart-define=FLAVOR=prod
	@echo "✅ 빌드 완료!"

# ============================================
# 🍎 iOS 배포 (Fastlane)
# ============================================

# iOS 배포 도구 설치 (최초 1회)
setup-ios-deploy:
	@echo "======iOS 배포 도구 설치 중...======"
	@which bundle > /dev/null || (echo "❌ Bundler가 없습니다. gem install bundler 실행하세요." && exit 1)
	cd ios && bundle install
	@echo "✅ Fastlane 설치 완료!"

# .env.prod에서 ASC 인증 환경변수 검증 헬퍼
_load-asc-env:
	@if [ ! -f ".env.prod" ]; then \
		echo "❌ .env.prod 파일이 없습니다. make prepare-env-prod 를 먼저 실행하세요."; \
		exit 1; \
	fi
	@ASC_KEY_ID=$$(grep '^ASC_KEY_ID=' .env.prod | cut -d '=' -f2); \
	ASC_ISSUER_ID=$$(grep '^ASC_ISSUER_ID=' .env.prod | cut -d '=' -f2); \
	ASC_KEY_BASE64=$$(grep '^ASC_KEY_BASE64=' .env.prod | cut -d '=' -f2); \
	if [ -z "$$ASC_KEY_ID" ] || [ -z "$$ASC_ISSUER_ID" ] || [ -z "$$ASC_KEY_BASE64" ]; then \
		echo "❌ .env.prod에 App Store Connect API 키 정보가 누락되었습니다."; \
		echo "   필요한 값: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_BASE64"; \
		echo ""; \
		echo "   [설정 방법]"; \
		echo "   1. App Store Connect → 사용자 및 액세스 → 통합 → API 키 생성"; \
		echo "   2. .p8 파일을 base64 인코딩: base64 -i AuthKey_XXXX.p8"; \
		echo "   3. .env.prod에 추가:"; \
		echo "      ASC_KEY_ID=키ID"; \
		echo "      ASC_ISSUER_ID=발급자ID"; \
		echo "      ASC_KEY_BASE64=base64인코딩값"; \
		exit 1; \
	fi

# IPA 빌드 (내부 헬퍼 - Fastfile에서 호출)
_build-ios-ipa: _ensure-env-prod
	@echo "======iOS IPA 빌드 중...======"
	$(FLUTTER) build ipa --release --dart-define=FLAVOR=prod --export-options-plist=ios/ExportOptions.plist 2>/dev/null || \
	$(FLUTTER) build ipa --release --dart-define=FLAVOR=prod
	@echo "✅ IPA 빌드 완료!"

# TestFlight 배포
deploy-ios-testflight: _ensure-env-prod _load-asc-env
	@echo "======iOS TestFlight 배포 중...======"
	@# IPA 빌드
	$(MAKE) _build-ios-ipa
	@# Fastlane 실행 (환경변수 전달: base64 디코딩하여 키 내용 전달)
	@export ASC_KEY_ID=$$(grep '^ASC_KEY_ID=' .env.prod | cut -d '=' -f2); \
	export ASC_ISSUER_ID=$$(grep '^ASC_ISSUER_ID=' .env.prod | cut -d '=' -f2); \
	export ASC_KEY_CONTENT=$$(grep '^ASC_KEY_BASE64=' .env.prod | cut -d '=' -f2 | base64 --decode); \
	export IPA_PATH=$$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1); \
	cd ios && bundle exec fastlane beta
	@echo "✅ TestFlight 배포 완료!"

# TestFlight 배포 (별칭)
deploy-ios: deploy-ios-testflight

# App Store 제출
deploy-ios-appstore: _ensure-env-prod _load-asc-env
	@echo "======iOS App Store 제출 중...======"
	@# IPA 빌드
	$(MAKE) _build-ios-ipa
	@# Fastlane 실행 (환경변수 전달: base64 디코딩하여 키 내용 전달)
	@export ASC_KEY_ID=$$(grep '^ASC_KEY_ID=' .env.prod | cut -d '=' -f2); \
	export ASC_ISSUER_ID=$$(grep '^ASC_ISSUER_ID=' .env.prod | cut -d '=' -f2); \
	export ASC_KEY_CONTENT=$$(grep '^ASC_KEY_BASE64=' .env.prod | cut -d '=' -f2 | base64 --decode); \
	export IPA_PATH=$$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1); \
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
	@echo "  make setup          - 워크스페이스 초기화 (서브모듈 + env 복호화 + 코드 생성)"
	@echo "  make setup-signing  - Android 서명 설정 (.env.prod → secrets/)"
	@echo "  make fresh          - 전체 클린 빌드"
	@echo "  make clean-ios      - iOS 캐시 완전 정리"
	@echo "  make clean-ios-quick - iOS Pod만 재설치"
	@echo "  make clean-android  - Android 캐시 정리"
	@echo "  make codegen        - 빌드 러너 실행"
	@echo "  make codegen-watch  - 빌드 러너 watch 모드"
	@echo ""
	@echo "🔐 환경 변수 (SOPS):"
	@echo "  make decrypt-env-dev  - 개발 환경 env 복호화"
	@echo "  make decrypt-env-prod - 프로덕션 환경 env 복호화"
	@echo "  make prepare-env-dev  - 개발 env 복호화 + .env 복사"
	@echo "  make prepare-env-prod - 프로덕션 env 복호화 + .env 복사"
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
	@echo "  3. .env.prod에 ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_BASE64 추가"
	@echo ""

.PHONY: setup setup-signing fresh clean-ios clean-ios-quick clean-android codegen codegen-watch \
        version bump-build bump-patch bump-minor bump-major \
        decrypt-env-dev decrypt-env-prod prepare-env-dev prepare-env-prod \
        build-env-dev build-env-prod _ensure-env-dev _ensure-env-prod run run-dev run-local run-prod \
        build-dev-android build-prod-android build-prod-android-aab \
        build-dev-ios build-prod-ios \
        setup-ios-deploy _load-asc-env _build-ios-ipa \
        deploy-ios deploy-ios-testflight deploy-ios-appstore help