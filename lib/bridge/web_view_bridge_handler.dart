import 'dart:convert';
import 'dart:io';
import 'package:app/bridge/social_login_handler.dart';
import 'package:app/main.dart';
import 'package:app/permissions/FirebaseConfig.dart';
import 'package:app/utils/env/env.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:app/utils/url_restore_manager.dart';

class WebViewBridgeHandler {
  final BuildContext context;
  final InAppWebViewController controller;
  final Logger logger;
  final MethodChannel platform =
      const MethodChannel('com.bottlenote.official.app/intents');

  final Function(String)? onShowLoading;
  final VoidCallback? onHideLoading;
  bool _handlersRegistered = false;

  static const String bridgeSetupScript = """
    if (typeof window.FlutterMessageQueue === 'undefined') {
      window.FlutterMessageQueue = {
        postMessage: function(message, ...args) {
          window.flutter_inappwebview.callHandler('FlutterMessageQueue', message, ...args);
        }
      };
    }

    if (typeof window.LogToFlutter === 'undefined') {
      window.LogToFlutter = {
        postMessage: function(message) {
          window.flutter_inappwebview.callHandler('LogToFlutter', message);
        }
      };
    }

    if (typeof window.isInApp === 'undefined') {
      window.isInApp = true;
    }

    console.log('[Flutter Bridge] FlutterMessageQueue initialized:', window.FlutterMessageQueue);
    console.log('[Flutter Bridge] LogToFlutter initialized:', window.LogToFlutter);

    if (window.LogToFlutter && typeof window.LogToFlutter.postMessage === 'function') {
      try {
        window.addEventListener('error', function(event) {
          window.LogToFlutter.postMessage('[WindowError] ' + event.message + ' at ' + event.filename + ':' + event.lineno);
        });
      } catch (bridgeLoggingError) {
        console.error('[Flutter Bridge] Failed to wire logging listeners', bridgeLoggingError);
      }
    }
  """;

  WebViewBridgeHandler({
    required this.controller,
    required this.logger,
    required this.context,
    this.onShowLoading,
    this.onHideLoading,
  });

