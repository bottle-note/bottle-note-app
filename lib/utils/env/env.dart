import 'dart:io' show Platform;
import 'package:envied/envied.dart';
part 'env.g.dart';

const String flavor = String.fromEnvironment(
  'FLAVOR',
  defaultValue: 'dev',
);

/// 카카오 네이티브 앱 키. config/flavors/<dev|prod>.json에서 주입된다.
/// (개발: Bottle Note-TEST 앱, 운영: Bottle Note 앱)
const String kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

/// 로컬 웹서버(localhost:3000)에 연결할지 여부
const bool useLocalWebView = bool.fromEnvironment(
  'USE_LOCAL_WEBVIEW',
  defaultValue: false,
);

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'FIREBASE_ANDROID_API_KEY')
  static final String firebaseAndroidApiKey = _Env.firebaseAndroidApiKey;

  @EnviedField(varName: 'FIREBASE_IOS_API_KEY')
  static final String firebaseIosApiKey = _Env.firebaseIosApiKey;

  /// FLAVOR와 USE_LOCAL_WEBVIEW에 따라 자동으로 URL 결정
  static String get webViewUrl {
    if (useLocalWebView) {
      // Android 에뮬레이터는 10.0.2.2, iOS 시뮬레이터는 localhost
      return Platform.isAndroid
          ? 'http://10.0.2.2:3000/'
          : 'http://localhost:3000/';
    }
    return switch (flavor) {
      'prod' => 'https://bottle-note.com/',
      _ => 'https://development.bottle-note.com/',
    };
  }
}
