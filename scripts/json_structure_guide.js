// ============================================
// JSON 구조 이해하기: 배열 vs 객체
// ============================================

console.log('=== 1. 배열 vs 객체 ===\n');

// 배열: 대괄호 []
const 배열 = [1, 2, 3];
console.log('배열:', 배열);
console.log('배열[0]:', 배열[0]);  // 1
console.log('배열.length:', 배열.length);  // 3
console.log('배열.data:', 배열.data);  // undefined (배열에는 data 속성 없음!)

// 객체: 중괄호 {}
const 객체 = { name: "안나", age: 20 };
console.log('\n객체:', 객체);
console.log('객체.name:', 객체.name);  // "안나"
console.log('객체.age:', 객체.age);  // 20
console.log('객체[0]:', 객체[0]);  // undefined (객체는 인덱스 접근 안 됨!)

console.log('\n=== 2. allResults 구조 분석 ===\n');

// allResults의 실제 구조
const allResults = [           // ← 배열 (레벨 1)
  {                            // ← 객체 (레벨 2)
    data: [                    // ← 배열 (레벨 3)
      {                        // ← 객체 (레벨 4)
        student_id: "안나_null",
        filename: "예문 (1).jpg"
      },
      {
        student_id: "수진_null",
        filename: "예문 (2).jpg"
      }
    ]
  }
];

console.log('allResults의 타입:', Array.isArray(allResults) ? '배열' : '객체');
console.log('allResults.length:', allResults.length);  // 1

console.log('\n--- 잘못된 접근 방법 ❌ ---');
console.log('allResults.data:', allResults.data);
// undefined (배열에는 .data 속성이 없음!)

console.log('\n--- 올바른 접근 방법 ✅ ---');
console.log('allResults[0]:', allResults[0]);
// { data: [...] } (첫 번째 요소 = 객체)

console.log('\nallResults[0]의 타입:', Array.isArray(allResults[0]) ? '배열' : '객체');

console.log('\nallResults[0].data:', allResults[0].data);
// [{ student_id: "안나" }, { student_id: "수진" }]

console.log('\nallResults[0].data[0]:', allResults[0].data[0]);
// { student_id: "안나_null", filename: "예문 (1).jpg" }


console.log('\n=== 3. [Object] 표시 이유 ===\n');

// 얕은 출력 (기본)
console.log('기본 출력:', allResults);
// [ { data: [ [Object], [Object] ] } ]  ← 깊이가 깊어서 생략됨

// 깊은 출력 (depth 옵션)
console.log('\n깊은 출력 (depth: null):');
console.log(JSON.stringify(allResults, null, 2));
// 모든 데이터가 완전히 표시됨


console.log('\n=== 4. 올바른 map 사용법 ===\n');

console.log('--- 잘못된 방법 ❌ ---');
try {
  const wrong = allResults.data.map(item => item);
} catch (error) {
  console.log('에러:', error.message);
  // Cannot read properties of undefined (reading 'map')
}

console.log('\n--- 올바른 방법 ✅ ---');
const items = allResults[0].data.map(item => ({
  json: {
    student_id: item.student_id,
    filename: item.filename
  }
}));

console.log('변환 결과:', items.length, '개');
console.log('첫 번째 아이템:', items[0]);


console.log('\n=== 5. 접근 경로 정리 ===\n');

const 접근경로 = {
  'allResults': allResults,
  'allResults의 타입': Array.isArray(allResults) ? '배열' : '객체',
  'allResults.length': allResults.length,

  'allResults[0]': allResults[0],
  'allResults[0]의 타입': Array.isArray(allResults[0]) ? '배열' : '객체',

  'allResults[0].data': allResults[0].data,
  'allResults[0].data의 타입': Array.isArray(allResults[0].data) ? '배열' : '객체',
  'allResults[0].data.length': allResults[0].data.length,

  'allResults[0].data[0]': allResults[0].data[0],
  'allResults[0].data[0]의 타입': Array.isArray(allResults[0].data[0]) ? '배열' : '객체',
};

console.table(접근경로);


console.log('\n=== 6. 시각적 구조도 ===\n');

console.log(`
allResults (배열)
  └─ [0] (객체)
       └─ data (배열)
            ├─ [0] (객체)
            │    ├─ student_id: "안나_null"
            │    └─ filename: "예문 (1).jpg"
            └─ [1] (객체)
                 ├─ student_id: "수진_null"
                 └─ filename: "예문 (2).jpg"

접근 방법:
  allResults -----------> 배열 → [0]으로 접근
  allResults[0] -------> 객체 → .data로 접근
  allResults[0].data --> 배열 → [0], [1]로 접근
  allResults[0].data[0] → 객체 → .student_id로 접근
`);


console.log('\n=== 7. 올바른 jsonConverter.js 코드 ===\n');

console.log(`
// 올바른 코드 ✅
const allResults = [ { data: [...] } ];

console.log('원본데이터:', allResults);

const items = allResults[0].data.map(item => ({
  //                    ↑↑↑ [0] 추가!
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

console.log('변환된 아이템:', items.length);
return items;
`);


console.log('\n=== 8. 요약 ===\n');
console.log(`
1. allResults는 "배열"이므로 [0]으로 접근
2. allResults[0]은 "객체"이므로 .data로 접근
3. allResults[0].data는 "배열"이므로 .map() 사용 가능
4. [Object]는 console.log의 생략 표시 (실제 데이터는 있음)
5. JSON.stringify()로 전체 구조 확인 가능
`);
