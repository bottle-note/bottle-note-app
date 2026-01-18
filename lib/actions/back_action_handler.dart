import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/*
*
  bool _backButtonPressedOnce = false;

  @Deprecated("This method is deprecated. Use handleBackAction() instead.")
  _backAction() async {
    // 안드로이드 뒤로가기 버튼 동작 제어
    if (await _controller.canGoBack()) {
      //_controller 에서 뒤로 갈 곳이 있는지 확인합니다. bool형태로 나옵니다
      _controller
          .goBack(); //갈곳이 있는경우 true이기 때문에 이 코드가 실행됩니다. _controller 의 이전 페이지로 이동합니다.
      return false;
    } else {
      //만약 _controller 에서 뒤로 갈 곳이 없는 경우~
      if (_backButtonPressedOnce) {
        //_backButtonPressedOnce 가 true 인 경우
        SystemNavigator.pop(); //앱 종료
      } else {
        _backButtonPressedOnce = true; //_backButtonPressedOnce 를 true로 바꾸고
        ScaffoldMessenger.of(context).showSnackBar(
          //하단에 스낵바를 생성합니다.
          const SnackBar(
            content: Text('한 번 더 누르시면 앱이 종료됩니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        Timer(const Duration(seconds: 2), () {
          //그리고 2초 뒤 _backButtonPressedOnce 값을 다시 false로 변환합니다.
          _backButtonPressedOnce = false;
        });
        return false;
      }
    }
    return true;
  }
*/

class BackActionHandler {
  final InAppWebViewController webViewController;
  final BuildContext context;
  bool _backButtonPressedOnce = false;

  BackActionHandler({
    required this.webViewController,
    required this.context,
  });

  /// 뒤로가기 액션을 처리하는 메서드
  Future<bool> action() async {
    if (await webViewController.canGoBack()) {
      // WebView에서 뒤로 갈 페이지가 있는 경우
      await webViewController.goBack();
      return false;
    } else {
      // WebView에서 더 이상 뒤로 갈 페이지가 없는 경우
      return _handleAppExit();
    }
  }

  /// 앱 종료 처리를 담당하는 private 메서드
  Future<bool> _handleAppExit() async {
    if (_backButtonPressedOnce) {
      // 이미 한 번 뒤로가기가 눌린 상태면 앱 종료
      SystemNavigator.pop();
      return true;
    } else {
      _showExitSnackBar();
      _resetBackButtonFlag();
      return false;
    }
  }

  /// 종료 안내 스낵바를 표시하는 private 메서드
  void _showExitSnackBar() {
    _backButtonPressedOnce = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('한 번 더 누르시면 앱이 종료됩니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 뒤로가기 버튼 플래그를 리셋하는 private 메서드
  void _resetBackButtonFlag() {
    Timer(const Duration(seconds: 2), () {
      _backButtonPressedOnce = false;
    });
  }
}
