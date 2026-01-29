# 한국어 쓰기 자동 채점 시스템 (AuthChecker)

서울대 한국어 플러스 2A 교재 기반 쓰기 과제 자동 채점 시스템

## 프로젝트 개요

한국어를 배우는 외국인 학습자의 주관식 답안을 자동으로 채점하여 교사의 채점 시간을 절약하는 시스템입니다.

### 주요 기능

- **OCR 기반 답안 인식**: PDF/JPG 이미지에서 한국어 텍스트 자동 추출
- **RAG 기반 채점**: 벡터 DB를 활용한 채점 기준 검색 및 적용
- **AI 자동 채점**: GPT-4를 활용한 정밀한 채점 및 피드백 생성
- **구조화된 피드백**: 항목별 점수 + 구체적인 개선 제안

### 채점 기준 (총 100점)

| 평가 영역 | 배점 | 평가 요소 |
|---------|------|----------|
| 과제 수행도 | 25점 | 필수 요소 4가지 포함 여부 |
| 핵심 문법 사용 | 30점 | 4가지 핵심 문법 사용 및 정확성 |
| 내용 적절성 | 15점 | 의미 일관성, 정보 충분성 |
| 조직력 | 10점 | 문장 흐름, 연결 표현 |
| 어휘 사용 | 10점 | 기본 어휘 적절성 |
| 문법 정확성 | 10점 | 조사·어미 오류 |

## 시스템 아키텍처

```
[학생 답안 제출 (PDF/JPG)]
         ↓
[OCR - 텍스트 추출]
         ↓
[PostgreSQL DB 저장]
         ↓
[RAG - 채점 기준 검색]
         ↓
[AI 채점 (GPT-4)]
         ↓
[채점 결과 DB 저장]
         ↓
[결과 출력 (점수 + 피드백)]
```

## 기술 스택

- **워크플로우**: n8n
- **데이터베이스**: PostgreSQL + pgvector
- **OCR**: Google Vision API / Naver Clova OCR
- **AI**: OpenAI GPT-4 + Embeddings
- **RAG**: PostgreSQL pgvector (벡터 검색)
- **언어**: Python 3.9+

## 설치 및 실행

### 1. 사전 준비

```bash
# PostgreSQL 설치 (pgvector 확장 포함)
# macOS
brew install postgresql@15
brew install pgvector

# Docker 사용 시
docker run -d \
  --name korean-grading-db \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_DB=korean_grading \
  -p 5432:5432 \
  ankane/pgvector
```

### 2. 프로젝트 설정

```bash
# 저장소 클론 (또는 다운로드)
cd AuthChecker

# Python 가상환경 생성
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install psycopg2-binary openai python-dotenv

# 환경 변수 설정
cp .env.example .env
# .env 파일을 열어 API 키 및 DB 정보 입력
```

### 3. 데이터베이스 초기화

```bash
# DB 스키마 생성 및 채점 기준 데이터 로드
python scripts/setup_database.py
```

### 4. n8n 설치 및 실행

```bash
# n8n 설치
npm install -g n8n

# n8n 실행
n8n start

# 브라우저에서 http://localhost:5678 접속
```

### 5. n8n 워크플로우 임포트

1. n8n 웹 인터페이스 접속
2. "Import from File" 클릭
3. `n8n-workflows/grading_workflow.json` 파일 선택
4. PostgreSQL 및 OpenAI 크레덴셜 설정

## 사용 방법

### API 엔드포인트

```bash
# 학생 답안 제출
curl -X POST http://localhost:5678/webhook/submit-answer \
  -H "Content-Type: application/json" \
  -d '{
    "student_number": "20240001",
    "student_name": "김민준",
    "assignment_id": 1,
    "file": "base64_encoded_image_or_pdf_url"
  }'
```

### 응답 형식

```json
{
  "student_info": {
    "student_number": "20240001",
    "student_name": "김민준"
  },
  "scores": {
    "task_completion": {"score": 23, "max_score": 25},
    "grammar_usage": {"score": 26, "max_score": 30},
    "content_adequacy": {"score": 13, "max_score": 15},
    "organization": {"score": 8, "max_score": 10},
    "vocabulary": {"score": 9, "max_score": 10},
    "grammar_accuracy": {"score": 7, "max_score": 10},
    "total_score": 86
  },
  "feedback": {
    "strengths": [
      "✔ 1과의 핵심 문법을 잘 사용했습니다.",
      "✔ 고향 소개가 구체적입니다."
    ],
    "improvements": [
      "🔸 -지 않다 표현을 한 번 더 연습해 보세요."
    ],
    "overall_comment": "전반적으로 잘 작성했습니다. 조사 사용에 조금 더 주의하면 완벽합니다!"
  }
}
```

## 프로젝트 구조

```
AuthChecker/
├── database/
│   └── schema.sql                 # PostgreSQL 스키마
├── n8n-workflows/
│   └── grading_workflow.json      # n8n 워크플로우
├── grading-criteria/
│   ├── lesson_2A_1.json          # 2A-1과 채점 기준
│   └── grading_prompt.md         # AI 채점 프롬프트
├── scripts/
│   └── setup_database.py         # DB 초기화 스크립트
├── sample-data/                  # 테스트용 샘플 데이터
├── .env.example                  # 환경 변수 템플릿
└── README.md                     # 이 파일
```

## RAG 시스템 설명

### 1. 벡터 데이터베이스

- **pgvector 확장**: PostgreSQL에서 벡터 검색 지원
- **임베딩 모델**: OpenAI `text-embedding-3-small` (1536차원)

### 2. 저장되는 데이터

- 채점 기준 (각 평가 영역별)
- 문법 규칙 (4가지 핵심 문법)
- 모범 답안
- 오류 패턴 및 피드백 템플릿

### 3. 검색 프로세스

1. 학생 답안 텍스트를 벡터로 변환
2. 유사도 검색으로 관련 채점 기준 추출
3. 문법 규칙 매칭
4. AI 프롬프트에 컨텍스트로 삽입

## 커스터마이징

### 새로운 과 추가

1. `grading-criteria/lesson_2A_2.json` 파일 생성
2. 채점 기준 정의
3. `setup_database.py` 실행하여 DB에 로드

### 채점 기준 수정

1. `grading-criteria/lesson_2A_1.json` 수정
2. DB 재로드:
```bash
python scripts/setup_database.py
```

## 문제 해결

### OCR 인식률 개선

- **한국어 특화**: Naver Clova OCR 사용 권장
- **이미지 품질**: 300 DPI 이상 권장
- **전처리**: 이미지 보정 (대비, 기울기 조정)

### DB 연결 오류

```bash
# PostgreSQL 실행 확인
pg_isready

# pgvector 확장 설치 확인
psql -d korean_grading -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
```

### n8n 워크플로우 오류

- Webhook URL 확인
- PostgreSQL 크레덴셜 설정 확인
- OpenAI API 키 유효성 확인

## 향후 계획

- [ ] 다양한 과(lesson) 지원 확장
- [ ] 웹 UI 개발 (학생/교사용)
- [ ] 실시간 채점 대시보드
- [ ] 학습 분석 리포트 생성
- [ ] 다국어 지원 (영어, 중국어 등)

## 라이선스

MIT License

## 기여

이슈 및 PR 환영합니다!

## 문의

프로젝트 관련 문의: [이메일 주소]
