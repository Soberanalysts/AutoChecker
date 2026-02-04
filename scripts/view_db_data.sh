#!/bin/bash
# PostgreSQL 데이터 조회 스크립트

echo "========================================="
echo "AutoChecker DB 데이터 조회"
echo "========================================="
echo

echo "1. 학생 답안 목록"
echo "========================================="
psql -U postgres -d autochecker -c "
SELECT
    answer_id,
    student_id,
    filename,
    LEFT(answer_text, 50) || '...' as answer_preview,
    char_count,
    word_count,
    created_at
FROM student_answers
ORDER BY answer_id;
"

echo
echo "2. 오류 유형 목록"
echo "========================================="
psql -U postgres -d autochecker -c "
SELECT
    error_code,
    name_ko,
    category,
    penalty_points,
    description_ko
FROM error_types
ORDER BY error_code;
"

echo
echo "3. 평가 기준"
echo "========================================="
psql -U postgres -d autochecker -c "
SELECT
    criteria_name,
    category,
    max_points,
    weight_percentage || '%' as weight,
    description_ko
FROM evaluation_criteria
ORDER BY criteria_id;
"