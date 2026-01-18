import 'package:app/main.dart' show logger;
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleLoginResult {
  final String idToken;

  AppleLoginResult({required this.idToken});
}

class KakaoLoginResult {
  final String accessToken;

  KakaoLoginResult({required this.accessToken});
}

Future<KakaoLoginResult?> loginWithKakao() async {
  try {
    print('[KAKAO_LOGIN] 카카오 로그인 시작');
    logger.d('카카오 로그인 시작');

    bool installed = await isKakaoTalkInstalled();
    print('[KAKAO_LOGIN] 카카오톡 설치 상태: $installed');
    logger.d('카카오톡 설치 상태: $installed');

    bool kakaoTalkLoginSucceeded = false;

    if (installed) {
      try {
        print('[KAKAO_LOGIN] 카카오톡 로그인 시도');
        logger.d('카카오톡 로그인 시도');
        await UserApi.instance.loginWithKakaoTalk();
        kakaoTalkLoginSucceeded = true;
        print('[KAKAO_LOGIN] 카카오톡 로그인 성공');
        logger.d('카카오톡 로그인 성공');
      } catch (e) {
        print('[KAKAO_LOGIN] 카카오톡 로그인 실패, 계정 로그인으로 fallback: $e');
        logger.d('카카오톡 로그인 실패, 계정 로그인으로 fallback: $e');
      }
    }

    if (!kakaoTalkLoginSucceeded) {
      print('[KAKAO_LOGIN] 카카오 계정 로그인 시도');
      logger.d('카카오 계정 로그인 시도');
      await UserApi.instance.loginWithKakaoAccount();
      print('[KAKAO_LOGIN] 카카오 계정 로그인 성공');
      logger.d('카카오 계정 로그인 성공');
    }

    print('[KAKAO_LOGIN] 사용자 정보 요청');
    logger.d('사용자 정보 요청');
    User user = await UserApi.instance.me();
    print('[KAKAO_LOGIN] 카카오 로그인 최종 성공 - 사용자 ID: ${user.id}');
    logger.d('카카오 로그인 최종 성공 - 사용자 ID: ${user.id}');

    // 액세스 토큰 가져오기
    print('[KAKAO_LOGIN] 액세스 토큰 요청');
    logger.d('액세스 토큰 요청');
    OAuthToken? token = await TokenManagerProvider.instance.manager.getToken();
    if (token == null) {
      print('[KAKAO_LOGIN] 액세스 토큰을 가져올 수 없습니다.');
      logger.w('액세스 토큰을 가져올 수 없습니다.');
      return null;
    }
    String accessToken = token.accessToken;
    print('[KAKAO_LOGIN] 액세스 토큰 획득 성공: ${accessToken.substring(0, 10)}...');
    logger.d('액세스 토큰 획득 성공');

    return KakaoLoginResult(
      accessToken: accessToken,
    );
  } on PlatformException catch (e) {
    print('[KAKAO_LOGIN] PlatformException 발생: ${e.code} - ${e.message}');
    logger.e('PlatformException 발생: ${e.code} - ${e.message}');
    if (e.code == 'CANCELED') {
      print('[KAKAO_LOGIN] 사용자가 로그인을 취소했습니다.');
      logger.d('사용자가 로그인을 취소했습니다.');
      return null;
    }
    print('[KAKAO_LOGIN] 알 수 없는 PlatformException: ${e.toString()}');
    logger.e('알 수 없는 PlatformException: ${e.toString()}');
    return null;
  } catch (error) {
    print('[KAKAO_LOGIN] 예상치 못한 오류 발생: $error');
    logger.e('예상치 못한 오류 발생: $error');
    return null;
  }
}

Future<AppleLoginResult?> loginWithApple(String nonce) async {
  try {
    print('[APPLE_LOGIN] 애플 로그인 시작');
    logger.d('애플 로그인 시작');

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: nonce,
    );

    print('[APPLE_LOGIN] 애플 로그인 credential 획득 성공');
    logger.d('애플 로그인 credential 획득 성공');

    String? idToken = credential.identityToken;

    if (idToken == null) {
      print('[APPLE_LOGIN] ID 토큰이 null입니다.');
      logger.w('ID 토큰이 null입니다.');
      return null;
    }

    print('[APPLE_LOGIN] 애플 로그인 성공 - ID 토큰 획득');
    logger.d('애플 로그인 성공 - ID 토큰 획득');

    return AppleLoginResult(
      idToken: idToken,
    );
  } on PlatformException catch (e) {
    print('[APPLE_LOGIN] PlatformException 발생: ${e.code} - ${e.message}');
    logger.e('PlatformException 발생: ${e.code} - ${e.message}');
    if (e.code == 'CANCELED') {
      print('[APPLE_LOGIN] 사용자가 로그인을 취소했습니다.');
      logger.d('사용자가 로그인을 취소했습니다.');
      return null;
    }
    print('[APPLE_LOGIN] 알 수 없는 PlatformException: ${e.toString()}');
    logger.e('알 수 없는 PlatformException: ${e.toString()}');
    return null;
  } catch (error) {
    print('[APPLE_LOGIN] 예상치 못한 오류 발생: $error');
    logger.e('예상치 못한 오류 발생: $error');
    return null;
  }
}
