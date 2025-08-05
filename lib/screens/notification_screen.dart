import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // ✅ 제목 가운데 정렬
        title: const Text(
          '알림',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold, // ✅ 폰트 굵게
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Image(
              image: AssetImage('assets/images/logo.png'),
              width: 50,
            ),
            title: Text('문의사항에 대한 답변이 등록 되었습니다.'),
          ),
          ListTile(
            leading: Image(
              image: AssetImage('assets/images/logo.png'),
              width: 50,
            ),
            title: Text('영수증 처리가 승인 되었습니다.'),
          ),
        ],
      ),
    );
  }
}