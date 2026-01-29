# 빠른 시작 가이드

## 5분 안에 시작하기

### 방법 1: Docker Compose 사용 (가장 쉬움)

```bash
# 1. 환경 변수 설정
cp .env.example .env
# .env 파일을 열어 OPENAI_API_KEY를 입력하세요

# 2. Docker Compose 실행
docker-compose up -d

# 3. 데이터베이스 초기화
docker exec -it korean-grading-n8n sh
pip install psycopg2-binary openai python-dotenv
python /workflows/../scripts/setup_database.py
exit

# 4. n8n 접속
# 브라우저에서 http://localhost:5678 열기
# ID: admin, PW: admin (또는 .env에서 설정한 값)
```

### 방법 2: 로컬 설치

```bash
# 1. PostgreSQL + pgvector 설치
# macOS
brew install postgresql@15 pgvector

# Ubuntu
sudo apt install postgresql postgresql-contrib
sudo apt install postgresql-15-pgvector

# 2. PostgreSQL 시작
brew services start postgresql@15  # macOS
sudo systemctl start postgresql     # Ubuntu

# 3. 데이터베이스 생성
createdb korean_grading
psql korean_grading -c "CREATE EXTENSION vector;"

# 4. Python 환경 설정
python3 -m venv venv
source venv/bin/activate
pip install -r scripts/requirements.txt

# 5. 환경 변수 설정
cp .env.example .env
# .env 파일에 API 키와 DB 정보 입력

# 6. 데이터베이스 초기화
python scripts/setup_database.py

# 7. n8n 설치 및 실행
npm install -g n8n
n8n start
```

## n8n 워크플로우 설정

1. 브라우저에서 `http://localhost:5678` 접속
2. 로그인 (초기 계정 생성)
3. 왼쪽 메뉴에서 "Workflows" 클릭
4. "Import from File" 클릭
5. `n8n-workflows/grading_workflow.json` 선택
6. 크레덴셜 설정:
   - PostgreSQL: DB 연결 정보 입력
   - OpenAI: API 키 입력

## 테스트 실행

```bash
# 1. 테스트 스크립트 실행
python scripts/test_grading.py

# 또는 직접 API 호출
curl -X POST http://localhost:5678/webhook/submit-answer \
  -H "Content-Type: application/json" \
  -d '{
    "student_number": "20240001",
    "student_name": "김민준",
    "assignment_id": 1,
    "extracted_text": "안녕하세요. 저는 다니엘이라고 합니다. 제 고향은 베트남 하노이인데..."
  }'
```

## 체크리스트

- [ ] PostgreSQL 실행 확인: `pg_isready`
- [ ] pgvector 확장 설치 확인: `psql korean_grading -c "SELECT * FROM pg_extension WHERE extname = 'vector';"`
- [ ] 환경 변수 설정 확인: `.env` 파일에 `OPENAI_API_KEY` 입력
- [ ] 데이터베이스 초기화 완료: `python scripts/setup_database.py`
- [ ] n8n 실행 확인: `http://localhost:5678` 접속
- [ ] n8n 워크플로우 임포트 완료
- [ ] PostgreSQL 크레덴셜 설정 완료
- [ ] OpenAI 크레덴셜 설정 완료

## 문제 해결

### PostgreSQL 연결 오류
```bash
# PostgreSQL 실행 확인
pg_isready

# PostgreSQL 재시작
brew services restart postgresql@15  # macOS
sudo systemctl restart postgresql     # Ubuntu
```

### pgvector 설치 오류
```bash
# 수동 설치
psql korean_grading -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

### n8n 크레덴셜 오류
1. n8n 웹 인터페이스에서 "Credentials" 메뉴 클릭
2. 각 크레덴셜 클릭 후 정보 입력
3. "Test" 버튼으로 연결 테스트

### OpenAI API 오류
- API 키 유효성 확인
- 사용량 한도 확인
- 모델 접근 권한 확인 (gpt-4o 필요)

## 다음 단계

1. 실제 학생 답안 이미지로 테스트
2. OCR 노드 설정 (Google Vision API 또는 Naver Clova OCR)
3. 교사 피드백 기능 활성화
4. 웹 UI 개발 (선택)

## 유용한 명령어

```bash
# DB 접속
psql korean_grading

# 학생 목록 확인
psql korean_grading -c "SELECT * FROM students;"

# 채점 결과 확인
psql korean_grading -c "SELECT s.student_name, g.total_score FROM grading_results g JOIN student_submissions ss ON g.submission_id = ss.submission_id JOIN students s ON ss.student_id = s.student_id;"

# n8n 로그 확인
docker logs korean-grading-n8n  # Docker 사용 시

# DB 백업
pg_dump korean_grading > backup.sql

# DB 복원
psql korean_grading < backup.sql
```
