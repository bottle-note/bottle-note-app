import 'dart:collection';

import 'package:app/bridge/web_view_bridge_handler.dart';
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
  const BottleNoteWebView({super.key, this.onLoaded});

  @override
  State<BottleNoteWebView> createState() => BottleNoteWebViewState();
}

class BottleNoteWebViewState extends State<BottleNoteWebView>
    with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigationHandler = WebViewNavigationHandler(logger: logger);
    _permissionWithNotification();
    _setupPullToRefresh();
    _initialUserScripts = UnmodifiableListView([
      UserScript(
        source: WebViewBridgeHandler.bridgeSetupScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);
  }

  void _setupPullToRefresh() {
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: const Color(0xffe58257),
        backgroundColor: Colors.white,
      ),
      onRefresh: () async {
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
    _pullToRefreshController.dispose();
    _webviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BottleNoteColors>()!;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (_backActionHandler != null) {
          await _backActionHandler!.action();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _buildBody(colors),
      ),
    );
  }

  Widget _buildBody(BottleNoteColors colors) {
    final content = Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(Env.webViewUrl)),
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
                final isDone =
                    ajaxRequest.readyState == AjaxRequestReadyState.DONE;
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
