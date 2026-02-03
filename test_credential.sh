#!/bin/bash

# n8n credential 확인 스크립트

echo "==================================="
echo "n8n OpenAI Credential 확인"
echo "==================================="
echo ""

echo "n8n 설정 디렉토리:"
ls -la ~/.n8n/ 2>/dev/null || echo "❌ .n8n 디렉토리가 없습니다"
echo ""

echo "Credential 파일 확인:"
if [ -f ~/.n8n/database.sqlite ]; then
    echo "✅ database.sqlite 파일 존재"
else
    echo "❌ database.sqlite 파일이 없습니다"
fi
echo ""

echo "==================================="
echo "해결 방법:"
echo "==================================="
echo "1. n8n UI에서 'OpenAI Vision API' 노드 열기"
echo "2. Authentication 섹션에서:"
echo "   - Credential Type: OpenAI Api"
echo "   - OpenAi: '수업용인증' 선택"
echo "3. 저장 후 다시 테스트"
echo ""
echo "또는 다음 명령으로 credential 다시 만들기:"
echo "1. n8n UI > Credentials > New Credential"
echo "2. OpenAI API 선택"
echo "3. API Key 입력 및 이름을 '수업용인증'으로 설정"
echo "==================================="