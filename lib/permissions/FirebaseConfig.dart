import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import '../main.dart' show logger;

Future<void> _onBackgroundMessage(RemoteMessage message) async {}

firebaseInitialized() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.requestPermission(
    badge: true,
    alert: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  firebaseMessagingListener();

  try {
    var token = (await FirebaseMessaging.instance.getToken())!;
    logger.d("디바이스 토큰 : $token");
  } catch (e) {
    logger.e("토큰 발급 실패 : $e");
  }
}

Future<String?> getDeviceToken() async {
  return (await FirebaseMessaging.instance.getToken())!;
}

firebaseMessagingListener() {
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage? message) {
      if (message != null) {
        if (message.notification != null) {
          print("앱 실행 중 메시지 수신");
          logger.d(
            "title: ${message.notification!.title},"
            " body: ${message.notification!.body},"
            " click_action: ${message.data["click_action"]}",
          );
        }
      }
    },
  );
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
    print("앱 백그라운드 상태에서 메시지 수신");
    if (message != null) {
      if (message.notification != null) {
        logger.d(message.notification!.title);
        logger.d(message.notification!.body);
        logger.d(message.data["click_action"]);
      }
    }
  });
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      if (message.notification != null) {
        logger.d(message.notification!.title);
        logger.d(message.notification!.body);
        logger.d(message.data["click_action"]);
      }
    }
  });
}
