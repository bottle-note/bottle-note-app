import 'dart:async';
import 'dart:collection';

import 'package:app/bridge/bridge_setup_script.dart';
import 'package:app/bridge/web_view_bridge_handler.dart';
import 'package:app/utils/network/connectivity_service.dart';
import 'package:app/ui/offline_screen.dart';
import 'package:app/bridge/web_view_navigation_handler.dart';
import 'package:app/main.dart';
import 'package:app/utils/env/env.dart';
import 'package:app/ui/loading_widget.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../actions/back_action_handler.dart';

class BottleNoteWebView extends StatefulWidget {
  final VoidCallback? onLoaded;
  final String? initialUrl;

  const BottleNoteWebView({super.key, this.onLoaded, this.initialUrl});

  @override
  State<BottleNoteWebView> createState() => BottleNoteWebViewState();
}

class BottleNoteWebViewState extends State<BottleNoteWebView>
    with WidgetsBindingObserver {
  static const String _systemUiThemeHandlerName = 'SystemUiTheme';
  static const Color _refreshIndicatorColor = Color(0xffe58257);
  static const String _nativeSafeAreaOverrideScript = r'''
    (function() {
      function applyNativeSafeAreaOverrides() {
        const root = document.documentElement;
        if (!root) return;

        if (!document.getElementById('bottle-note-native-safe-area')) {
          const style = document.createElement('style');
          style.id = 'bottle-note-native-safe-area';
          style.textContent = `
            html { --navbar-margin-bottom: 8px !important; }
            .pt-safe-header { padding-top: 0 !important; }
          `;
          (document.head || root).appendChild(style);
        }
      }

      applyNativeSafeAreaOverrides();
      if (document.readyState === 'loading') {
        document.addEventListener(
          'DOMContentLoaded',
          applyNativeSafeAreaOverrides,
          { once: true },
        );
      }
    })();
  ''';
  static const String _systemUiThemeObserverScript = r'''
    (function() {
      function isDarkTheme() {
        const root = document.documentElement;
        const body = document.body;
        const rootDark = root.classList.contains('dark') || root.dataset.theme === 'dark';
        const bodyDark = body &&
          (body.classList.contains('dark') || body.dataset.theme === 'dark');

        return rootDark || bodyDark;
      }

      function opaqueBackgroundOf(element) {
        if (!element) return null;

        const color = getComputedStyle(element).backgroundColor;
        const channels = color.match(/[\d.]+/g);
        if (!channels || channels.length < 3) return null;

        const alpha = channels.length >= 4 ? Number(channels[3]) : 1;
        return alpha > 0 ? channels.slice(0, 3).map(Number) : null;
      }

      function documentBackground() {
        return opaqueBackgroundOf(document.documentElement) ||
          opaqueBackgroundOf(document.body);
      }

      let lastSystemUiState;

      function notifyFlutter() {
        const topBackground = documentBackground();
        const systemUiState = JSON.stringify([
          isDarkTheme(),
          topBackground,
        ]);

        if (systemUiState === lastSystemUiState) return;
        lastSystemUiState = systemUiState;

        window.flutter_inappwebview.callHandler(
          'SystemUiTheme',
          isDarkTheme(),
          topBackground,
        );
      }

      let notifyScheduled = false;

      function scheduleNotify() {
        if (notifyScheduled) return;
        notifyScheduled = true;

        window.requestAnimationFrame(function() {
          notifyScheduled = false;
          notifyFlutter();
        });
      }

      const observerOptions = {
        attributes: true,
        attributeFilter: ['class', 'data-theme', 'style'],
      };

      function observeThemeTargets(observer) {
        observer.observe(document.documentElement, observerOptions);
        if (document.body) {
          observer.observe(document.body, observerOptions);
        }
      }

      if (window.__bottleNoteSystemUiThemeObserver) {
        observeThemeTargets(window.__bottleNoteSystemUiThemeObserver);
        notifyFlutter();
        return;
      }

      const observer = new MutationObserver(scheduleNotify);
      window.__bottleNoteSystemUiThemeObserver = observer;
      observeThemeTargets(observer);

      if (!document.body && document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
          observeThemeTargets(observer);
          scheduleNotify();
        }, { once: true });
      }

      notifyFlutter();
    })();
  ''';

  final Logger logger = Logger(
    printer: PrettyPrinter(colors: false),
  );

  late InAppWebViewController _webviewController;
  BackActionHandler? _backActionHandler;
  WebViewBridgeHandler? _webViewBridgeHandler;
  late final WebViewNavigationHandler _navigationHandler;
  late PullToRefreshController _pullToRefreshController;
  late final UnmodifiableListView<UserScript> _initialUserScripts;

  bool _isAppLoading = false;
  late String _url = '';
  bool _isWebViewCreated = false;
  bool _hasWebViewTheme = false;
  bool _isWebViewDark = false;
  Color? _webViewTopColor;

  // Network status
  late ConnectivityService _connectivityService;
  StreamSubscription<NetworkStatus>? _networkSubscription;
  bool _isOffline = false;
  bool _initialLoadCompleted = false;

  // Lifecycle
  DateTime? _backgroundTime;
  static const Duration _refreshThreshold = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigationHandler = WebViewNavigationHandler(logger: logger);
    _connectivityService = ConnectivityService(logger: logger);
    _initializeConnectivity();
    _permissionWithNotification();
    _setupPullToRefresh();
    _initialUserScripts = UnmodifiableListView([
      if (Platform.isAndroid)
        UserScript(
          source: _nativeSafeAreaOverrideScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      UserScript(
        source: BridgeSetupScript.script,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();

    if (!mounted) return;

    final isConnected = await _connectivityService.checkConnectivity();
    if (!mounted) return;

    if (!isConnected) {
      setState(() {
        _isOffline = true;
      });
    }

    _networkSubscription =
        _connectivityService.networkStatusStream.listen((status) {
      if (!mounted) return;

      final wasOffline = _isOffline;
      setState(() {
        _isOffline = status == NetworkStatus.offline;
      });

      // Offline -> Online: auto reload
      if (wasOffline &&
          status == NetworkStatus.online &&
          _initialLoadCompleted &&
          _isWebViewCreated) {
        _webviewController.reload();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _backgroundTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        _refreshSystemUiAfterConfigurationChange();
        break;
      default:
        break;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _refreshSystemUiAfterConfigurationChange();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _refreshSystemUiAfterConfigurationChange();
  }

  void _refreshSystemUiAfterConfigurationChange() {
    if (!mounted) return;

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applySystemUiOverlayStyle(
        isDark: _effectiveDarkMode,
        topColor: _webViewTopColor ?? _fallbackSystemBarColor,
        bottomColor: _fallbackSystemBarColor,
      );
    });
  }

  void _handleAppResumed() {
    if (_backgroundTime != null && _initialLoadCompleted && _isWebViewCreated) {
      final duration = DateTime.now().difference(_backgroundTime!);
      if (duration > _refreshThreshold) {
        logger.d(
            'Long background duration: ${duration.inSeconds}s. Reloading WebView.');
        _webviewController.reload();
      }
      _backgroundTime = null;
    }
  }

  void _setupPullToRefresh() {
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: _refreshIndicatorColor,
        backgroundColor: Colors.white,
      ),
      onRefresh: () async {
        if (!_isWebViewCreated) return;

        if (Platform.isAndroid) {
          _webviewController.reload();
        } else if (Platform.isIOS) {
          _webviewController.loadUrl(
            urlRequest: URLRequest(url: await _webviewController.getUrl()),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cancel network subscription first to prevent callbacks on disposed controller
    _networkSubscription?.cancel();
    _connectivityService.dispose();
    _pullToRefreshController.dispose();
    if (_isWebViewCreated) {
      _webviewController.dispose();
    }
    super.dispose();
  }

  Future<void> _retryConnection() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _isOffline = false;
      });
      if (_initialLoadCompleted && _isWebViewCreated) {
        _webviewController.reload();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인터넷 연결을 확인해 주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BottleNoteColors>()!;
    final isDark = _hasWebViewTheme
        ? _isWebViewDark
        : MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final fallbackSystemBarColor = isDark ? Colors.black : Colors.white;
    final topSystemBarColor = _webViewTopColor ?? fallbackSystemBarColor;
    final bottomSystemBarColor = fallbackSystemBarColor;
    final systemPadding = MediaQuery.paddingOf(context);
    final webViewPadding = Platform.isAndroid ? systemPadding : EdgeInsets.zero;
    final systemUiOverlayStyle = _systemUiOverlayStyle(
      isDark: isDark,
      topColor: topSystemBarColor,
      bottomColor: bottomSystemBarColor,
    );

    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (_backActionHandler != null) {
            await _backActionHandler!.action();
          }
        },
        child: Scaffold(
          backgroundColor: bottomSystemBarColor,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: webViewPadding,
                child: _isOffline && !_initialLoadCompleted
                    ? OfflineScreen(onRetry: _retryConnection)
                    : _buildBody(colors),
              ),
              if (Platform.isAndroid && systemPadding.top > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: systemPadding.top,
                  child: IgnorePointer(
                    child: ColoredBox(color: topSystemBarColor),
                  ),
                ),
              if (Platform.isAndroid && systemPadding.bottom > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: systemPadding.bottom,
                  child: IgnorePointer(
                    child: ColoredBox(color: bottomSystemBarColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BottleNoteColors colors) {
    final content = Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(widget.initialUrl ?? Env.webViewUrl),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: true,
            useShouldInterceptAjaxRequest: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            iframeAllowFullscreen: true,
            isInspectable: !kReleaseMode,
          ),
          initialUserScripts: _initialUserScripts,
          pullToRefreshController: _pullToRefreshController,
          onWebViewCreated: (controller) {
            _webviewController = controller;
            _isWebViewCreated = true;
            _setupSystemUiThemeHandler(controller);
            _webViewBridgeHandler = WebViewBridgeHandler(
              controller: controller,
              logger: logger,
              context: context,
              onShowLoading: _showAppLoading,
              onHideLoading: _hideAppLoading,
            );
            _backActionHandler = BackActionHandler(
              webViewController: controller,
              context: context,
            );

            _webViewBridgeHandler!.setupJavaScriptChannels();
          },
          onUpdateVisitedHistory: (controller, url, isReload) {
            setState(() {
              _url = url.toString();
            });
          },
          onLoadStart: (controller, url) {},
          onLoadStop: (controller, url) async {
            _pullToRefreshController.endRefreshing();
            _initialLoadCompleted = true;

            if (Platform.isAndroid) {
              await controller.evaluateJavascript(
                source: _nativeSafeAreaOverrideScript,
              );
            }
            await controller.evaluateJavascript(
              source: _systemUiThemeObserverScript,
            );

            // 웹뷰가 완전히 로드된 후 JavaScript 초기화
            if (_webViewBridgeHandler != null) {
              await _webViewBridgeHandler!.setupJavaScriptChannels();
            }
            // onLoaded 콜백 호출
            if (widget.onLoaded != null) {
              widget.onLoaded!();
            }
          },
          onReceivedHttpError: (controller, request, errorResponse) {
            _pullToRefreshController.endRefreshing();
            logger.w(
              '[HTTP Error] url=${request.url} status=${errorResponse.statusCode} description=${errorResponse.reasonPhrase}',
            );
          },
          onReceivedError: (controller, request, error) {
            logger.e('WebView error: ${error.description}');
            _pullToRefreshController.endRefreshing();
          },
          onProgressChanged: (controller, progress) {},
          onConsoleMessage: (controller, consoleMessage) {
            if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
              logger.e('[WebView Console] ${consoleMessage.message}');
            }
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            return await _navigationHandler
                .handleNavigationAction(navigationAction);
          },
          shouldInterceptAjaxRequest: (controller, ajaxRequest) async {
            return ajaxRequest;
          },
          onAjaxReadyStateChange: (controller, ajaxRequest) async {
            final isDone = ajaxRequest.readyState == AjaxRequestReadyState.DONE;
            final status = ajaxRequest.status;
            if (isDone && status != null && status >= 400) {
              logger.w(
                '[AjaxError] status=$status url=${ajaxRequest.url}',
              );
            }
            return AjaxRequestAction.PROCEED;
          },
          onAjaxProgress: (controller, ajaxRequest) async {
            return AjaxRequestAction.PROCEED;
          },
          onReceivedServerTrustAuthRequest: (controller, challenge) async {
            // Surface SSL challenges to diagnose certificate issues during loading.
            logger.w(
              '[SSL] host=${challenge.protectionSpace.host} protocol=${challenge.protectionSpace.protocol} error=${challenge.protectionSpace.sslError}',
            );
            if (kReleaseMode) {
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            }
            return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.PROCEED,
            );
          },
        ),
        if (_isAppLoading)
          LoadingWidget(
            isLoading: _isAppLoading,
            waveColor: colors.subCoral,
            bottleColor: Colors.white,
          ),
        if (_url.contains('development') || _url.contains('192.'))
          Container(
            width: double.infinity,
            height: 120,
            alignment: Alignment.centerLeft,
            child: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text(
                'development',
                style: TextStyle(color: Colors.black12, fontSize: 10),
              ),
            ),
          ),
      ],
    );

    return content;
  }

  void _setupSystemUiThemeHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: _systemUiThemeHandlerName,
      callback: (arguments) {
        final isDark = arguments.isNotEmpty && arguments.first == true;
        final webViewTopColor =
            _colorFromJavaScript(arguments.length > 1 ? arguments[1] : null);
        if (!mounted ||
            (_hasWebViewTheme &&
                isDark == _isWebViewDark &&
                webViewTopColor == _webViewTopColor)) {
          return;
        }

        setState(() {
          _hasWebViewTheme = true;
          _isWebViewDark = isDark;
          _webViewTopColor = webViewTopColor;
        });

        unawaited(
          _pullToRefreshController.setBackgroundColor(
            webViewTopColor ?? (isDark ? Colors.black : Colors.white),
          ),
        );
      },
    );
  }

  bool get _effectiveDarkMode => _hasWebViewTheme
      ? _isWebViewDark
      : WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;

  Color get _fallbackSystemBarColor =>
      _effectiveDarkMode ? Colors.black : Colors.white;

  void _applySystemUiOverlayStyle({
    required bool isDark,
    required Color topColor,
    required Color bottomColor,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      _systemUiOverlayStyle(
        isDark: isDark,
        topColor: topColor,
        bottomColor: bottomColor,
      ),
    );
  }

  SystemUiOverlayStyle _systemUiOverlayStyle({
    required bool isDark,
    required Color topColor,
    required Color bottomColor,
  }) {
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return SystemUiOverlayStyle(
      systemNavigationBarColor: bottomColor,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarContrastEnforced: false,
      statusBarColor: topColor,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: iconBrightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
    );
  }

  Color? _colorFromJavaScript(Object? value) {
    if (value is! List || value.length < 3) return null;

    final red = value[0];
    final green = value[1];
    final blue = value[2];
    if (red is! num || green is! num || blue is! num) return null;

    return Color.fromARGB(
      255,
      red.round().clamp(0, 255),
      green.round().clamp(0, 255),
      blue.round().clamp(0, 255),
    );
  }

  _permissionWithNotification() async {
    if (await Permission.notification.isDenied &&
        !await Permission.notification.isPermanentlyDenied) {
      await [Permission.notification].request();
    }
  }

  void _showAppLoading(String message) {
    setState(() {
      _isAppLoading = true;
    });
  }

  void _hideAppLoading() {
    setState(() {
      _isAppLoading = false;
    });
  }
}
