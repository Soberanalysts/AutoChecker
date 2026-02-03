#!/bin/bash

echo "==================================="
echo "n8n 파일 접근 권한 확인"
echo "==================================="
echo ""

echo "1. 홈 디렉토리: $HOME"
echo "2. n8n 파일 디렉토리: $HOME/.n8n-files"
echo "3. 예제 이미지 경로: $HOME/.n8n-files/examples/쓰기 채점_예문 (1).jpg"
echo ""

echo "파일 존재 여부:"
if [ -f "$HOME/.n8n-files/examples/쓰기 채점_예문 (1).jpg" ]; then
    echo "✅ 파일이 존재합니다"
    ls -lh "$HOME/.n8n-files/examples/쓰기 채점_예문 (1).jpg"
else
    echo "❌ 파일이 없습니다"
fi
echo ""

echo "n8n 프로세스 확인:"
ps aux | grep n8n | grep -v grep
echo ""

echo "==================================="
echo "해결 방법:"
echo "1. n8n을 재시작하세요"
echo "2. 또는 워크플로우에서 Webhook 방식 사용"
echo "   (image_ocr_http.json + curl 명령)"
echo "==================================="