# iOS 캐시 완전 정리

iOS 빌드 문제 해결을 위해 캐시를 완전히 정리합니다. 다음 작업을 순서대로 실행해주세요:

1. `cd ios && rm -rf Pods Podfile.lock .symlinks` - Pod 관련 파일 삭제
2. `cd ios && pod cache clean --all` - Pod 캐시 정리
3. `flutter clean` - Flutter 캐시 정리
4. `flutter pub get` - 의존성 재설치
5. `cd ios && pod install` - Pod 재설치

각 단계의 결과를 확인하고, 오류가 있으면 원인을 분석해서 알려주세요.
