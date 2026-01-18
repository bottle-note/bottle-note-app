![Group 236 (3)](https://github.com/bottle-note/.github/assets/97773895/bd41fdbb-f8c6-496d-87df-536b0b85ab89)

# bottle_note_official_app

보틀노트 프로젝트 공식 앱입니다.

## 빠른 시작

```bash
# 워크스페이스 초기화 (의존성 설치 + 코드 생성)
make setup

# 앱 실행
make run-dev
```

전체 명령어 목록: `make help`

## Make 명령어

### 초기 설정 & 클린업

| 명령어 | 설명 |
|--------|------|
| `make setup` | 워크스페이스 초기화 (pub get + 코드 생성) |
| `make setup-signing` | Android 서명 설정 (.env.prod → secrets/) |
| `make fresh` | 전체 클린 빌드 |
| `make clean-ios` | iOS 캐시 완전 정리 |
| `make clean-ios-quick` | iOS Pod만 재설치 |
| `make clean-android` | Android 캐시 정리 |
| `make codegen` | build_runner 실행 |
| `make codegen-watch` | build_runner watch 모드 |

### 버전 관리

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `make version` | 현재 버전 확인 | - |
| `make bump-build` | 빌드 번호만 +1 | 1.0.5+23 → 1.0.5+24 |
| `make bump-patch` | 패치 버전 +1 | 1.0.5 → 1.0.6 |
| `make bump-minor` | 마이너 버전 +1 | 1.0.5 → 1.1.0 |
| `make bump-major` | 메이저 버전 +1 | 1.0.5 → 2.0.0 |

### 앱 실행

| 명령어 | 환경 | 설명 |
|--------|------|------|
| `make run` | 프로덕션 | 프로덕션 환경 실행 (FLAVOR=prod) |
| `make run-dev` | 개발 | 개발 환경 실행 (FLAVOR=dev) |
| `make run-local` | 로컬 | 로컬 웹서버 연결 (localhost:3000) |
| `make run-prod` | 프로덕션 | 프로덕션 환경 실행 (별칭) |

### 빌드

| 명령어 | 플랫폼 | 환경 |
|--------|--------|------|
| `make build-dev-android` | Android APK | 개발 |
| `make build-prod-android` | Android APK | 프로덕션 |
| `make build-prod-android-aab` | Android AAB | 프로덕션 |
| `make build-dev-ios` | iOS | 개발 |
| `make build-prod-ios` | iOS | 프로덕션 |

## 릴리즈 워크플로우

```bash
# 1. 버전 확인
make version

# 2. 빌드 번호 올리기
make bump-build

# 3. 빌드
make build-prod-ios
make build-prod-android-aab

# 4. Xcode에서 Archive & 업로드
open ios/Runner.xcworkspace
```

## 트러블슈팅

### iOS Pods 충돌

```bash
make clean-ios
```

### build_runner 충돌

```bash
make codegen
```

### 의존성 꼬임

```bash
make fresh
```

## 필수 도구 설치

### FVM (Flutter Version Manager)

```bash
brew install fvm
fvm use 3.32.8
```

### cider (버전 관리)

```bash
dart pub global activate cider
```

PATH 설정 필요시:
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## 환경 설정

### .env 파일 생성

```bash
# 개발 환경
cp .env.example .env.dev

# 프로덕션 환경
cp .env.example .env.prod
```

### Android 서명 설정 (프로덕션 빌드용)

`.env.prod`에 아래 값을 설정한 후:
```
KEYSTORE_PASSWORD=your_password
KEY_PASSWORD=your_password
KEY_ALIAS=your_alias
KEYSTORE_BASE64=base64_encoded_keystore
```

서명 파일 생성:
```bash
make setup-signing
```

![Group 236 (3)](https://github.com/bottle-note/.github/assets/97773895/bd41fdbb-f8c6-496d-87df-536b0b85ab89)
