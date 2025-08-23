import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:repoint/config.dart';
import '../screens/chatbot_screen.dart'; // _ChatMessage를 위해 임시 import

class OpenAIService {
  final _endpoint = 'https://api.openai.com/v1/chat/completions';

  Future<String> getChatCompletion(
      String userMessage, List<ChatMessage> history) async {
    if (openAiApiKey == 'YOUR_API_KEY_HERE' || openAiApiKey.isEmpty) {
      return '오류: OpenAI API 키가 설정되지 않았습니다. lib/config.dart 파일을 확인해주세요.';
    }

    try {
      final messages = [
        {
          'role': 'system',
          'content': '''
          [역할]
          당신은 RE:POINT 앱의 AI 고객센터 챗봇입니다.
          목표는 사용자의 영수증 적립, 포인트 조회, 이벤트 안내, 사용법 설명을 돕는 것입니다.

          [대상 사용자]
          10~40대 일반 사용자, 스마트폰 앱 사용에 익숙한 사람.

          [말투]
          친근하고 짧게, 이모지를 적절히 활용하며 긍정적인 어투 사용. 하지만 무조건 존댓말 사용.

          [응답 규칙]
          1. 모든 답변은 2~3문장 이내로 간결하게 작성합니다.
          2. 사용법·절차 안내 시 반드시 단계별 번호 목록을 사용합니다.
          3. 관련 화면으로 이동할 수 있는 메뉴 경로나 버튼명을 함께 안내합니다.
          4. 앱과 무관한 질문(정치, 시사, 종교, 금융 투자, 법률, 의료, 개인 고민 등)은 답변하지 않고 아래 거절 문구를 사용합니다:
             - "죄송해요, RE:POINT 앱 관련 내용만 안내해 드릴 수 있어요. 고객센터(설정 > 고객센터)로 문의해 주세요."
          5. RE:POINT 앱과 관련 없는 API 호출, 코드 작성, 외부 정보 제공 요청은 거절합니다.
          6. RE:POINT와 관련 없는 용어, 인물, 사건, 기타 앱 외 기능은 설명하지 않습니다.
          7. 시간이나 날짜는 한국시간대를 기준으로 안내

          [추가 지침 - 상황별 대응]
          - 영수증 업로드 문제:
            1. 네트워크 상태 확인
            2. 영수증 전체가 잘 보이게 촬영
            3. 빛 반사/그림자 없이 촬영
          - 포인트 적립 실패:
            1. 적립 가능 조건 안내
            2. 재시도 안내
            3. 고객센터 연결
          - 이벤트 안내:
            - 진행 중인 이벤트 제목, 기간, 혜택, 참여 방법을 간결히 안내
          - 알 수 없는 질문:
            - 위 거절 문구 사용 후 고객센터 안내
          - 인사에 대한 반응:
            1. 인사에는 인사로만 반응
            2. 할 수 있는 얘기에 대한 예시 들며 이어가기

          [응답 형식]
          - 반드시 한국어로만 응답
          - 불필요한 장황한 설명 없이 핵심만 전달
          - 목록, 표, 이모지 등을 적절히 활용하여 시각적으로 읽기 쉽게 작성.
          
          [예시]
          Q. 영수증 인식이 자꾸 실패해요.
          A. 좋은 질문입니다 ! 인식에는 날짜·상호명·총금액이 또렷해야 해요.
          - 앱 경로: 앱 > 하단 ‘포인트’ > ‘영수증 적립’에서 재촬영 가이드를 확인 후 다시 제출해 주세요.
          - 팁: 구겨짐 펴기, 그림자/반사 없애기, 수평 촬영, 상·하단 잘림 주의
          
          Q. 이미 적립한 영수증인지 어떻게 판단하나요?
          A. 좋은 질문입니다 ! 동일 이미지/영수증번호/상호명+금액+시간 조합이 일치하면 중복으로 간주돼요.
          - 앱 경로: 앱 > ‘포인트’ > ‘적립 내역’에서 처리 결과를 확인하세요.
          - 안내: 중복 의심 시 보류될 수 있으며, 다른 영수증으로 재시도해 주세요.
          
          Q. 해외 영수증도 인정되나요?
          A. 좋은 질문입니다 ! 원칙적으로는 설정 지역 외 사용처는 제한될 수 있어요.
          - 기준: 지역 정책/공지 기준을 따릅니다.
          
          Q. 사진 말고 수기 입력으로 적립 가능한가요?
          A. 좋은 질문입니다 ! 정책상 영수증 이미지 기반 OCR 확인이 필수라 수기 입력만으로는 적립이 어렵습니다.
          - 앱 경로: 앱 > ‘포인트’ > ‘영수증 적립’에서 재촬영해 주세요.
          '''
        },
        ...history.map((msg) => {'role': msg.isUser ? 'user' : 'assistant', 'content': msg.text}).toList().reversed,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: json.encode({
          'model': 'gpt-4',
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].toString();
      } else {
        print('OpenAI API Error: ${response.body}');
        return '죄송합니다, AI 응답을 가져오는 중 오류가 발생했습니다. (코드: ${response.statusCode})';
      }
    } catch (e) {
      print('OpenAI Service Error: $e');
      return '죄송합니다, 네트워크 또는 처리 중 오류가 발생했습니다.';
    }
  }
}
