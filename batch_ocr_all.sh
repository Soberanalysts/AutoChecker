#!/bin/bash

# 5개 이미지 파일 일괄 OCR 처리 및 정리

N8N_URL="http://localhost:5678"
IMAGE_DIR="/Users/imseongjin/AutoChecker/example"
OUTPUT_DIR="/Users/imseongjin/AutoChecker/ocr_results"

echo "==================================="
echo "이미지 OCR 일괄 처리"
echo "==================================="
echo ""

# 출력 디렉토리 생성
mkdir -p "$OUTPUT_DIR"

# 5개 파일 배열
FILES=(
  "쓰기 채점_예문 (1).jpg"
  "쓰기 채점_예문 (2).jpg"
  "쓰기 채점_예문 (3).jpg"
  "쓰기 채점_예문 (4).jpg"
  "쓰기 채점_예문 (5).jpg"
)

# 각 파일 처리
for i in "${!FILES[@]}"; do
  FILE="${FILES[$i]}"
  NUM=$((i + 1))

  echo "[$NUM/5] 처리 중: $FILE"

  # OCR 실행
  curl -s -X POST "$N8N_URL/webhook-test/image-ocr" \
    -F "data=@$IMAGE_DIR/$FILE" \
    -H "Content-Type: multipart/form-data" \
    -o "$OUTPUT_DIR/result_$NUM.json"

  if [ $? -eq 0 ]; then
    echo "  ✅ OCR 완료: result_$NUM.json"
  else
    echo "  ❌ OCR 실패"
  fi

  # API 과부하 방지를 위한 딜레이
  sleep 2
done

echo ""
echo "==================================="
echo "결과 정리 중..."
echo "==================================="

# JSON 파일들을 하나로 합치고 정리
cat > "$OUTPUT_DIR/all_results.json" << 'EOF'
{
  "students": [
EOF

for i in {1..5}; do
  if [ -f "$OUTPUT_DIR/result_$i.json" ]; then
    echo "    {" >> "$OUTPUT_DIR/all_results.json"
    echo "      \"student_id\": $i," >> "$OUTPUT_DIR/all_results.json"
    echo "      \"image_file\": \"쓰기 채점_예문 ($i).jpg\"," >> "$OUTPUT_DIR/all_results.json"

    # jq로 extracted_text 추출
    if command -v jq &> /dev/null; then
      TEXT=$(jq -r '.extracted_text' "$OUTPUT_DIR/result_$i.json" 2>/dev/null)
      if [ ! -z "$TEXT" ] && [ "$TEXT" != "null" ]; then
        echo "      \"answer\": $(echo "$TEXT" | jq -Rs .)," >> "$OUTPUT_DIR/all_results.json"
      else
        echo "      \"answer\": \"추출 실패\"," >> "$OUTPUT_DIR/all_results.json"
      fi

      # 메타데이터 추가
      METADATA=$(jq -c '.metadata' "$OUTPUT_DIR/result_$i.json" 2>/dev/null)
      if [ ! -z "$METADATA" ] && [ "$METADATA" != "null" ]; then
        echo "      \"metadata\": $METADATA" >> "$OUTPUT_DIR/all_results.json"
      else
        echo "      \"metadata\": {}" >> "$OUTPUT_DIR/all_results.json"
      fi
    else
      echo "      \"answer\": \"jq 미설치\"," >> "$OUTPUT_DIR/all_results.json"
      echo "      \"metadata\": {}" >> "$OUTPUT_DIR/all_results.json"
    fi

    if [ $i -lt 5 ]; then
      echo "    }," >> "$OUTPUT_DIR/all_results.json"
    else
      echo "    }" >> "$OUTPUT_DIR/all_results.json"
    fi
  fi
done

cat >> "$OUTPUT_DIR/all_results.json" << 'EOF'
  ]
}
EOF

echo ""
echo "✅ 모든 처리 완료!"
echo ""
echo "==================================="
echo "결과 파일:"
echo "==================================="
echo "- 개별 결과: $OUTPUT_DIR/result_1.json ~ result_5.json"
echo "- 통합 결과: $OUTPUT_DIR/all_results.json"
echo ""

# 간단한 요약 출력
if command -v jq &> /dev/null; then
  echo "==================================="
  echo "추출 요약:"
  echo "==================================="

  for i in {1..5}; do
    if [ -f "$OUTPUT_DIR/result_$i.json" ]; then
      CHAR_COUNT=$(jq -r '.metadata.char_count // 0' "$OUTPUT_DIR/result_$i.json" 2>/dev/null)
      WORD_COUNT=$(jq -r '.metadata.word_count // 0' "$OUTPUT_DIR/result_$i.json" 2>/dev/null)
      echo "학생 $i: ${CHAR_COUNT}자, ${WORD_COUNT}단어"
    fi
  done

  echo ""
  echo "전체 결과 확인:"
  echo "cat $OUTPUT_DIR/all_results.json | jq '.'"
fi

echo "==================================="