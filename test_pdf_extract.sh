#!/bin/bash

# PDF 텍스트 추출 테스트 스크립트

PDF_FILE="/Users/imseongjin/AutoChecker/2차_진행사항_26029_2시.pdf"
N8N_URL="http://localhost:5678"

echo "==================================="
echo "PDF 텍스트 추출 테스트"
echo "==================================="
echo ""

# 1. 기본 버전 테스트 (AI 없음)
echo "1. 기본 버전 테스트 (빠른 추출)..."
echo "   Endpoint: $N8N_URL/webhook/pdf-extract"
echo ""

curl -X POST "$N8N_URL/webhook/pdf-extract" \
  -F "data=@$PDF_FILE" \
  -H "Content-Type: multipart/form-data" \
  -o output_basic.json

if [ $? -eq 0 ]; then
    echo "✅ 성공! 결과가 output_basic.json에 저장되었습니다."
    echo ""
    echo "--- 결과 미리보기 ---"
    cat output_basic.json | jq -r '.text' | head -20
    echo "..."
    echo ""
else
    echo "❌ 실패! n8n이 실행 중인지, 워크플로우가 활성화되어 있는지 확인하세요."
    echo ""
fi

echo "==================================="
echo ""

# 2. AI 강화 버전 테스트
echo "2. AI 강화 버전 테스트 (정리된 텍스트)..."
echo "   Endpoint: $N8N_URL/webhook/pdf-extract-ai"
echo ""

curl -X POST "$N8N_URL/webhook/pdf-extract-ai" \
  -F "data=@$PDF_FILE" \
  -H "Content-Type: multipart/form-data" \
  -o output_ai.json

if [ $? -eq 0 ]; then
    echo "✅ 성공! 결과가 output_ai.json에 저장되었습니다."
    echo ""
    echo "--- 정리된 텍스트 미리보기 ---"
    cat output_ai.json | jq -r '.cleaned_text' | head -20
    echo "..."
    echo ""
else
    echo "❌ 실패! AI 모델이 연결되어 있는지 확인하세요."
    echo ""
fi

echo "==================================="
echo "테스트 완료!"
echo "전체 결과는 output_basic.json, output_ai.json에서 확인하세요."
echo "==================================="