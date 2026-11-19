import 'dart:io';

import 'package:app/bridge/handlers/bridge_handler_base.dart';
import 'package:app/permissions/FirebaseConfig.dart';
import 'package:app/utils/env/env.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart'
    show KakaoSdk, TokenManagerProvider;
import 'package:vibration/vibration.dart';

/// 디바이스 토큰, 햅틱, 환경 전환 관련 브릿지 핸들러
mixin DeviceBridgeHandler on BridgeHandlerBase {
  Future<void> sendDeviceToken() async {
    try {
      String? token = await getDeviceToken();

      if (token == null) {
        logger.w("Device token is null");
        return;
      }

      String platformType = Platform.isIOS ? "IOS" : "ANDROID";
      await controller.evaluateJavascript(
        source: "getDeviceToken('$token', '$platformType')",
      );
    } catch (e) {
      logger.e("Error getting device token: $e");
    }
  }

  Future<void> triggerHaptic(List<dynamic> arguments) async {
    if (arguments.isEmpty) {
      logger.w('햅틱 피드백 타입이 전달되지 않았습니다.');
      return;
    }

    try {
      if (arguments[0] is Map) {
        final Map<String, dynamic> hapticArgs =
            Map<String, dynamic>.from(arguments[0]);
        final hapticType = (hapticArgs['type'] as String?)?.toLowerCase();

        if (hapticType == null) {
          logger.w('Haptic feedback type not specified in arguments');
          return;
        }

        if (Platform.isAndroid &&
            await Vibration.hasAmplitudeControl() == true) {
          // Android: Vibration API로 amplitude 직접 제어
          // amplitude 기준: expo-haptics 프로덕션 값 + Android 공식 디자인 가이드
          // 레벨 간 최소 1.4배 차이 유지 (Android Haptics Design Principles)
          switch (hapticType) {
            case 'light':
              await Vibration.vibrate(duration: 50, amplitude: 30);
              break;
            case 'medium':
              await Vibration.vibrate(duration: 43, amplitude: 50);
              break;
            case 'heavy':
              await Vibration.vibrate(duration: 60, amplitude: 70);
              break;
            case 'selection':
              await Vibration.vibrate(duration: 20, amplitude: 20);
              break;
            case 'vibrate':
              await Vibration.vibrate(duration: 500, amplitude: 128);
              break;
            default:
              logger.w('Unknown haptic feedback type: $hapticType');
          }
        } else {
          // iOS 또는 amplitude 미지원 Android: Flutter 기본 API 사용
          switch (hapticType) {
            case 'light':
              await HapticFeedback.lightImpact();
              break;
            case 'medium':
              await HapticFeedback.mediumImpact();
              break;
            case 'heavy':
              await HapticFeedback.heavyImpact();
              break;
            case 'selection':
              await HapticFeedback.selectionClick();
              break;
            case 'vibrate':
              await HapticFeedback.vibrate();
              break;
            default:
              logger.w('Unknown haptic feedback type: $hapticType');
          }
        }
      } else {
        logger.w(
            'Haptic feedback arguments should be an object with type property');
      }
    } catch (e) {
      logger.e('Error triggering haptic feedback: $e');
    }
  }

  Future<void> switchEnvironment(List<dynamic> arguments) async {
    logger.d('switchEnvironment called with arguments: $arguments');
    if (arguments.isNotEmpty && arguments[0] is String) {
      final target = Env.switchTarget(arguments[0] as String);
      // 카카오 토큰은 발급한 카카오 앱의 서버에서만 통과하므로, 웹과 같은 환경의 키로 바꾼다.
      KakaoSdk.init(nativeAppKey: target.kakaoNativeAppKey);
      try {
        await TokenManagerProvider.instance.manager.clear();
      } catch (e) {
        logger.w('카카오 토큰 정리 실패: $e');
      }
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(target.url)));
    }
  }
}
