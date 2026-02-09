import 'package:app/bridge/handlers/bridge_handler_base.dart';
import 'package:share_plus/share_plus.dart';

/// 네이티브 공유 시트 관련 브릿지 핸들러
mixin ShareBridgeHandler on BridgeHandlerBase {
  Future<void> handleShare(List<dynamic> arguments) async {
    if (arguments.isEmpty || arguments[0] is! Map) {
      logger.w('공유 인자가 올바르지 않습니다: $arguments');
      return;
    }

    try {
      final Map<String, dynamic> shareArgs =
          Map<String, dynamic>.from(arguments[0]);

      final String title = shareArgs['title'] ?? '';
      final String description = shareArgs['description'] ?? '';
      final String linkUrl = shareArgs['linkUrl'] ?? '';

      final StringBuffer shareText = StringBuffer();
      if (title.isNotEmpty) {
        shareText.writeln(title);
      }
      if (description.isNotEmpty) {
        shareText.writeln(description);
      }
      if (linkUrl.isNotEmpty) {
        shareText.write(linkUrl);
      }

      final String textToShare = shareText.toString().trim();

      if (textToShare.isEmpty) {
        logger.w('공유할 내용이 없습니다.');
        return;
      }

      logger.d('공유 시작: $textToShare');

      final result = await Share.share(textToShare);

      logger.d('공유 결과: ${result.status}');

      if (result.status == ShareResultStatus.success) {
        await controller.evaluateJavascript(
          source: "onShareSuccess && onShareSuccess()",
        );
      } else if (result.status == ShareResultStatus.dismissed) {
        await controller.evaluateJavascript(
          source: "onShareDismissed && onShareDismissed()",
        );
      }
    } catch (e) {
      logger.e('공유 중 오류 발생: $e');
      await controller.evaluateJavascript(
        source: "onShareError && onShareError('$e')",
      );
    }
  }
}
