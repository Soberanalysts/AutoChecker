-- ============================================
-- AutoChecker PostgreSQL Schema
-- 한국어 쓰기 자동 채점 시스템
-- ============================================

-- 1. 학생 답안 테이블
CREATE TABLE student_answers (
    answer_id SERIAL PRIMARY KEY,
    student_id VARCHAR(50) NOT NULL,
    filename VARCHAR(255),
    answer_text TEXT NOT NULL,

    -- OCR 메타데이터
    char_count INTEGER,
    word_count INTEGER,
    extracted_at TIMESTAMP,
    ocr_model VARCHAR(50),

    -- 타임스탬프
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE student_answers IS '학생들의 원본 답안 (OCR 추출 텍스트)';
COMMENT ON COLUMN student_answers.answer_text IS 'OCR로 추출된 학생 답안 원문';

-- student_answers 인덱스
CREATE INDEX idx_student_answers_student_id ON student_answers(student_id);
CREATE INDEX idx_student_answers_created_at ON student_answers(created_at);


-- 2. 평가 기준 테이블
CREATE TABLE evaluation_criteria (
    criteria_id SERIAL PRIMARY KEY,
    criteria_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'grammar', 'vocabulary', 'content', 'organization'

    -- 점수 배분
    max_points DECIMAL(5,2) NOT NULL,
    weight_percentage DECIMAL(5,2), -- 전체 점수에서 차지하는 비율

    -- 설명
    description_ko TEXT,
    description_en TEXT,

    -- 채점 가이드
    scoring_guideline TEXT,

    -- 활성화 상태
    is_active BOOLEAN DEFAULT TRUE,

    -- 타임스탬프
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- 제약조건
    CHECK (weight_percentage >= 0 AND weight_percentage <= 100)
);

COMMENT ON TABLE evaluation_criteria IS '채점 평가 기준 정의';

-- 기본 평가 기준 삽입
INSERT INTO evaluation_criteria (criteria_name, category, max_points, weight_percentage, description_ko) VALUES
('문법 정확성', 'grammar', 40.00, 40.00, '조사, 시제, 어미 사용의 정확성'),
('어휘 적절성', 'vocabulary', 30.00, 30.00, '어휘 선택의 정확성과 다양성'),
('내용 충실성', 'content', 20.00, 20.00, '주제에 맞는 내용 전개'),
('구성 및 논리성', 'organization', 10.00, 10.00, '글의 구조와 논리적 흐름');


-- 3. 오류 유형 테이블
CREATE TABLE error_types (
    error_code VARCHAR(10) PRIMARY KEY,
    category VARCHAR(50) NOT NULL, -- 'grammar', 'vocabulary', 'spelling', 'style'

    -- 이름 (다국어)
    name_ko VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),

    -- 설명
    description_ko TEXT,
    description_en TEXT,

    -- 감점
    penalty_points DECIMAL(3,2) NOT NULL,

    -- 예시
    example_wrong TEXT,
    example_correct TEXT,

    -- 활성화 상태
    is_active BOOLEAN DEFAULT TRUE,

    -- 타임스탬프
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- 제약조건
    CHECK (penalty_points <= 0)
);

COMMENT ON TABLE error_types IS '오류 유형 코드 및 정의';
COMMENT ON COLUMN error_types.penalty_points IS '감점 (음수 값)';

-- 기본 오류 유형 삽입
INSERT INTO error_types (error_code, category, name_ko, name_en, penalty_points, description_ko) VALUES
('G01', 'grammar', '조사 오류', 'Particle Error', -0.5, '조사 사용이 부적절하거나 누락됨'),
('G02', 'grammar', '시제 오류', 'Tense Error', -0.5, '시제 표현이 부적절함'),
('G03', 'grammar', '어미 오류', 'Ending Error', -0.5, '어미 활용이 부적절함'),
('G04', 'grammar', '어순 오류', 'Word Order Error', -0.7, '문장 성분의 순서가 부자연스러움'),
('G05', 'grammar', '접속 오류', 'Conjunction Error', -0.5, '접속 표현 사용 오류 (–는데/–은데, –지만 등)'),
('G06', 'grammar', '문법 불일치', 'Agreement Error', -0.7, '주어-서술어 호응, 수 일치 등'),
('V01', 'vocabulary', '어휘 선택 오류', 'Vocabulary Choice Error', -0.3, '문맥에 맞지 않는 어휘 사용'),
('V02', 'vocabulary', '한자어 오용', 'Sino-Korean Misuse', -0.3, '한자어 사용이 부적절함'),
('S01', 'spelling', '맞춤법 오류', 'Spelling Error', -0.2, '한글 맞춤법 오류'),
('S02', 'spelling', '띄어쓰기 오류', 'Spacing Error', -0.1, '띄어쓰기 오류'),
('C01', 'content', '내용 부족', 'Insufficient Content', -1.0, '주제와 관련 없는 내용 또는 내용 부족');


