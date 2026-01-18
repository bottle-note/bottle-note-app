import 'dart:io';

import 'package:app/utils/env/env.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewNavigationHandler {
  final Logger logger;

  final MethodChannel platform =
      const MethodChannel('com.bottlenote.official.app/intents');

  WebViewNavigationHandler({
    required this.logger,
  });

  Future<NavigationActionPolicy> handleNavigationAction(
    NavigationAction navigationAction,
  ) async {
    final url = navigationAction.request.url?.toString() ?? '';
    const prodUrl = 'https://bottle-note.com/';
    const devUrl = 'https://development.bottle-note.com/';

    if (!url.startsWith(prodUrl) &&
        !url.startsWith(devUrl) &&
        !url.startsWith(Env.webViewUrl)) {
      if (Platform.isIOS) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.inAppWebView,
        );
      } else if (Platform.isAndroid) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }
}
