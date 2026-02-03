#!/bin/bash

# 직접 OpenAI API 테스트 (n8n 없이)

IMAGE_FILE="/Users/imseongjin/AutoChecker/example/쓰기 채점_예문 (2).jpg"
OPENAI_API_KEY="${OPENAI_API_KEY}"

echo "==================================="
echo "OpenAI Vision API 직접 테스트"
echo "==================================="
echo ""

# API 키 확인
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ OPENAI_API_KEY 환경변수가 설정되지 않았습니다."
    echo ""
    echo "다음 명령으로 설정하세요:"
    echo "export OPENAI_API_KEY='sk-...'"
    exit 1
fi

# 이미지 파일 확인
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ 이미지 파일을 찾을 수 없습니다: $IMAGE_FILE"
    exit 1
fi

echo "이미지 파일: $IMAGE_FILE"
echo "파일 크기: $(du -h "$IMAGE_FILE" | cut -f1)"
echo ""

# Base64 인코딩
echo "1. 이미지를 Base64로 인코딩 중..."
IMAGE_BASE64=$(base64 -i "$IMAGE_FILE")
echo "   Base64 길이: ${#IMAGE_BASE64} 문자"
echo ""

# OpenAI API 호출
echo "2. OpenAI Vision API 호출 중..."
echo ""

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d @- << EOF
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "이 이미지에 있는 모든 텍스트를 정확하게 추출해주세요. 한글, 영어, 숫자 모두 포함해서 원본 그대로 추출하세요. 추가 설명 없이 텍스트만 반환하세요."
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,$IMAGE_BASE64"
          }
        }
      ]
    }
  ],
  "max_tokens": 4096,
  "temperature": 0
}
EOF
)

# 결과 저장
echo "$RESPONSE" > /tmp/openai_vision_test.json

# 에러 확인
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ API 에러 발생:"
    echo "$RESPONSE" | jq '.error'
    exit 1
fi

# 추출된 텍스트 출력
echo "✅ 성공!"
echo ""
echo "--- 추출된 텍스트 ---"
echo "$RESPONSE" | jq -r '.choices[0].message.content'
echo ""
echo "--- 전체 응답 ---"
echo "결과 파일: /tmp/openai_vision_test.json"
echo ""
echo "사용된 토큰:"
echo "$RESPONSE" | jq '.usage'