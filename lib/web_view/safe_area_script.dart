import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';

/// 웹이 상태 표시줄·하단 바 높이를 알 수 있게 넘기는 값.
///
/// 일부 Android WebView는 화면 끝까지 그려도 env(safe-area-inset-*)를 0으로 준다.
/// 웹은 이 값과 env 중 큰 값을 여백으로 쓴다 (bottle-note-frontend globals.css).
class SafeAreaScript {
  static const String groupName = 'bottle-note-safe-area';

  /// 시스템 바 높이를 CSS px(= Flutter 논리 px)로 계산한다.
  /// 키보드가 열리면 가려진 하단 여백은 0이 되며, 키보드 높이 자체는 포함하지 않는다.
  static EdgeInsets insetsOf(FlutterView view) {
    return EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio);
  }

  /// window.BottleNoteApp.safeArea를 갱신하고 웹에 바뀌었다고 알리는 스크립트.
  static String build(EdgeInsets insets) {
    final top = insets.top.toStringAsFixed(2);
    final bottom = insets.bottom.toStringAsFixed(2);
    return '''
(function() {
  var app = window.BottleNoteApp || (window.BottleNoteApp = {});
  app.safeArea = { top: $top, bottom: $bottom };
  window.dispatchEvent(new Event('bottlenote:safearea'));
})();
''';
  }
}
