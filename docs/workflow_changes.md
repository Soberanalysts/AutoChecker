# AutoChecker 워크플로우 변경 사항

## 기존 워크플로우 (AutoChecker.json)

### OCR 파트
```
배치 이미지 업로드
  → 파일 분리
  → Split In Batches
  → 이미지 준비
  → OpenAI Vision OCR
  → 결과 파싱
  → (루프백)
  → 결과 통합
  → 최종 결과 포맷
  → 결과 반환
```

### 채점 파트 (분리됨)
```
텍스트 입력
  → 프롬프트 준비
  → AI Agent
  → 결과 파싱
  → 결과 반환
```

**문제점:**
- OCR과 채점이 분리되어 있음
- DB 저장 기능 없음
- 수동으로 OCR 결과를 채점 API에 전달해야 함

---

## 새 워크플로우 (AutoChecker_with_DB.json)

### 전체 통합 흐름

```
배치 이미지 업로드
  ↓
파일 분리
  ↓
Split In Batches ←──────────────┐ (루프)
  ↓ [loop]                      │
이미지 준비                       │
  ↓                              │
OpenAI Vision OCR                │
  ↓                              │
OCR 결과 파싱 (학생 이름 추출)    │
  ↓                              │
✨ DB: student_answers 저장       │
  ↓                              │
채점 준비 (answer_id 전달)        │
  ↓                              │
프롬프트 생성                     │
  ↓                              │
AI 채점 (GPT-4o)                 │
  ↓                              │
채점 결과 파싱                    │
  ↓                              │
✨ DB: grading_results 저장       │
  ↓                              │
오류 목록 분리                    │
  ↓                              │
오류 있는지 확인 (IF)             │
  ↓ [true]          ↓ [false]   │
병합          ✨ DB: errors 저장  │
  └────────────┴─────────────────┘
  ↓ [done]
결과 통합
  ↓
최종 결과
  ↓
결과 반환
```

---

## 추가된 노드 (✨ 표시)

### 1. **DB: 답안 저장** (PostgreSQL Insert)
- **위치**: OCR 결과 파싱 → 채점 준비 사이
- **테이블**: `student_answers`
- **저장 데이터**:
  - `student_id`: 자동 추출 (예: `안나_001`)
  - `filename`: 원본 파일명
  - `answer_text`: OCR 추출 텍스트
  - `char_count`, `word_count`: 통계
  - `ocr_model`: `gpt-4o`
  - `extracted_at`: 추출 시간
- **반환**: `answer_id` (다음 단계에서 사용)

### 2. **채점 준비** (Code)
- **역할**: `answer_id`를 다음 노드로 전달
- **출력**: `answer_id`, `student_id`, `answer_text`

### 3. **프롬프트 생성** (Code)
- **역할**: AI 채점용 프롬프트 생성
- **변경점**:
  - 기존 하드코딩된 프롬프트 → 동적 생성
  - JSON 응답 형식 명확화
  - `response_format: { type: 'json_object' }` 사용

### 4. **AI 채점** (HTTP Request)
- **역할**: OpenAI GPT-4o로 채점
- **변경점**:
  - AI Agent → HTTP Request로 변경 (더 간단)
  - `response_format: json_object` 사용

### 5. **채점 결과 파싱** (Code)
- **역할**: AI 응답 JSON 파싱
- **출력**: 점수, 등급, 오류 목록

### 6. **DB: 채점 결과 저장** (PostgreSQL Insert)
- **테이블**: `grading_results`
- **저장 데이터**:
  - `answer_id`: FK (student_answers)
  - `total_score`, `grammar_score`, `vocabulary_score` 등
  - `grade`: A+, A, B+ 등
  - `pass_fail`: true/false
  - `overall_feedback`: 전체 피드백
  - `grading_model`: `gpt-4o`
- **반환**: `grading_id` (다음 단계에서 사용)

### 7. **오류 목록 분리** (Code)
- **역할**: errors 배열을 개별 아이템으로 분리
- **출력**: 각 오류마다 1개 아이템 생성

### 8. **오류 있는지 확인** (IF)
- **역할**: 오류가 있으면 DB 저장, 없으면 스킵
- **조건**: `no_errors === true`

### 9. **DB: 오류 저장** (PostgreSQL Insert)
- **테이블**: `detected_errors`
- **저장 데이터**:
  - `grading_id`: FK (grading_results)
  - `error_code`: G01, G02, V01 등
  - `original_text`: 오류 원문
  - `corrected_text`: 수정안
  - `explanation`: 설명
  - `points_deducted`: 감점 (-0.5 등)
  - `error_position`: 문자 위치

### 10. **병합** (Code)
- **역할**: IF 노드의 두 경로 병합
- **출력**: 배치 완료 신호

---

## 주요 개선 사항

