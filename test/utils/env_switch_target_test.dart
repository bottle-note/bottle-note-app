import 'package:app/utils/env/env.dart';
import 'package:flutter_test/flutter_test.dart';

// flutter test --dart-define=FLAVOR=prod --dart-define=KAKAO_NATIVE_APP_KEY=prod-key
//   --dart-define=KAKAO_NATIVE_APP_KEY_DEV=dev-key --dart-define=KAKAO_NATIVE_APP_KEY_PROD=prod-key
void main() {
  group('Env.switchTarget', () {
    test('dev로 전환하면 개발 웹과 TEST 카카오 키를 쓴다', () {
      final target = Env.switchTarget('dev');
      expect(target.url, 'https://development.bottle-note.com/');
      expect(target.kakaoNativeAppKey, Env.kakaoNativeAppKeyDev);
    });

    test('prod로 전환하면 운영 웹과 운영 카카오 키를 쓴다', () {
      final target = Env.switchTarget('prod');
      expect(target.url, 'https://bottle-note.com/');
      expect(target.kakaoNativeAppKey, Env.kakaoNativeAppKeyProd);
    });

    test('알 수 없는 값은 빌드 기본 환경으로 되돌린다', () {
      final target = Env.switchTarget('unknown');
      expect(target.url, Env.webViewUrl);
      expect(target.kakaoNativeAppKey, Env.kakaoNativeAppKey);
    });

    test('dev와 prod 키가 서로 다르게 주입된다', () {
      expect(Env.kakaoNativeAppKeyDev, isNotEmpty);
      expect(Env.kakaoNativeAppKeyProd, isNotEmpty);
      expect(Env.kakaoNativeAppKeyDev, isNot(Env.kakaoNativeAppKeyProd));
    });
  });
}
