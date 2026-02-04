# n8n 워크플로우 아키텍처

## 전체 흐름도

```
┌─────────────────┐
│  이미지 업로드  │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  OpenAI Vision  │
│  (OCR 추출)     │
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────┐
│  student_answers 테이블에 저장  │  ← 원본 답안 저장
│  (answer_id 반환)               │
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────┐
│  AI Agent       │
│  (채점 수행)    │
└────────┬────────┘
         │
         ↓
    ┌───┴───┐
    │       │
    ↓       ↓
┌──────┐ ┌──────────┐
│ 점수 │ │ 오류상세 │
└──┬───┘ └────┬─────┘
   │          │
   ↓          ↓
grading_    detected_
results      errors
```

## 테이블별 역할

### 1. student_answers (학생 답안)
- **용도**: OCR로 추출한 원본 텍스트 저장
- **입력 시점**: OCR 완료 직후
- **데이터**: 학생ID, 파일명, 답안 텍스트, 글자수 등

### 2. evaluation_criteria (평가 기준)
- **용도**: 채점 기준 정의 (정적 데이터)
- **입력 시점**: DB 초기 설정 시 (schema.sql에 이미 포함)
- **데이터**: 문법 40점, 어휘 30점 등의 기준
- **주의**: 워크플로우에서 **읽기만** 하고 쓰지 않음!

### 3. error_types (오류 유형)
- **용도**: 오류 코드 정의 (정적 데이터)
- **입력 시점**: DB 초기 설정 시 (schema.sql에 이미 포함)
- **데이터**: G01=조사 오류, G02=시제 오류 등
- **주의**: 워크플로우에서 **읽기만** 하고 쓰지 않음!

### 4. grading_results (채점 결과)
- **용도**: AI가 채점한 점수와 등급 저장
- **입력 시점**: AI Agent 채점 완료 후
- **데이터**: 총점, 문법점수, 어휘점수, 등급, 피드백 등

### 5. detected_errors (검출된 오류)
- **용도**: AI가 발견한 개별 오류들 저장
- **입력 시점**: AI Agent 채점 완료 후
- **데이터**: 오류 코드, 원문, 수정안, 설명, 감점 등

## 워크플로우 노드 구성

### Option A: 순차 처리 (추천)

```
1. 배치 이미지 업로드 (Webhook)
   ↓
2. 파일 분리 (Code)
   ↓
3. Split In Batches
   ↓ [loop]
4. 이미지 준비 (Code)
   ↓
5. OpenAI Vision API (OCR)
   ↓
6. PostgreSQL Insert (student_answers에 저장)
   ↓
7. AI Agent 채점 호출
   ↓
8. 채점 결과 파싱 (Code)
   ↓
9. PostgreSQL Insert (grading_results에 저장)
   ↓
10. 오류 목록 파싱 (Code)
   ↓
11. PostgreSQL Insert (detected_errors에 저장)
   ↓
12. 다음 배치로 (→ Split In Batches)
   ↓ [done]
13. 최종 결과 통합
   ↓
14. 결과 반환
```

### Option B: 병렬 처리

```
3. Split In Batches
   ↓ [loop]
4~6. OCR → student_answers 저장
   ↓
   ┌───┴───┐
   │       │
   ↓       ↓
채점      다음 OCR 시작 (병렬)
7~11
```

## 예시 데이터 흐름

### 1단계: OCR 결과 → student_answers

**입력 (OCR 결과)**:
```json
{
  "extracted_text": "저는 안나입니다\n제 고향은 독일 뮌헨인데...",
  "char_count": 205,
  "word_count": 45
}
```

**DB 저장** (student_answers):
```sql
INSERT INTO student_answers (student_id, filename, answer_text, ...)
VALUES ('안나_001', '예문1.jpg', '저는 안나입니다...', ...);
-- 반환: answer_id = 2
```

### 2단계: AI 채점 → grading_results

**AI Agent 입력**:
```json
{
  "answer_id": 2,
  "answer_text": "저는 안나입니다\n제 고향은 독일 뮌헨인데..."
}
```

