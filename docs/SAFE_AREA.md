# 앱과 웹의 safe area 규약 (HYE-95)

앱의 WebView는 iOS와 Android 모두 시스템 바 뒤까지 그린다. 배경과 사진은 화면 끝까지 이어지고, 버튼과 글자의 여백은 웹이 결정한다. 앱은 웹 CSS를 주입하거나 WebView 바깥에 시스템 바 높이만큼 여백을 추가하지 않는다. 네이티브 오프라인 화면은 Flutter `SafeArea`를 쓴다.

## 앱이 전달하는 값

페이지 시작 스크립트(`AT_DOCUMENT_START`)가 아래 값을 설정한다. `BottleNoteApp`의 다른 필드는 유지한다.

```js
window.BottleNoteApp.safeArea = { top: 54.1, bottom: 48 };
window.dispatchEvent(new Event('bottlenote:safearea'));
```

- 단위는 CSS px이다. Flutter `view.padding`을 `devicePixelRatio`로 나눈다.
- `padding`은 키보드에 가려지는 하단 여백을 0으로 만든다. 키보드 높이(`viewInsets`)를 safe area에 더하지 않는다.
- 회전, 내비게이션 방식 변경, 화면 크기 변경, 앱 복귀 시 현재 값을 다시 확인한다.
- 변경은 순서대로 전달하고, 이후 페이지에도 최신 값이 주입되도록 시작 스크립트를 교체한다.
- 페이지 로드가 끝나면 값을 다시 전달한다. 오래된 WebView에서 document-start 실행 시점이 보장되지 않는 경우에도 웹의 이벤트 수신기가 값을 받도록 한다.

## 웹이 담당하는 처리

웹은 첫 화면에서 현재 값을 읽고 `bottlenote:safearea` 이벤트마다 CSS 변수를 갱신한다.

```css
--safe-area-top: max(env(safe-area-inset-top, 0px), var(--app-safe-area-top, 0px));
--safe-area-bottom: max(env(safe-area-inset-bottom, 0px), var(--app-safe-area-bottom, 0px));
```

`env()`가 0인 WebView는 앱 값을 사용한다. 정상 값을 주는 WebView에서는 두 값을 더하지 않고 큰 값만 사용한다. UA의 WebView 버전 번호로 분기하지 않는다.

구버전 Android 앱이 주입하는 `#bottle-note-native-safe-area`가 있으면 웹이 두 여백을 0으로 처리해야 한다. 이 앱은 이미 네이티브 여백을 확보한다. 구버전 iOS와 모바일 브라우저는 기존 `env()` 동작을 유지한다.

## 배포 순서

1. 웹의 값 수신 및 구버전 Android 호환 처리를 먼저 배포한다.
2. 구버전 앱에서 이중 여백이 없어졌는지 확인한다.
3. 새 앱을 기존 출시 예정 버전 **1.0.9**에 포함한다. `release:build` 머지 시 CI가 현재 `+40`에서 빌드 번호만 올린다.

웹보다 먼저 새 앱을 출시하면 `env()`가 0인 기기에서 헤더와 하단 버튼이 시스템 바에 가려진다.

## 검증 기준

| 환경/전환 | 확인할 내용 |
| --- | --- |
| Android WebView 140 | `env()`가 0이어도 앱 값으로 상하단 내용이 보호됨 |
| 최신 Android WebView 실기기 | `env()`와 앱 값을 합산하지 않음 |
| 제스처 ↔ 3버튼 내비게이션 | 하단 값 갱신 및 다음 페이지 시작 값 유지 |
| 키보드 열기 ↔ 닫기 | 하단 값이 0으로 바뀌고 원래 값으로 복귀 |
| 회전·화면 크기 변경 | 현재 페이지와 다음 페이지가 같은 최신 값을 사용 |
| iOS | 기존 `env()` 기반 화면 및 상태바·홈 인디케이터 배경 유지 |
| 오프라인 첫 실행 | 네이티브 메시지와 재시도 버튼이 시스템 바에 가려지지 않음 |

Android 수동 확인은 홈, 전체 화면, 하단 고정 버튼, 입력 화면과 새로고침 표시를 포함한다. 앱과 웹 통합 검증은 실제 웹 변경을 적용한 환경에서 수행한다.
