import 'dart:convert';

import 'package:app/bridge/handlers/bridge_handler_base.dart';
import 'package:app/bridge/social_login_handler.dart';

/// 소셜 로그인 관련 브릿지 핸들러
mixin AuthBridgeHandler on BridgeHandlerBase {
  Future<void> handleKakaoLogin() async {
    try {
      onShowLoading?.call('카카오 로그인 중...');
      KakaoLoginResult? kakaoLoginResult = await loginWithKakao();

      if (kakaoLoginResult == null) {
        return;
      }

      await controller.evaluateJavascript(
        source: "onKakaoLoginSuccess('${kakaoLoginResult.accessToken}')",
      );
    } catch (error) {
      try {
        await controller.evaluateJavascript(
          source: "onKakaoLoginError('$error')",
        );
      } catch (_) {}
    } finally {
      onHideLoading?.call();
    }
  }

  Future<void> handleAppleLogin(List<dynamic> arguments) async {
    try {
      onShowLoading?.call('애플 로그인 중...');

      String nonce = arguments[0]['nonce'];
      AppleLoginResult? appleLoginResult = await loginWithApple(nonce);

      if (appleLoginResult == null) {
        return;
      }

      final json = jsonEncode({
        'idToken': appleLoginResult.idToken,
        'nonce': nonce,
      });

      logger.d('appleLoginResult: ${appleLoginResult.idToken}, $nonce');

      await controller.evaluateJavascript(
        source: "onAppleLoginSuccess('$json')",
      );
    } catch (error) {
      try {
        await controller.evaluateJavascript(
          source: "onAppleLoginError('$error')",
        );
      } catch (_) {}
    } finally {
      onHideLoading?.call();
    }
  }
}
