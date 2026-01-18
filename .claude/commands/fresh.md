# 전체 클린 빌드

프로젝트를 처음부터 다시 빌드합니다. 다음 작업을 순서대로 실행해주세요:

1. `flutter clean` - 기존 빌드 캐시 삭제
2. `flutter pub get` - 의존성 재설치
3. `dart run build_runner build --delete-conflicting-outputs` - 코드 생성

각 단계의 결과를 확인하고, 오류가 있으면 원인을 분석해서 알려주세요.
