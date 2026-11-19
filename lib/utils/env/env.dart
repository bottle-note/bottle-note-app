import 'dart:io' show Platform;

/// 앱 환경 값. scripts/run.sh가 환경별 env 파일
/// (.env.development / .env.production)을 --dart-define-from-file로 넘긴다.
abstract class Env {
  /// dev | prod
  static const String flavor = String.fromEnvironment('FLAVOR');

  /// 빌드 환경(FLAVOR)의 카카오 네이티브 앱 키. 앱 시작 시 SDK 초기화에 쓴다.
  static const String kakaoNativeAppKey =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

  /// 앱 안에서 웹 환경을 전환할 때 쓰는 환경별 카카오 키.
  /// 서버는 토큰을 발급한 카카오 앱(app_id)을 확인하므로, 웹 환경과 키가 맞아야 한다.
  static const String kakaoNativeAppKeyDev =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY_DEV');

  static const String kakaoNativeAppKeyProd =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY_PROD');

  static const String firebaseAndroidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');

  static const String firebaseIosApiKey =
      String.fromEnvironment('FIREBASE_IOS_API_KEY');

  /// 로컬 웹서버(localhost:3000)에 연결할지 여부
  static const bool useLocalWebView = bool.fromEnvironment('USE_LOCAL_WEBVIEW');

  /// env 파일 없이 실행하면 잘못된 환경 값으로 조용히 도는 대신 바로 실패한다.
  static void ensureLoaded() {
    final missing = {
      'FLAVOR': flavor,
      'KAKAO_NATIVE_APP_KEY': kakaoNativeAppKey,
      'KAKAO_NATIVE_APP_KEY_DEV': kakaoNativeAppKeyDev,
      'KAKAO_NATIVE_APP_KEY_PROD': kakaoNativeAppKeyProd,
      'FIREBASE_ANDROID_API_KEY': firebaseAndroidApiKey,
      'FIREBASE_IOS_API_KEY': firebaseIosApiKey,
    }.entries.where((e) => e.value.isEmpty).map((e) => e.key).toList();
    if (missing.isNotEmpty) {
      throw StateError(
        '환경 값 누락: ${missing.join(', ')}. '
        'scripts/run.sh <cmd> <dev|prod>(또는 make run-dev)로 실행하세요.',
      );
    }
  }

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

  /// 웹 환경 전환('dev' | 'prod')에 맞는 웹 URL과 카카오 키.
  /// 그 밖의 값은 빌드 기본 환경으로 되돌린다.
  /// 환경마다 다른 값이 더 생기면 여기에 함께 넣어 웹 URL과 같이 바뀌게 한다.
  static ({String url, String kakaoNativeAppKey}) switchTarget(String env) =>
      switch (env) {
        'prod' => (
            url: 'https://bottle-note.com/',
            kakaoNativeAppKey: kakaoNativeAppKeyProd,
          ),
        'dev' => (
            url: 'https://development.bottle-note.com/',
            kakaoNativeAppKey: kakaoNativeAppKeyDev,
          ),
        _ => (url: webViewUrl, kakaoNativeAppKey: kakaoNativeAppKey),
      };
}
