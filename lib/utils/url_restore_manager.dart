import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

/// Android에서 카메라 호출 후 앱이 kill되었을 때 URL을 복원하기 위한 매니저
class UrlRestoreManager {
  static const String _pendingUrlKey = 'pending_restore_url';
  static const String _timestampKey = 'pending_restore_timestamp';

  /// URL 복원 유효 시간 (5분)
  static const int _validDurationMinutes = 5;

  /// 카메라 호출 전 현재 URL 저장 (Android 전용)
  static Future<void> saveUrlBeforeCamera(String url) async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingUrlKey, url);
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 저장된 URL 가져오기 및 삭제 (Android 전용)
  /// 유효 시간이 지났거나 URL이 없으면 null 반환
  static Future<String?> consumeRestoredUrl() async {
    if (!Platform.isAndroid) return null;

    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_pendingUrlKey);
    final savedTimestamp = prefs.getInt(_timestampKey);

    // 저장된 URL이 없으면 null
    if (savedUrl == null || savedTimestamp == null) {
      return null;
    }

    // 유효 시간 체크 (5분 초과시 무효)
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - savedTimestamp;
    if (elapsed > _validDurationMinutes * 60 * 1000) {
      // 만료된 데이터도 정리
      await clearSavedUrl();
      return null;
    }

    // 정상적으로 복원된 경우 사용 후 삭제
    await clearSavedUrl();
    return savedUrl;
  }

  /// 저장된 URL 삭제 (정상 카메라 복귀 시 호출)
  static Future<void> clearSavedUrl() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingUrlKey);
    await prefs.remove(_timestampKey);
  }
}
