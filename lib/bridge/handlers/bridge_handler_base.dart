import 'dart:io';

import 'package:app/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logger/logger.dart';

/// 브릿지 핸들러 공통 의존성 및 유틸리티
abstract class BridgeHandlerBase {
  InAppWebViewController get controller;
  Logger get logger;
  Function(String)? get onShowLoading;
  VoidCallback? get onHideLoading;
  BuildContext get context;

  /// 권한 요청 다이얼로그 (iOS: Cupertino, Android: Material)
  void showPermissionDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    Widget dialog = Platform.isIOS
        ? CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              CupertinoDialogAction(
                child: const Text('설정으로 이동'),
                onPressed: () {
                  onConfirm();
                  Navigator.of(ctx).pop();
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
                  Navigator.of(ctx).pop();
                },
              ),
              TextButton(
                child: const Text('설정으로 이동'),
                onPressed: () {
                  onConfirm();
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          );

    showDialog(
      context: ctx,
      builder: (BuildContext context) => dialog,
    );
  }
}