**AI Agent 출력**:
```json
{
  "total_score": 85.5,
  "grammar_score": 37.0,
  "vocabulary_score": 28.0,
  "content_score": 15.0,
  "organization_score": 5.5,
  "grade": "B+",
  "pass_fail": true,
  "errors": [
    {
      "error_code": "G01",
      "original": "독일 뮌헨",
      "corrected": "독일의 뮌헨",
      "explanation": "관형격 조사 누락",
      "points_deducted": -0.5,
      "position": 25
    },
    {
      "error_code": "S02",
      "original": "맥주가유명하",
      "corrected": "맥주가 유명하",
      "explanation": "띄어쓰기 오류",
      "points_deducted": -0.1,
      "position": 78
    }
  ]
}
```

**DB 저장** (grading_results):
```sql
INSERT INTO grading_results
(answer_id, total_score, grammar_score, vocabulary_score, content_score,
 organization_score, grade, pass_fail, grading_model, overall_feedback)
VALUES
(2, 85.5, 37.0, 28.0, 15.0, 5.5, 'B+', true, 'gpt-4o', '전반적으로 우수...');
-- 반환: grading_id = 1
```

### 3단계: 오류 상세 → detected_errors

**DB 저장** (detected_errors, 반복):
```sql
INSERT INTO detected_errors
(grading_id, error_code, original_text, corrected_text, explanation, points_deducted, error_position)
VALUES
(1, 'G01', '독일 뮌헨', '독일의 뮌헨', '관형격 조사 누락', -0.5, 25),
(1, 'S02', '맥주가유명하', '맥주가 유명하', '띄어쓰기 오류', -0.1, 78);
```

## n8n 노드 상세

### PostgreSQL 노드 설정

#### 노드 1: student_answers 저장
```javascript
// Operation: Insert
// Table: student_answers
// Columns:
{
  "student_id": "={{ $json.student_id }}",
  "filename": "={{ $json.filename }}",
  "answer_text": "={{ $json.extracted_text }}",
  "char_count": "={{ $json.char_count }}",
  "word_count": "={{ $json.word_count }}",
  "ocr_model": "gpt-4o"
}
// Return Fields: answer_id
```

#### 노드 2: grading_results 저장
```javascript
// Operation: Insert
// Table: grading_results
// Columns:
{
  "answer_id": "={{ $json.answer_id }}",
  "total_score": "={{ $json.total_score }}",
  "grammar_score": "={{ $json.grammar_score }}",
  "vocabulary_score": "={{ $json.vocabulary_score }}",
  "content_score": "={{ $json.content_score }}",
  "organization_score": "={{ $json.organization_score }}",
  "grade": "={{ $json.grade }}",
  "pass_fail": "={{ $json.pass_fail }}",
  "grading_model": "gpt-4o",
  "overall_feedback": "={{ $json.feedback }}"
}
// Return Fields: grading_id
```

#### 노드 3: detected_errors 저장 (Loop)
```javascript
// 이전 노드에서 errors 배열을 분리한 후
// Operation: Insert
// Table: detected_errors
// Columns:
{
  "grading_id": "={{ $json.grading_id }}",
  "error_code": "={{ $json.error_code }}",
  "original_text": "={{ $json.original }}",
  "corrected_text": "={{ $json.corrected }}",
  "explanation": "={{ $json.explanation }}",
  "points_deducted": "={{ $json.points_deducted }}",
  "error_position": "={{ $json.position }}"
}
```

## 중요 포인트

### ✅ 해야 할 것

1. **student_answers 먼저 저장** → `answer_id` 받기
2. `answer_id`를 AI Agent에 전달
3. **grading_results 저장** → `grading_id` 받기
4. `grading_id`와 오류 목록으로 **detected_errors 여러 개 저장**

### ❌ 하지 말아야 할 것

1. `evaluation_criteria` 테이블에 채점 결과 저장 (X)
2. `error_types` 테이블에 오류 저장 (X)
3. 이 두 테이블은 **읽기 전용**으로 참조만 할 것

## 다음 단계

1. 기존 OCR 워크플로우에 PostgreSQL 노드 3개 추가
2. AI Agent 워크플로우 생성 (채점 로직)
3. 두 워크플로우 연결
4. 테스트 실행