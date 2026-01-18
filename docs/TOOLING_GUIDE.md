# Bottle Note Flutter 개발 도구 가이드

이 문서는 프로젝트에서 사용하는 개발 도구들의 설정 및 사용법을 설명합니다.

## 목차
1. [FVM (Flutter Version Management)](#1-fvm-flutter-version-management)
2. [Codemagic CI/CD](#2-codemagic-cicd)
3. [Firebase Studio](#3-firebase-studio)

---

## 1. FVM (Flutter Version Management)

FVM은 프로젝트별로 Flutter 버전을 관리하는 도구입니다.

### 설치

```bash
# Homebrew로 설치 (macOS)
brew tap leoafarias/fvm
brew install fvm
```

### 프로젝트 설정

```bash
# 프로젝트 디렉토리에서 실행
fvm use 3.32.8
```

프로젝트 루트에 `.fvmrc` 파일이 생성됩니다:
```json
{
  "flutter": "3.32.8"
}
```

### 사용법

FVM을 통해 Flutter 명령어를 실행합니다:

```bash
# 기존
flutter pub get

# FVM 사용
fvm flutter pub get
```

Makefile의 모든 명령어가 FVM을 사용하도록 설정되어 있습니다:
```bash
make setup      # 프로젝트 초기화
make run-dev    # 개발 환경 실행
make build-prod-android  # 프로덕션 APK 빌드
```

### IDE 설정

**VS Code:**
`.vscode/settings.json`에 추가:
```json
{
  "dart.flutterSdkPath": ".fvm/versions/3.32.8"
}
```

**Android Studio:**
Settings > Languages & Frameworks > Flutter > Flutter SDK path:
```
/Users/[username]/fvm/versions/3.32.8
```

---

## 2. Codemagic CI/CD

Codemagic은 Flutter 전용 CI/CD 플랫폼입니다.

### 초기 설정

1. [Codemagic](https://codemagic.io) 가입
2. GitHub 저장소 연결
3. `codemagic.yaml` 자동 인식됨

### 환경 변수 설정 (Codemagic Dashboard)

**1. 앱 인증 정보 그룹 (`app_credentials`):**
- `KAKAO_NATIVE_KEY` - 카카오 네이티브 앱 키
- `KAKAO_JS_KEY` - 카카오 JavaScript 키

**2. Android 서명 (`bottle_note_keystore`):**
- Keystore 파일 업로드
- `CM_KEYSTORE_PASSWORD` - 키스토어 비밀번호
- `CM_KEY_PASSWORD` - 키 비밀번호
- `CM_KEY_ALIAS` - 키 별칭

**3. iOS 코드 사이닝:**
- Apple Developer 계정 연결
- 인증서 및 프로비저닝 프로파일 자동 관리

### 워크플로우

| 워크플로우 | 트리거 | 설명 |
|-----------|--------|------|
| `android-build` | main, develop push | APK/AAB 빌드 |
| `ios-build` | main, develop push | IPA 빌드 |
| `pr-check` | PR 생성 | 코드 분석 + 빌드 검증 |

### 로컬에서 검증

```bash
# codemagic.yaml 문법 검사
pip install codemagic-cli-tools
codemagic-yaml-validator codemagic.yaml
```

### 수동 빌드 트리거

Codemagic Dashboard에서:
1. 프로젝트 선택
2. "Start new build" 클릭
3. 브랜치 및 워크플로우 선택

---

## 3. Firebase Studio

Firebase Studio는 Firebase 프로젝트를 관리하는 웹 기반 IDE입니다.

### 접속

[Firebase Studio](https://firebase.studio) 접속 후 Google 계정으로 로그인

### 프로젝트 연결

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# 로그인
firebase login

# 프로젝트 목록 확인
firebase projects:list
```

### 현재 Firebase 설정

프로젝트 ID: `official-bottlenote`

**Android:**
- App ID: `1:521955856728:android:fd11527374003dd7a6552d`
- 설정 파일: `android/app/google-services.json`

**iOS:**
- App ID: `1:521955856728:ios:07dfad642adae4d6a6552d`
- 설정 파일: `ios/Runner/GoogleService-Info.plist`

### 사용 중인 Firebase 서비스

- **Firebase Cloud Messaging (FCM)** - 푸시 알림
- **Firebase Core** - 기본 SDK

### 향후 추가 가능한 서비스

| 서비스 | 용도 |
|--------|------|
| Crashlytics | 앱 크래시 모니터링 |
| Analytics | 사용자 행동 분석 |
| Remote Config | 앱 설정 원격 변경 |
| Performance | 앱 성능 모니터링 |

### Crashlytics 활성화 (선택)

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 설정 재구성 (Crashlytics 포함)
flutterfire configure --project=official-bottlenote
```

`pubspec.yaml`에 추가:
```yaml
dependencies:
  firebase_crashlytics: ^4.0.0
```

---

## 환경별 빌드

### 개발 환경 (Development)
```bash
make run-dev
# 웹뷰 URL: https://development.bottle-note.com/
```

### 프로덕션 환경 (Production)
```bash
make run-prod
# 웹뷰 URL: https://bottle-note.com/
```

### 로컬 환경 (Local)
```bash
make run-dev-local
# 웹뷰 URL: http://192.168.45.148:3000/
```

---

## 버전 관리

Cider를 사용한 버전 관리:

```bash
make version      # 현재 버전 확인
make bump-build   # 빌드 번호 +1 (1.0.5+23 → 1.0.5+24)
make bump-patch   # 패치 버전 +1 (1.0.5 → 1.0.6)
make bump-minor   # 마이너 버전 +1 (1.0.5 → 1.1.0)
make bump-major   # 메이저 버전 +1 (1.0.5 → 2.0.0)
```

---

## 문제 해결

### FVM이 인식되지 않을 때
```bash
# FVM 재설치
brew reinstall fvm

# 버전 재설정
fvm use 3.32.8 --force
```

### 빌드 캐시 문제
```bash
make fresh        # 전체 클린 빌드
make clean-ios    # iOS 캐시 정리
make clean-android # Android 캐시 정리
```

### Codemagic 빌드 실패
1. Dashboard에서 로그 확인
2. 환경 변수 설정 확인
3. 서명 설정 확인

---

## 참고 자료

- [FVM 공식 문서](https://fvm.app/)
- [Codemagic 문서](https://docs.codemagic.io/)
- [Firebase 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
