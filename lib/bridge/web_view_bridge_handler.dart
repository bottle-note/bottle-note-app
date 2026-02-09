import 'dart:io';

import 'package:app/bridge/bridge_setup_script.dart';
import 'package:app/bridge/handlers/bridge_handler_base.dart';
import 'package:app/bridge/handlers/auth_bridge_handler.dart';
import 'package:app/bridge/handlers/device_bridge_handler.dart';
import 'package:app/bridge/handlers/media_bridge_handler.dart';
import 'package:app/bridge/handlers/share_bridge_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logger/logger.dart';

class WebViewBridgeHandler extends BridgeHandlerBase
    with
        MediaBridgeHandler,
        AuthBridgeHandler,
        ShareBridgeHandler,
        DeviceBridgeHandler {
  @override
  final BuildContext context;
  @override
  final InAppWebViewController controller;
  @override
  final Logger logger;

  final MethodChannel platform =
      const MethodChannel('com.bottlenote.official.app/intents');

  @override
  final Function(String)? onShowLoading;
  @override
  final VoidCallback? onHideLoading;

  bool _handlersRegistered = false;

  WebViewBridgeHandler({
    required this.controller,
    required this.logger,
    required this.context,
    this.onShowLoading,
    this.onHideLoading,
  });

  Future<void> setupJavaScriptChannels() async {
    if (!_handlersRegistered) {
      // Legacy FlutterMessageQueue (구버전 웹 호환)
      controller.addJavaScriptHandler(
        handlerName: 'FlutterMessageQueue',
        callback: (args) {
          if (args.isEmpty) {
            logger.w('Received empty message from JS');
            return;
          }

          final message = args[0].toString();
          final arguments = args.length > 1 ? args.sublist(1) : [];
          logger.d(
              'Received message from JS: $message, arguments: $arguments');
          _handleFlutterMessageQueue(message, arguments);
        },
      );

      controller.addJavaScriptHandler(
        handlerName: 'LogToFlutter',
        callback: (args) {
          if (args.isNotEmpty) {
            logger.d("[Log from In App] ${args[0]}");
          }
        },
      );

      // 개별 채널 핸들러 등록
      _registerIndividualChannels();

      _handlersRegistered = true;
    }

    await setupWebViewJavaScriptChannels();
  }

  /// 웹 페이지에 JavaScript 채널 객체를 정의하는 메서드
  Future<void> setupWebViewJavaScriptChannels() async {
    await controller.evaluateJavascript(source: BridgeSetupScript.script);
  }

  /// 개별 채널 핸들러를 등록하는 헬퍼
  void _registerChannel(
    String name,
    Future<dynamic> Function(List<dynamic>) handler,
  ) {
    controller.addJavaScriptHandler(
      handlerName: name,
      callback: (args) async {
        try {
          logger.d('Channel $name called with args: $args');
          final result = await handler(args);
          if (result is Map) return result;
          return {'success': true};
        } catch (e) {
          logger.e('Error in channel $name: $e');
          return {'error': e.toString()};
        }
      },
    );
  }

  /// 각 기능별 개별 채널 핸들러 등록
  void _registerIndividualChannels() {
    _registerChannel('AppBridge.deviceToken', (_) => sendDeviceToken());

    _registerChannel('AppBridge.platform', (_) async {
      final platform = Platform.operatingSystem;
      await controller.evaluateJavascript(
        source: "checkPlatform('$platform')",
      );
      return {'platform': platform};
    });

    _registerChannel('AppBridge.album', (_) => pickImgFromAlbum());

    _registerChannel(
        'AppBridge.albumMultiple', (_) => pickMultipleImgsFromAlbum());

    _registerChannel('AppBridge.camera', (_) => pickImgFromCamera());

    _registerChannel('AppBridge.kakaoLogin', (_) => handleKakaoLogin());

    _registerChannel(
        'AppBridge.appleLogin', (args) => handleAppleLogin(args));

    _registerChannel('AppBridge.haptic', (args) async {
      triggerHaptic(args);
    });

    _registerChannel('AppBridge.env', (args) async {
      switchEnvironment(args);
    });

    _registerChannel('AppBridge.share', (args) => handleShare(args));
  }

  /// Legacy FlutterMessageQueue 메시지 라우팅 (구버전 웹 호환)
  void _handleFlutterMessageQueue(String message, List<dynamic> arguments) {
    switch (message) {
      case 'deviceToken':
        sendDeviceToken();
        break;
      case 'checkPlatform':
        logger.d('checkPlatform called');
        logger.d('Platform: ${Platform.operatingSystem}');
        controller.evaluateJavascript(
          source: "checkPlatform('${Platform.operatingSystem}')",
        );
        break;
      case 'openAlbum':
        logger.d('openAlbum called with arguments: $arguments');
        pickImgFromAlbum();
        break;
      case 'openAlbumMultiple':
        logger.d('openAlbumMultiple called with arguments: $arguments');
        pickMultipleImgsFromAlbum();
        break;
      case 'openCamera':
        logger.d('openCamera called with arguments: $arguments');
        pickImgFromCamera();
        break;
      case 'loginWithKakao':
        logger.d('loginWithKakao called with arguments: $arguments');
        handleKakaoLogin();
        break;
      case 'loginWithApple':
        logger.d('loginWithApple called with arguments: $arguments');
        handleAppleLogin(arguments);
        break;
      case 'triggerHaptic':
        logger.d('triggerHaptic called with arguments: $arguments');
        triggerHaptic(arguments);
        break;
      case 'switchEnv':
        logger.d('switchEnvironment called with arguments: $arguments');
        switchEnvironment(arguments);
        break;
      case 'share':
        logger.d('share called with arguments: $arguments');
        handleShare(arguments);
        break;
      default:
        logger
            .w("Unknown message received: $message with arguments: $arguments");
    }
  }
}