  Future<void> setupJavaScriptChannels() async {
    if (!_handlersRegistered) {
      controller.addJavaScriptHandler(
        handlerName: 'FlutterMessageQueue',
        callback: (args) {
          if (args.isEmpty) {
            logger.w('Received empty message from JS');
            return;
          }

          final message = args[0].toString();
          final arguments = args.length > 1 ? args.sublist(1) : [];
          logger.d('Received message from JS: $message, arguments: $arguments');
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

      _handlersRegistered = true;
    }

    await setupWebViewJavaScriptChannels();
  }

  /// 웹 페이지에 JavaScript 채널 객체를 정의하는 메서드
  Future<void> setupWebViewJavaScriptChannels() async {
    await controller.evaluateJavascript(source: bridgeSetupScript);
  }

  void _handleFlutterMessageQueue(String message, List<dynamic> arguments) {
    switch (message) {
      case 'deviceToken':
        _sendDeviceToken();
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
        _pickImgFromAlbum();
        break;
      case 'openAlbumMultiple':
        logger.d('openAlbumMultiple called with arguments: $arguments');
        _pickMultipleImgsFromAlbum();
        break;
      case 'openCamera':
        logger.d('openCamera called with arguments: $arguments');
        _pickImgFromCamera();
        break;
      case 'loginWithKakao':
        logger.d('loginWithKakao called with arguments: $arguments');
        _handleKakaoLogin();
        break;
      case 'loginWithApple':
        logger.d('loginWithApple called with arguments: $arguments');
        _handleAppleLogin(arguments);
        break;
      case 'triggerHaptic':
        logger.d('triggerHaptic called with arguments: $arguments');
        _triggerHaptic(arguments);
        break;
      case 'switchEnv':
        logger.d('switchEnvironment called with arguments: $arguments');
        _switchEnvironment(arguments);
        break;
      default:
        logger
            .w("Unknown message received: $message with arguments: $arguments");
    }
  }

  Future<void> _sendDeviceToken() async {
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

  Future<void> _pickImgFromAlbum() async {
    // 권한 상태만 체크 (요청은 image_picker가 자체적으로 처리)
    final status = await Permission.photos.status;

    // 영구 거부된 경우에만 설정으로 안내
    if (status.isPermanentlyDenied) {
      logger.d('앨범 권한 영구 거부됨. 설정으로 안내');
      _showPermissionDialog(
        title: '앨범 접근 권한 안내',
        content: '사진을 첨부하려면 접근 권한이 필요해요.\n설정에서 허용해 주시겠어요?',
        onConfirm: openAppSettings,
      );
      return;
    }

    try {
      onShowLoading?.call('이미지 처리 중...');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        await controller.evaluateJavascript(
          source: "openAlbum('data:image/png;base64,$base64Image')",
        );
      } else {
        logger.d('이미지 선택 취소');
      }
      onHideLoading?.call();
    } catch (e) {
      logger.e('Error picking image: $e');
      onHideLoading?.call();
    }
  }

  Future<void> _pickImgFromCamera() async {
    // 권한 상태만 체크 (요청은 image_picker가 자체적으로 처리)
    final status = await Permission.camera.status;

    // 영구 거부된 경우에만 설정으로 안내
    if (status.isPermanentlyDenied) {
      logger.d('카메라 권한 영구 거부됨. 설정으로 안내');
      _showPermissionDialog(
        title: '카메라 접근 권한 안내',
        content: '사진을 촬영하려면 접근 권한이 필요해요.\n설정에서 허용해 주시겠어요?',
        onConfirm: openAppSettings,
      );
      return;
    }

    try {
      // Android에서 카메라 호출 전 현재 URL 저장 (앱이 kill될 경우 복원용)
      final currentUrl = await controller.getUrl();
      if (currentUrl != null) {
        await UrlRestoreManager.saveUrlBeforeCamera(currentUrl.toString());
        logger.d('카메라 호출 전 URL 저장: $currentUrl');
      }

      onShowLoading?.call('사진 촬영 중...');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        await controller.evaluateJavascript(
          source: "openAlbum('data:image/png;base64,$base64Image')",
        );
      }

      // 정상 복귀 시 저장된 URL 삭제 (앱이 kill되지 않았으므로)
      await UrlRestoreManager.clearSavedUrl();
      onHideLoading?.call();
    } catch (e) {
      logger.e('Error taking image: $e');
      // 에러 시에도 저장된 URL 삭제
      await UrlRestoreManager.clearSavedUrl();
      onHideLoading?.call();
    }
  }

  Future<void> _pickMultipleImgsFromAlbum() async {
    const int maxImages = 5;

    // 권한 상태만 체크 (요청은 image_picker가 자체적으로 처리)
    final status = await Permission.photos.status;

    // 영구 거부된 경우에만 설정으로 안내
    if (status.isPermanentlyDenied) {
      logger.d('앨범 권한 영구 거부됨. 설정으로 안내');
      _showPermissionDialog(
        title: '앨범 접근 권한 안내',
        content: '사진을 첨부하려면 접근 권한이 필요해요.\n설정에서 허용해 주시겠어요?',
        onConfirm: openAppSettings,
      );
      return;
    }

    try {
      onShowLoading?.call('이미지 선택 중...');
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (images.isEmpty) {
        logger.d('이미지 선택 취소');
        onHideLoading?.call();
        return;
      }

      // 최대 5장 제한
      if (images.length > maxImages) {
        logger.w('최대 $maxImages장까지만 선택 가능');
        await controller.evaluateJavascript(
          source: "alert('최대 $maxImages장까지만 선택할 수 있습니다.')",
        );
        onHideLoading?.call();
        return;
      }

      // 여러 이미지를 base64로 변환
      List<String> base64Images = [];
      onShowLoading?.call('이미지 처리 중... (0/${images.length})');

      for (var i = 0; i < images.length; i++) {
        onShowLoading?.call('이미지 처리 중... (${i + 1}/${images.length})');
        final imageBytes = await images[i].readAsBytes();
        final base64Image = base64Encode(imageBytes);
        base64Images.add('data:image/png;base64,$base64Image');
      }

      // JSON 배열로 변환하여 WebView로 전송
      final jsonImages = jsonEncode(base64Images);
      final escapedJson = jsonImages.replaceAll("'", "\\'");

      onShowLoading?.call('이미지 전송 중...');
      await controller.evaluateJavascript(
        source: "openAlbumMultiple('$escapedJson')",
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          logger.e('이미지 전송 타임아웃');
          throw Exception('이미지 전송 시간 초과');
        },
      );

      logger.d('Successfully sent ${images.length} images to WebView');
      onHideLoading?.call();
    } catch (e) {
      logger.e('Error picking multiple images: $e');
      onHideLoading?.call();
    }
  }

  Future<void> _handleKakaoLogin() async {
    try {
      onShowLoading?.call('카카오 로그인 중...');
      KakaoLoginResult? kakaoLoginResult = await loginWithKakao();

      if (kakaoLoginResult == null) {
        onHideLoading?.call();
        return;
      }

      await controller.evaluateJavascript(
        source: "onKakaoLoginSuccess('${kakaoLoginResult.accessToken}')",
      );
      onHideLoading?.call();
    } catch (error) {
      await controller.evaluateJavascript(
        source: "onKakaoLoginError('$error')",
      );
      onHideLoading?.call();
    }
  }

  Future<void> _handleAppleLogin(List<dynamic> arguments) async {
    try {
      onShowLoading?.call('애플 로그인 중...');

      String nonce = arguments[0]['nonce'];
      AppleLoginResult? appleLoginResult = await loginWithApple(nonce);

      if (appleLoginResult == null) {
        onHideLoading?.call();
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
      onHideLoading?.call();
    } catch (error) {
      await controller.evaluateJavascript(
        source: "onAppleLoginError('$error')",
      );
      onHideLoading?.call();
    }
  }

  // 웹뷰 -> flutter {type: 'light'} 와 같은 형식으로 전달됨
  void _triggerHaptic(List<dynamic> arguments) async {
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

  void _showPermissionDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Widget dialog = Platform.isIOS
        ? CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                child: const Text('설정으로 이동'),
                onPressed: () {
                  onConfirm();
                  Navigator.of(context).pop();
                },
              ),
            ],
          )
        : AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('설정으로 이동'),
                onPressed: () {
                  onConfirm();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );

    showDialog(
      context: context,
      builder: (BuildContext context) => dialog,
    );
  }

  void _switchEnvironment(List<dynamic> arguments) async {
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
