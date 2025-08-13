import 'package:flutter/material.dart';
import '../services/openai_service.dart';

// 메시지 데이터 모델
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final OpenAIService _openAIService = OpenAIService();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController(); // ScrollController 추가

  @override
  void initState() {
    super.initState();
    // 초기 웰컴 메시지
    _addMessage('안녕하세요🔥🔥 RE:POINT 서비스에 대해 궁금한 점을 무엇이든 물어보세요.😊 예) 영수증 포인트 적립 방법 알려줘', isUser: false, delay: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose(); // dispose 추가
    super.dispose();
  }

  // 메시지 리스트에 메시지 추가 (애니메이션과 함께)
  void _addMessage(String text, {required bool isUser, Duration delay = Duration.zero}) {
    Future.delayed(delay, () {
      if (_listKey.currentState != null) {
        _messages.add(ChatMessage(text: text, isUser: isUser));
        _listKey.currentState!.insertItem(_messages.length - 1, duration: const Duration(milliseconds: 400));
        // 스크롤을 맨 아래로 이동
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  // 사용자가 메시지를 전송했을 때 호출
  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = text;
    _textController.clear();
    setState(() {
      _isLoading = true;
    });

    _addMessage(userMessage, isUser: true);

    // 로딩 인디케이터 추가
    _addMessage('...', isUser: false);

    try {
      final response = await _openAIService.getChatCompletion(userMessage, _messages);
      // '...' 메시지 제거
      setState(() {
        _messages.removeAt(_messages.length - 1); // 마지막 메시지 제거
        _listKey.currentState!.removeItem(_messages.length, (context, animation) => const SizedBox.shrink());
      });
      _addMessage(response, isUser: false);
    } catch (e) {
      // 에러 처리
      setState(() {
        _messages.removeAt(_messages.length - 1); // 마지막 메시지 제거
        _listKey.currentState!.removeItem(_messages.length, (context, animation) => const SizedBox.shrink());
      });
      _addMessage('죄송합니다, 오류가 발생했어요. 다시 시도해주세요.', isUser: false);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF),
      appBar: AppBar(
        title: const Text('AI 상담원', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              controller: _scrollController, // ScrollController 연결
              reverse: false,
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
              initialItemCount: _messages.length,
              itemBuilder: (context, index, animation) {
                return _buildAnimatedMessageItem(_messages[index], animation);
              },
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildAnimatedMessageItem(ChatMessage message, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: _buildMessageItem(message),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    // '...' 로딩 메시지일 경우
    if (message.text == '...' && !message.isUser) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    const userBubbleColor = Color(0xFF5E2AD7);
    const botBubbleColor = Colors.white;

    final isUser = message.isUser;
    final crossAxisAlignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? userBubbleColor : botBubbleColor;
    final textColor = isUser ? Colors.white : Colors.black87;
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(8), // 꼬리 부분 둥글기 조정
            topRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(8), // 꼬리 부분 둥글기 조정
            topLeft: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: [
                if (!isUser)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 16.0, height: 1.4), // 글자 크기 조정
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -3), // changes position of shadow
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 12.0,
        top: 12.0,
        bottom: MediaQuery.of(context).padding.bottom + 12.0, // Safe area for bottom
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(
                  hintText: _isLoading ? '응답을 기다리는 중...' : '메시지를 입력하세요',
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16.0),
                enabled: !_isLoading,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Color(0xFF5E2AD7)),
            onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
}