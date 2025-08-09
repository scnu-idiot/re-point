import 'package:flutter/material.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 챗봇'),
      ),
      body: const Center(
        child: Text(
          'AI 챗봇입니다',
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
    );
  }
}