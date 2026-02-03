#!/bin/bash

# 이미지 OCR 테스트 스크립트

IMAGE_FILE="/Users/imseongjin/AutoChecker/example/쓰기 채점_예문 (1).jpg"
N8N_URL="http://localhost:5678"

echo "==================================="
echo "이미지 OCR 테스트"
echo "==================================="
echo ""

# 이미지 파일 존재 확인
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ 이미지 파일을 찾을 수 없습니다: $IMAGE_FILE"
    exit 1
fi

echo "이미지 파일: $IMAGE_FILE"
echo "Endpoint: $N8N_URL/webhook-test/image-ocr"
echo ""
echo "텍스트 추출 중..."
echo ""

# HTTP Request 기반 OCR 테스트
curl -X POST "$N8N_URL/webhook-test/image-ocr" \
  -F "data=@$IMAGE_FILE" \
  -H "Content-Type: multipart/form-data" \
  -o output_image_ocr.json

if [ $? -eq 0 ]; then
    echo "✅ 성공! 결과가 output_image_ocr.json에 저장되었습니다."
    echo ""
    echo "--- 추출된 텍스트 미리보기 ---"

    # jq가 설치되어 있으면 JSON 파싱
    if command -v jq &> /dev/null; then
        cat output_image_ocr.json | jq -r '.extracted_text' | head -30
        echo ""
        echo "--- 메타데이터 ---"
        cat output_image_ocr.json | jq '.metadata'
    else
        # jq가 없으면 raw 출력
        cat output_image_ocr.json
    fi
    echo ""
else
    echo "❌ 실패! n8n이 실행 중인지, 워크플로우가 활성화되어 있는지 확인하세요."
    echo ""
fi

echo "==================================="
echo "테스트 완료!"
echo "전체 결과는 output_image_ocr.json에서 확인하세요."
echo "==================================="