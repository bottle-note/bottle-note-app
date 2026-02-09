import 'dart:io';

import 'package:app/bridge/handlers/bridge_handler_base.dart';
import 'package:app/permissions/FirebaseConfig.dart';
import 'package:app/utils/env/env.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

  void triggerHaptic(List<dynamic> arguments) async {
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
      } else {
        logger.w(
            'Haptic feedback arguments should be an object with type property');
      }
    } catch (e) {
      logger.e('Error triggering haptic feedback: $e');
    }
  }

  void switchEnvironment(List<dynamic> arguments) async {
    logger.d('switchEnvironment called with arguments: $arguments');
    if (arguments.isNotEmpty && arguments[0] is String) {
      final env = arguments[0] as String;
      String url;
      if (env == 'prod') {
        url = 'https://bottle-note.com/';
      } else if (env == 'dev') {
        url = 'https://development.bottle-note.com/';
      } else {
        url = Env.webViewUrl;
      }
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
  }
}
