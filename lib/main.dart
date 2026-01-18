import 'package:app/permissions/FirebaseConfig.dart';
import 'package:app/ui/loading_widget.dart';
import 'package:app/utils/env/env.dart';
import 'package:app/web_view/web_view.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_template.dart';
import 'package:logger/logger.dart';

Logger logger = Logger(
  printer: PrettyPrinter(
    colors: false,
  ),
);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BottleNoteColors extends ThemeExtension<BottleNoteColors> {
  final Color mainCoral;
  final Color subCoral;
  final Color bgGray;
  final Color brightGray;
  final Color mainGray;
  final Color textGray;
  final Color gray;
  final Color mainBlack;
  final Color mainDarkGray;
  final Color sectionWhite;

  const BottleNoteColors({
    required this.mainCoral,
    required this.subCoral,
    required this.bgGray,
    required this.brightGray,
    required this.mainGray,
    required this.textGray,
    required this.gray,
    required this.mainBlack,
    required this.mainDarkGray,
    required this.sectionWhite,
  });

  @override
  BottleNoteColors copyWith({
    Color? mainCoral,
    Color? subCoral,
    Color? bgGray,
    Color? brightGray,
    Color? mainGray,
    Color? textGray,
    Color? gray,
    Color? mainBlack,
    Color? mainDarkGray,
    Color? sectionWhite,
  }) {
    return BottleNoteColors(
      mainCoral: mainCoral ?? this.mainCoral,
      subCoral: subCoral ?? this.subCoral,
      bgGray: bgGray ?? this.bgGray,
      brightGray: brightGray ?? this.brightGray,
      mainGray: mainGray ?? this.mainGray,
      textGray: textGray ?? this.textGray,
      gray: gray ?? this.gray,
      mainBlack: mainBlack ?? this.mainBlack,
      mainDarkGray: mainDarkGray ?? this.mainDarkGray,
      sectionWhite: sectionWhite ?? this.sectionWhite,
    );
  }

  @override
  BottleNoteColors lerp(ThemeExtension<BottleNoteColors>? other, double t) {
    if (other is! BottleNoteColors) {
      return this;
    }
    return BottleNoteColors(
      mainCoral: Color.lerp(mainCoral, other.mainCoral, t)!,
      subCoral: Color.lerp(subCoral, other.subCoral, t)!,
      bgGray: Color.lerp(bgGray, other.bgGray, t)!,
      brightGray: Color.lerp(brightGray, other.brightGray, t)!,
      mainGray: Color.lerp(mainGray, other.mainGray, t)!,
      textGray: Color.lerp(textGray, other.textGray, t)!,
      gray: Color.lerp(gray, other.gray, t)!,
      mainBlack: Color.lerp(mainBlack, other.mainBlack, t)!,
      mainDarkGray: Color.lerp(mainDarkGray, other.mainDarkGray, t)!,
      sectionWhite: Color.lerp(sectionWhite, other.sectionWhite, t)!,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await firebaseInitialized();

  try {
    KakaoSdk.init(nativeAppKey: Env.kaKaoNativeAppKey);
  } catch (e) {
    logger.e('카카오 SDK 초기화 실패: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xffe58257),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffe58257),
          primary: const Color(0xffe58257),
          secondary: const Color(0xffe6e6dd),
        ),
        extensions: const [
          BottleNoteColors(
            mainCoral: Color(0xFFEF9A6E),
            subCoral: Color(0xFFE58257),
            bgGray: Color(0xFFE6E6DD),
            brightGray: Color(0xFFBFBFBF),
            mainGray: Color(0xFF666666),
            textGray: Color(0xFFC6C6C6),
            gray: Color(0xFF2B2B2B),
            mainBlack: Color(0xFF101010),
            mainDarkGray: Color(0xFF252525),
            sectionWhite: Color(0xFFF7F7F7),
          ),
        ],
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const BottleNoteWebView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BottleNoteColors>()!;
    return Scaffold(
      backgroundColor: colors.subCoral,
      body: Center(
        child: LoadingWidget(
          isLoading: true,
          waveColor: Colors.white,
          bottleColor: colors.subCoral,
          isBlur: false,
        ),
      ),
    );
  }
}
