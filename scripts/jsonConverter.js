const allResults = [
  {
    "data": [
      {
        "student_id": "안나_null",
        "filename": "쓰기 채점_예문 (1).jpg",
        "answer_text": "고향을 소개하는 글을 써 보세요.\nwrite a passage introducing your hometown.\n\n저는 안나라고 합니다\n제 고향은 독일 뮌헨인데 남쪽에 있습니다\n소개하고 싶은 곳은 마리엔 광장인데\n성당이 많습니다.\n뮌헨은 맥주가 유명하 고 값도 비싸지\n않습니다. 한국 친구들에게 소개하려고\n이렇게 글을 썼습니다.\n도시는 크지 않지만 아름답습니다.",
        "char_count": 201,
        "word_count": 44,
        "extracted_at": "2026-02-04T07:08:42.180Z",
        "ocr_model": "gpt-4o-2024-08-06",
        "batch_index": null
      },
      {
        "student_id": "수잔_null",
        "filename": "쓰기 채점_예문 (2).jpg",
        "answer_text": "고향을 소개하는 글을 써 보세요.\nWrite a passage introducing your hometown.\n\n저는 수잔라고 합니다.\n제 고향은 스페인 바르셀로나데\n바다 옆에 있습니다.\n카사 비센스는 가우디의 첫 작품인데\n정말 멋집니다.\n거기에 가려면 미리 예약을\n해야 됩니다.\n서울보다 훨씬 크지 않지만\n구경할 것이 많습니다.",
        "char_count": 184,
        "word_count": 41,
        "extracted_at": "2026-02-04T07:08:51.118Z",
        "ocr_model": "gpt-4o-2024-08-06",
        "batch_index": null
      },
      {
        "student_id": "student_null",
        "filename": "쓰기 채점_예문 (3).jpg",
        "answer_text": "고향을 소개하는 글을 써 보세요.\nWrite a passage introducing your hometown.\n\n저는 호아입니다\n제 고향은 하노이라고 합니다.\n\n하노이는 베트남의 수도인데\n매우 덥습니다. 제일 높은 곳은\n랜드마크72인데 멋집니다.\n\n거기 가면 버스를 타고 다시\n지하철은 탑니다.\n하노이는 크지 않만 관광객이 많습니",
        "char_count": 184,
        "word_count": 39,
        "extracted_at": "2026-02-04T07:08:59.028Z",
        "ocr_model": "gpt-4o-2024-08-06",
        "batch_index": null
      },
      {
        "student_id": "student_null",
        "filename": "쓰기 채점_예문 (4).jpg",
        "answer_text": "고향을 소개하는 글을 써 보세요.\nWrite a passage introducing your hometown.\n\n저는 다오입니다.\n제 고향은 다낭입니다. 인데 거의\n베트남의 가운데에 있습니다.\n유명한 휴양지인데 많은 상점과\n볼 거리가 있습니다.\n마사지를 소개하려고 글을 씁니다.",
        "char_count": 155,
        "word_count": 32,
        "extracted_at": "2026-02-04T07:09:08.197Z",
        "ocr_model": "gpt-4o-2024-08-06",
        "batch_index": null
      },
      {
        "student_id": "타오_null",
        "filename": "쓰기 채점_예문 (5).jpg",
        "answer_text": "고향을 소개하는 글을 써 보세요.\nWrite a passage introducing your hometown.\n\n저는 타오라고 합니다.\n제 고향은 푸꾸옥입니다.\n거기 가려고 하면 호치민에서\n비행기를 잡아타야 합니다.\n아름답지만 크지 않습니다.",
        "char_count": 135,
        "word_count": 27,
        "extracted_at": "2026-02-04T07:09:15.443Z",
        "ocr_model": "gpt-4o-2024-08-06",
        "batch_index": null
      }
    ]
  }
]

// 1. 구조 확인
console.log('=== 데이터 구조 분석 ===');
console.log('allResults 타입:', Array.isArray(allResults) ? '배열' : '객체');
console.log('allResults.length:', allResults.length);
console.log('allResults[0] 타입:', Array.isArray(allResults[0]) ? '배열' : '객체');
console.log('전체 구조 (얕게):', allResults);

// 2. 전체 구조 깊게 보기
console.log('\n=== 전체 데이터 (깊게) ===');
console.log(JSON.stringify(allResults, null, 2));

// 3. 올바른 접근: allResults[0].data
console.log('\n=== 데이터 변환 ===');
const items = allResults[0].data.map(item => ({
  //              ↑↑↑ [0] 추가! 배열의 첫 번째 요소(객체)에 접근
  json: {
    student_id: item.student_id,
    filename: item.filename,
    answer_text: item.answer_text,
    char_count: item.char_count,
    word_count: item.word_count,
    ocr_model: item.ocr_model,
    extracted_at: item.extracted_at
  }
}));

console.log('변환된 아이템 수:', items.length);
console.log('첫 번째 아이템:', JSON.stringify(items[0], null, 2));

return items;
