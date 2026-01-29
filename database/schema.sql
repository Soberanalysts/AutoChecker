-- =============================================
-- 한국어 쓰기 자동 채점 시스템 DB 스키마
-- =============================================

-- 1. 학생 정보 테이블
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    student_number VARCHAR(50) UNIQUE NOT NULL,
    student_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 쓰기 과제 정보 테이블
CREATE TABLE assignments (
    assignment_id SERIAL PRIMARY KEY,
    assignment_name VARCHAR(200) NOT NULL,
    lesson_number VARCHAR(20), -- 예: "2A-1과"
    required_sentences INTEGER DEFAULT 6,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. 학생 답안 테이블
CREATE TABLE student_submissions (
    submission_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(student_id),
    assignment_id INTEGER REFERENCES assignments(assignment_id),
    original_file_url TEXT, -- PDF/JPG 원본 파일 경로
    extracted_text TEXT NOT NULL, -- OCR로 추출된 텍스트
    submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' -- pending, graded, reviewed
);

-- 4. 채점 결과 테이블
CREATE TABLE grading_results (
    result_id SERIAL PRIMARY KEY,
    submission_id INTEGER REFERENCES student_submissions(submission_id),

    -- 세부 점수
    task_completion_score DECIMAL(5,2), -- 과제 수행도 (25점)
    grammar_usage_score DECIMAL(5,2), -- 핵심 문법 사용 (30점)
    content_adequacy_score DECIMAL(5,2), -- 내용 적절성 (15점)
    organization_score DECIMAL(5,2), -- 조직력 (10점)
    vocabulary_score DECIMAL(5,2), -- 어휘 사용 (10점)
    grammar_accuracy_score DECIMAL(5,2), -- 문법 정확성 (10점)

    total_score DECIMAL(5,2), -- 총점 (100점)

    -- 세부 분석 결과 (JSON)
    detailed_analysis JSONB,

    -- AI 생성 피드백
    ai_feedback TEXT,

    graded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. 교사 피드백 테이블
CREATE TABLE teacher_feedback (
    feedback_id SERIAL PRIMARY KEY,
    result_id INTEGER REFERENCES grading_results(result_id),
    teacher_comment TEXT,
    adjusted_score DECIMAL(5,2), -- 교사가 조정한 점수 (선택)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. 채점 기준 테이블 (RAG용 - 벡터 저장)
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE grading_criteria (
    criteria_id SERIAL PRIMARY KEY,
    lesson_number VARCHAR(20), -- "2A-1과"
    category VARCHAR(50), -- 'grammar', 'task', 'content', etc.
    criteria_name VARCHAR(200),
    criteria_description TEXT,
    scoring_rule TEXT,
    examples JSONB, -- 모범 답안 및 오류 예시
    embedding vector(1536), -- OpenAI embedding 차원
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. 문법 규칙 테이블
CREATE TABLE grammar_rules (
    rule_id SERIAL PRIMARY KEY,
    lesson_number VARCHAR(20),
    grammar_name VARCHAR(100), -- 예: "명(이)라고 하다"
    grammar_form TEXT,
    usage_description TEXT,
    score_weight INTEGER, -- 배점
    detection_pattern TEXT, -- 정규식 또는 패턴
    examples JSONB,
    embedding vector(1536),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX idx_student_number ON students(student_number);
CREATE INDEX idx_submission_status ON student_submissions(status);
CREATE INDEX idx_grading_submission ON grading_results(submission_id);
CREATE INDEX idx_criteria_lesson ON grading_criteria(lesson_number);
CREATE INDEX idx_grammar_lesson ON grammar_rules(lesson_number);

-- 벡터 검색용 인덱스 (pgvector)
CREATE INDEX idx_criteria_embedding ON grading_criteria USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_grammar_embedding ON grammar_rules USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

COMMENT ON TABLE students IS '학생 기본 정보';
COMMENT ON TABLE assignments IS '쓰기 과제 정보';
COMMENT ON TABLE student_submissions IS '학생이 제출한 답안 원본 및 OCR 텍스트';
COMMENT ON TABLE grading_results IS 'AI 자동 채점 결과';
COMMENT ON TABLE teacher_feedback IS '교사의 추가 피드백 및 점수 조정';
COMMENT ON TABLE grading_criteria IS 'RAG용 채점 기준 (벡터 임베딩 포함)';
COMMENT ON TABLE grammar_rules IS 'RAG용 문법 규칙 (벡터 임베딩 포함)';
