#!/bin/bash

# 테스트 답안 1: 좋은 답안
echo "=== 테스트 1: 좋은 답안 ==="
curl -X POST http://localhost:5678/webhook-test/grade \
  -H "Content-Type: application/json" \
  -d '{
    "answer": "안녕하세요. 저는 다니엘이라고 합니다. 제 고향은 베트남 하노이인데 베트남의 북쪽에 있습니다. 하노이는 크지 않지만 사람들이 많고 활기찬 도시입니다. 제가 소개하고 싶은 곳은 호안끼엠 호수인데 경치가 아주 좋습니다. 제 고향은 쌀국수가 유명하지만 너무 맵지 않습니다. 저는 한국 친구들에게 제 고향을 소개하려고 이 글을 씁니다."
  }' | jq '.'

echo -e "\n\n=== 테스트 2: 짧은 답안 (문법 부족) ==="
curl -X POST http://localhost:5678/webhook-test/grade \
  -H "Content-Type: application/json" \
  -d '{
    "answer": "안녕하세요. 저는 마리아입니다. 제 고향은 프랑스 파리입니다. 파리는 아름다운 도시입니다."
  }' | jq '.'