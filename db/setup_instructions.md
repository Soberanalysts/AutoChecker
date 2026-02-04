# PostgreSQL 데이터베이스 셋업 가이드

## 방법 1: pgAdmin GUI 사용

### 1단계: 새 데이터베이스 생성

1. **pgAdmin에서 `postgres` 서버 우클릭**
2. `Create` → `Database...` 선택
3. 다음 정보 입력:
   - Database: `autochecker`
   - Owner: `postgres`
   - Encoding: `UTF8`
4. `Save` 클릭

### 2단계: 스키마 실행

1. **왼쪽 트리에서 `autochecker` 데이터베이스 선택**
2. 상단 메뉴에서 `Tools` → `Query Tool` 클릭 (또는 단축키: `Cmd+K`, `Cmd+T`)
3. `/Users/imseongjin/AutoChecker/db/schema.sql` 파일 내용 전체 복사
4. Query Tool에 붙여넣기
5. 상단의 `Execute` 버튼 클릭 (또는 `F5`)

### 3단계: 테이블 확인

1. 왼쪽 트리에서 `autochecker` → `Schemas` → `public` → `Tables` 펼치기
2. 다음 5개 테이블이 보여야 함:
   - `student_answers`
   - `evaluation_criteria`
   - `error_types`
   - `grading_results`
   - `detected_errors`

---

## 방법 2: 터미널에서 실행 (더 빠름)

```bash
# 1. 데이터베이스 생성
psql -U postgres -c "CREATE DATABASE autochecker;"

# 2. 스키마 실행
psql -U postgres -d autochecker -f /Users/imseongjin/AutoChecker/db/schema.sql

# 3. 테이블 확인
psql -U postgres -d autochecker -c "\dt"
```

---

## 방법 3: 자동화 스크립트 (추천)

`/Users/imseongjin/AutoChecker/db/setup_db.sh` 실행:

```bash
chmod +x /Users/imseongjin/AutoChecker/db/setup_db.sh
./db/setup_db.sh
```

---

## 생성될 테이블 구조

### 1. student_answers (학생 답안)
- `answer_id` (PK)
- `student_id`
- `filename`
- `answer_text` (OCR 추출 텍스트)
- `char_count`, `word_count`
- `ocr_model`

### 2. evaluation_criteria (평가 기준)
- `criteria_id` (PK)
- `criteria_name` (문법 정확성, 어휘 적절성 등)
- `max_points`, `weight_percentage`

### 3. error_types (오류 유형)
- `error_code` (PK) - G01, G02, V01 등
- `name_ko`, `name_en`
- `penalty_points` (감점)

### 4. grading_results (채점 결과)
- `grading_id` (PK)
- `answer_id` (FK → student_answers)
- `total_score`, `grade`
- `grammar_score`, `vocabulary_score` 등

### 5. detected_errors (검출된 오류)
- `detection_id` (PK)
- `grading_id` (FK → grading_results)
- `error_code` (FK → error_types)
- `original_text`, `corrected_text`

---

## 샘플 쿼리

### 학생별 채점 결과 조회
```sql
SELECT * FROM student_grading_summary;
```

### 오류 유형별 통계
```sql
SELECT * FROM error_statistics;
```

### 특정 학생의 오류 상세 조회
```sql
SELECT
    sa.student_id,
    et.name_ko as error_type,
    de.original_text,
    de.corrected_text,
    de.points_deducted
FROM student_answers sa
JOIN grading_results gr ON sa.answer_id = gr.answer_id
JOIN detected_errors de ON gr.grading_id = de.grading_id
JOIN error_types et ON de.error_code = et.error_code
WHERE sa.student_id = 'anna_001';
```

---

## 주의사항

1. **데이터베이스 이름**: `autochecker`를 사용하세요 (기본 `postgres` DB 사용 X)
2. **인코딩**: UTF-8 필수 (한글 지원)
3. **백업**: 중요 데이터 생성 후 정기적으로 백업
   ```bash
   pg_dump -U postgres autochecker > backup_$(date +%Y%m%d).sql
   ```