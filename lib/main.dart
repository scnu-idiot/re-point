import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter/services.dart';   // ✅ 시스템 UI 제어용 import

import 'firebase_options.dart';        // flutterfire configure가 생성
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Kakao 먼저 초기화
  KakaoSdk.init(nativeAppKey: 'dd00c30573b12a8a81cd65b526943c99');

  // ✅ Firebase 초기화 (각 플랫폼 옵션 적용)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 앱 전체에서 상태바 + 네비게이션바 숨김 (Immersive 모드)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RE:POINT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard',
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}