### 1. 완전 자동화
- **이전**: OCR → 수동 복사 → 채점 API 호출
- **이후**: 이미지 업로드 → 자동 OCR → 자동 채점 → DB 저장

### 2. 학생 이름 자동 추출
```javascript
// "저는 XXX라고 합니다" 패턴에서 이름 추출
const nameMatch = extractedText.match(/저는\s+(\S+?)(?:라고|이라고)\s+합니다/);
const studentName = nameMatch ? nameMatch[1] : null;

// student_id 생성: "안나_001", "수진_002" 등
const studentId = studentName
  ? `${studentName}_${String(batchIndex).padStart(3, '0')}`
  : `student_${String(batchIndex).padStart(3, '0')}`;
```

### 3. 외래 키 관계 유지
```
student_answers (answer_id)
        ↓ FK
grading_results (grading_id)
        ↓ FK
detected_errors
```

### 4. JSON 응답 안정화
```javascript
// OpenAI response_format 사용
{
  "response_format": { "type": "json_object" }
}
```

이전에는 마크다운 코드 블록(```json)을 파싱해야 했지만, 이제는 순수 JSON 반환

---

## 사용 방법

### 1. PostgreSQL Credential 설정

n8n에서:
1. **Credentials** → **Add credential** → **PostgreSQL**
2. 다음 정보 입력:
   - Host: `localhost`
   - Database: `autochecker`
   - User: `postgres`
   - Password: (비밀번호)
   - Port: `5432`
3. **Save**

### 2. Workflow Import

1. n8n에서 **Import from File** 선택
2. `AutoChecker_with_DB.json` 파일 선택
3. 모든 PostgreSQL 노드에서 credential 연결:
   - `DB: 답안 저장`
   - `DB: 채점 결과 저장`
   - `DB: 오류 저장`

### 3. 테스트 실행

```bash
# 5개 이미지 업로드
/opt/anaconda3/bin/python3 batch_upload_multipart.py

# 또는 curl
curl -X POST http://localhost:5678/webhook/image-ocr-batch \
  -F "data=@example/쓰기 채점_예문 (1).jpg" \
  -F "data=@example/쓰기 채점_예문 (2).jpg" \
  -F "data=@example/쓰기 채점_예문 (3).jpg" \
  -F "data=@example/쓰기 채점_예문 (4).jpg" \
  -F "data=@example/쓰기 채점_예문 (5).jpg"
```

### 4. 결과 확인

```bash
# DB 데이터 확인
./scripts/view_db_data.sh

# 또는 직접 쿼리
psql -U postgres -d autochecker -c "
SELECT
  sa.student_id,
  gr.total_score,
  gr.grade,
  gr.pass_fail,
  COUNT(de.detection_id) as error_count
FROM student_answers sa
LEFT JOIN grading_results gr ON sa.answer_id = gr.answer_id
LEFT JOIN detected_errors de ON gr.grading_id = de.grading_id
GROUP BY sa.student_id, gr.total_score, gr.grade, gr.pass_fail
ORDER BY sa.created_at DESC;
"
```

---

## 예상 결과

### student_answers 테이블
| answer_id | student_id | filename | answer_text | char_count |
|-----------|------------|----------|-------------|------------|
| 1 | 안나_001 | 예문 (1).jpg | 저는 안나라고 합니다... | 205 |
| 2 | 수진_002 | 예문 (2).jpg | 저는 수진라고 합니다... | 184 |

### grading_results 테이블
| grading_id | answer_id | total_score | grade | pass_fail |
|------------|-----------|-------------|-------|-----------|
| 1 | 1 | 85.5 | A | true |
| 2 | 2 | 78.0 | B | true |

### detected_errors 테이블
| detection_id | grading_id | error_code | original_text | corrected_text | points_deducted |
|--------------|------------|------------|---------------|----------------|-----------------|
| 1 | 1 | G01 | 독일 뮌헨 | 독일의 뮌헨 | -0.5 |
| 2 | 1 | S02 | 맥주가유명하 | 맥주가 유명하 | -0.1 |

---

## 문제 해결

### PostgreSQL 연결 오류
```
Error: connect ECONNREFUSED 127.0.0.1:5432
```
→ PostgreSQL이 실행 중인지 확인: `brew services list`

### Credential 오류
```
Error: No credentials found
```
→ 모든 PostgreSQL 노드에 credential 연결 확인

### JSON 파싱 오류
```
Error: Unexpected token in JSON
```
→ AI 응답에 `response_format: json_object` 설정 확인

---

## 다음 단계

1. ✅ OCR + 채점 통합 완료
2. ✅ DB 저장 기능 추가 완료
3. ⏳ 웹 UI 개발 (결과 조회, 통계)
4. ⏳ 배치 처리 최적화 (병렬 처리)
5. ⏳ 오류 피드백 개선 (예시 문장 추가)