import 'dart:io' show Platform;

/// 앱 환경 값. scripts/run.sh가 환경별 env 파일
/// (.env.development / .env.production)을 --dart-define-from-file로 넘긴다.
abstract class Env {
  /// dev | prod
  static const String flavor = String.fromEnvironment('FLAVOR');

  static const String kakaoNativeAppKey =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

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
}
