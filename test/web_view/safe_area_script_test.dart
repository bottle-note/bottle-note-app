import 'package:app/web_view/safe_area_script.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeAreaScript.build', () {
    test('웹이 읽을 상하단 높이를 CSS px로 넣는다', () {
      final script = SafeAreaScript.build(
        const EdgeInsets.only(top: 36.33, bottom: 48),
      );

      expect(script, contains('app.safeArea = { top: 36.33, bottom: 48.00 }'));
    });

    test('값이 바뀌었다고 웹에 이벤트를 보낸다', () {
      final script = SafeAreaScript.build(EdgeInsets.zero);

      expect(script, contains("new Event('bottlenote:safearea')"));
    });
  });

  testWidgets('SafeAreaScript.insetsOf는 물리 px를 논리 px로 바꾼다', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 109, bottom: 144);
    addTearDown(tester.view.reset);

    final insets = SafeAreaScript.insetsOf(tester.view);

    expect(insets.top, closeTo(36.33, 0.01));
    expect(insets.bottom, 48);
  });

  testWidgets('키보드가 열리면 시스템 바 여백과 키보드 높이를 더하지 않는다', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(top: 109, bottom: 144);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    tester.view.padding = const FakeViewPadding(top: 109);
    addTearDown(tester.view.reset);

    final insets = SafeAreaScript.insetsOf(tester.view);

    expect(insets.top, closeTo(36.33, 0.01));
    expect(insets.bottom, 0);

    tester.view.viewInsets = const FakeViewPadding();
    tester.view.padding = const FakeViewPadding(top: 109, bottom: 144);
    expect(SafeAreaScript.insetsOf(tester.view).bottom, 48);
  });
}