-- 4. 채점 결과 테이블
CREATE TABLE grading_results (
    grading_id SERIAL PRIMARY KEY,
    answer_id INTEGER NOT NULL REFERENCES student_answers(answer_id) ON DELETE CASCADE,

    -- 점수
    total_score DECIMAL(5,2) NOT NULL,
    grammar_score DECIMAL(5,2),
    vocabulary_score DECIMAL(5,2),
    content_score DECIMAL(5,2),
    organization_score DECIMAL(5,2),

    -- 등급
    grade VARCHAR(2), -- 'A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F'
    pass_fail BOOLEAN,

    -- AI 모델 정보
    grading_model VARCHAR(50),
    model_version VARCHAR(20),

    -- 전체 피드백
    overall_feedback TEXT,

    -- 타임스탬프
    graded_at TIMESTAMP DEFAULT NOW(),

    -- 제약조건
    CHECK (total_score >= 0 AND total_score <= 100)
);

COMMENT ON TABLE grading_results IS 'AI 자동 채점 결과';

-- grading_results 인덱스
CREATE INDEX idx_grading_results_answer_id ON grading_results(answer_id);
CREATE INDEX idx_grading_results_total_score ON grading_results(total_score);
CREATE INDEX idx_grading_results_graded_at ON grading_results(graded_at);


-- 5. 검출된 오류 상세 테이블
CREATE TABLE detected_errors (
    detection_id SERIAL PRIMARY KEY,
    grading_id INTEGER NOT NULL REFERENCES grading_results(grading_id) ON DELETE CASCADE,
    error_code VARCHAR(10) NOT NULL REFERENCES error_types(error_code),

    -- 오류 위치
    error_position INTEGER, -- 원문에서의 문자 위치
    sentence_index INTEGER, -- 몇 번째 문장인지

    -- 원문 및 수정안
    original_text TEXT NOT NULL,
    corrected_text TEXT,

    -- 상세 설명
    explanation TEXT,

    -- 감점
    points_deducted DECIMAL(3,2),

    -- 타임스탬프
    detected_at TIMESTAMP DEFAULT NOW(),

    -- 제약조건
    CHECK (points_deducted <= 0)
);

COMMENT ON TABLE detected_errors IS '채점 과정에서 검출된 개별 오류들';
COMMENT ON COLUMN detected_errors.original_text IS '오류가 포함된 원문';
COMMENT ON COLUMN detected_errors.corrected_text IS 'AI가 제안한 수정안';

-- detected_errors 인덱스
CREATE INDEX idx_detected_errors_grading_id ON detected_errors(grading_id);
CREATE INDEX idx_detected_errors_error_code ON detected_errors(error_code);


-- ============================================
-- 유용한 뷰 (Views)
-- ============================================

-- 학생별 채점 요약 뷰
CREATE VIEW student_grading_summary AS
SELECT
    sa.answer_id,
    sa.student_id,
    sa.created_at as submitted_at,
    gr.total_score,
    gr.grade,
    gr.pass_fail,
    COUNT(de.detection_id) as total_errors,
    gr.graded_at
FROM student_answers sa
LEFT JOIN grading_results gr ON sa.answer_id = gr.answer_id
LEFT JOIN detected_errors de ON gr.grading_id = de.grading_id
GROUP BY sa.answer_id, sa.student_id, sa.created_at, gr.grading_id, gr.total_score, gr.grade, gr.pass_fail, gr.graded_at;

COMMENT ON VIEW student_grading_summary IS '학생별 채점 결과 요약';


-- 오류 유형별 통계 뷰
CREATE VIEW error_statistics AS
SELECT
    et.error_code,
    et.name_ko,
    et.category,
    COUNT(de.detection_id) as occurrence_count,
    AVG(de.points_deducted) as avg_deduction,
    SUM(de.points_deducted) as total_deduction
FROM error_types et
LEFT JOIN detected_errors de ON et.error_code = de.error_code
GROUP BY et.error_code, et.name_ko, et.category
ORDER BY occurrence_count DESC;

COMMENT ON VIEW error_statistics IS '오류 유형별 발생 통계';


-- ============================================
-- 트리거: updated_at 자동 업데이트
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_student_answers_updated_at BEFORE UPDATE ON student_answers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_evaluation_criteria_updated_at BEFORE UPDATE ON evaluation_criteria
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_error_types_updated_at BEFORE UPDATE ON error_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================
-- 샘플 데이터 삽입 (테스트용)
-- ============================================

-- 샘플 학생 답안
INSERT INTO student_answers (student_id, filename, answer_text, char_count, word_count, ocr_model) VALUES
('anna_001', 'anna_answer.jpg', '저는 안나라고 합니다\n제 고향은 독일 뮌헨인데 남쪽에 있습니다\n소개하고 싶은 곳은 마리엔 광장인데\n성당이 많습니다.', 89, 15, 'gpt-4o');

-- 샘플 채점 결과 (이후 AI가 자동으로 생성)
-- INSERT INTO grading_results (answer_id, total_score, grammar_score, grade, pass_fail, grading_model) VALUES
-- (1, 85.5, 38.0, 'B+', TRUE, 'gpt-4o');

-- 샘플 오류 검출 (이후 AI가 자동으로 생성)
-- INSERT INTO detected_errors (grading_id, error_code, original_text, corrected_text, explanation, points_deducted) VALUES
-- (1, 'G01', '고향은 독일 뮌헨인데', '고향은 독일의 뮌헨인데', '국가와 도시 사이에 관형격 조사 "의"가 필요합니다', -0.5);