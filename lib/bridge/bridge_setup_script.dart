/// WebView에 주입되는 JavaScript 브릿지 스크립트
class BridgeSetupScript {
  BridgeSetupScript._();

  static const String script = """
    (function() {
      window.AppBridge = window.AppBridge || {};

      function _setupChannel(name) {
        window.AppBridge[name] = {
          postMessage: function(...args) {
            return window.flutter_inappwebview.callHandler('AppBridge.' + name, ...args);
          }
        };
      }

      // Legacy FlutterMessageQueue (구버전 웹 호환)
      if (typeof window.FlutterMessageQueue === 'undefined') {
        window.FlutterMessageQueue = {
          postMessage: function(message, ...args) {
            return window.flutter_inappwebview.callHandler('FlutterMessageQueue', message, ...args);
          }
        };
      }

      // 개별 채널 인터페이스
      _setupChannel('deviceToken');
      _setupChannel('platform');
      _setupChannel('album');
      _setupChannel('albumMultiple');
      _setupChannel('camera');
      _setupChannel('kakaoLogin');
      _setupChannel('appleLogin');
      _setupChannel('haptic');
      _setupChannel('env');
      _setupChannel('share');

      // 로깅 채널
      if (typeof window.LogToFlutter === 'undefined') {
        window.LogToFlutter = {
          postMessage: function(message) {
            window.flutter_inappwebview.callHandler('LogToFlutter', message);
          }
        };
      }

      window.isInApp = true;

      console.log('[Flutter Bridge] AppBridge channels:', Object.keys(window.AppBridge));

      if (window.LogToFlutter && typeof window.LogToFlutter.postMessage === 'function') {
        try {
          window.addEventListener('error', function(event) {
            window.LogToFlutter.postMessage('[WindowError] ' + event.message + ' at ' + event.filename + ':' + event.lineno);
          });
        } catch (bridgeLoggingError) {
          console.error('[Flutter Bridge] Failed to wire logging listeners', bridgeLoggingError);
        }
      }
    })();
  """;
}
