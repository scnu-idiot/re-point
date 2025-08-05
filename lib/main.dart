import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'screens/splash_screen.dart'; // 스플래시 화면

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK 초기화 - 반드시 runApp 전에!
  KakaoSdk.init(nativeAppKey: 'dd00c30573b12a8a81cd65b526943c99');

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
        fontFamily: 'Pretendard', // 선택사항
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // 첫 화면: 스플래시
    );
  }
}