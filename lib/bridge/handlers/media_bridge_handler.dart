import 'dart:convert';

import 'package:app/bridge/handlers/bridge_handler_base.dart';
import 'package:app/utils/url_restore_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 이미지 선택 및 카메라 관련 브릿지 핸들러
mixin MediaBridgeHandler on BridgeHandlerBase {
  Future<void> pickImgFromAlbum() async {
    try {
      onShowLoading?.call('이미지 처리 중...');
      final ImagePicker picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: ImageSource.gallery);

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

  Future<void> pickImgFromCamera() async {
    final status = await Permission.camera.status;

    if (status.isPermanentlyDenied) {
      logger.d('카메라 권한 영구 거부됨. 설정으로 안내');
      showPermissionDialog(
        title: '카메라 접근 권한 안내',
        content: '사진을 촬영하려면 접근 권한이 필요해요.\n설정에서 허용해 주시겠어요?',
        onConfirm: openAppSettings,
      );
      return;
    }

    try {
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

      await UrlRestoreManager.clearSavedUrl();
      onHideLoading?.call();
    } catch (e) {
      logger.e('Error taking image: $e');
      await UrlRestoreManager.clearSavedUrl();
      onHideLoading?.call();
    }
  }

  Future<void> pickMultipleImgsFromAlbum() async {
    const int maxImages = 5;

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

      if (images.length > maxImages) {
        logger.w('최대 $maxImages장까지만 선택 가능');
        await controller.evaluateJavascript(
          source: "alert('최대 $maxImages장까지만 선택할 수 있습니다.')",
        );
        onHideLoading?.call();
        return;
      }

      List<String> base64Images = [];
      onShowLoading?.call('이미지 처리 중... (0/${images.length})');

      for (var i = 0; i < images.length; i++) {
        onShowLoading?.call('이미지 처리 중... (${i + 1}/${images.length})');
        final imageBytes = await images[i].readAsBytes();
        final base64Image = base64Encode(imageBytes);
        base64Images.add('data:image/png;base64,$base64Image');
      }

      final jsonImages = jsonEncode(base64Images);
      final escapedJson = jsonImages.replaceAll("'", "\\'");

      onShowLoading?.call('이미지 전송 중...');
      await controller
          .evaluateJavascript(
        source: "openAlbumMultiple('$escapedJson')",
      )
          .timeout(
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
}
