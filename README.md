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

### Android (GitHub Actions 자동화)

PR을 `main` 브랜치에 머지할 때 라벨을 붙이면 자동으로 버전 bump + AAB 빌드가 실행됩니다.

| 라벨 | 버전 변경 | 예시 |
|------|----------|------|
| `release:build` | 빌드 번호만 +1 | 1.0.6+30 → 1.0.6+31 |
| `release:patch` | 패치 버전 +1 | 1.0.6 → 1.0.7 |
| `release:minor` | 마이너 버전 +1 | 1.0.6 → 1.1.0 |
| `release:major` | 메이저 버전 +1 | 1.0.6 → 2.0.0 |

**워크플로우 흐름:**
1. Feature 브랜치에서 작업 완료
2. PR 생성 → `release:*` 라벨 추가
3. PR 머지 → GitHub Actions가 자동으로:
   - 버전 bump & 커밋
   - AAB 빌드
   - Artifacts에 업로드

**수동 실행 (긴급 재빌드):**
GitHub Actions → `Android Release` → `Run workflow` 에서 직접 실행 가능

**빌드 결과물:**
GitHub Actions 실행 결과 → Artifacts에서 AAB 다운로드

### iOS (수동)

```bash
# 1. 버전 확인
make version

# 2. 빌드
make build-prod-ios

# 3. Xcode에서 Archive & 업로드
open ios/Runner.xcworkspace
```

### 로컬 빌드 (테스트용)

```bash
# Android APK (테스트 배포용)
make build-prod-android

# Android AAB (스토어 업로드용)
make build-prod-android-aab
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

### cider (버전 관리 - 선택)

로컬에서 수동 버전 관리 시에만 필요합니다. GitHub Actions 자동화를 사용한다면 불필요.

```bash
dart pub global activate cider
```

PATH 설정 필요시:
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## 환경 설정

### 자동 설정 (권장)

`make setup`이 모든 환경 설정을 자동으로 처리합니다:

```bash
make setup
```

> ⚠️ 환경변수 설정이 필요합니다. 처음 셋업 시 팀원에게 요청하세요.

### 수동 환경 전환

```bash
# 개발 → 프로덕션 전환
make prepare-env-prod

# 프로덕션 → 개발 전환
make prepare-env-dev
```

### Android 서명 (로컬 프로덕션 빌드용)

프로덕션 빌드 명령어 실행 시 자동으로 secrets 폴더가 생성됩니다:

```bash
make build-prod-android  # 자동으로 secrets 생성
```

수동으로 생성하려면:
```bash
make setup-signing
```

![Group 236 (3)](https://github.com/bottle-note/.github/assets/97773895/bd41fdbb-f8c6-496d-87df-536b0b85ab89)
