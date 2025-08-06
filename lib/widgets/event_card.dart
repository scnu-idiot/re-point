import 'package:flutter/material.dart';

class EventCardScreen extends StatelessWidget {
  const EventCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // ✅ 제목 가운데 정렬
        title: const Text(
          '이벤트',
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
            title: Text('8월 3주차 포인트 2배 적립 지역 안내'),
          ),
          ListTile(
            leading: Image(
              image: AssetImage('assets/images/logo.png'),
              width: 50,
            ),
            title: Text('8월 4주차 포인트 2배 적립 지역 안내'),
          ),
          ListTile(
            leading: Image(
              image: AssetImage('assets/images/logo.png'),
              width: 50,
            ),
            title: Text('8월 친구 초대 이벤트 안내'),
          ),
        ],
      ),
    );
  }
}