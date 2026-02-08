#!/bin/bash

# AutoChecker DB 데이터 삭제 스크립트

echo "=== AutoChecker DB 데이터 삭제 ==="
echo ""
echo "선택하세요:"
echo "1) 모든 데이터 삭제 (테이블 구조 유지)"
echo "2) student_answers만 삭제"
echo "3) grading_results만 삭제"
echo "4) 최근 1시간 데이터만 삭제"
echo "5) 특정 student_id 삭제"
echo "0) 취소"
echo ""
read -p "선택 (0-5): " choice

case $choice in
  1)
    echo "모든 데이터를 삭제합니다..."
    psql -U postgres -d autochecker -c "
      TRUNCATE TABLE detected_errors CASCADE;
      TRUNCATE TABLE grading_results CASCADE;
      TRUNCATE TABLE student_answers CASCADE;
    "
    echo "✅ 모든 데이터 삭제 완료"
    ;;

  2)
    echo "student_answers 데이터를 삭제합니다..."
    psql -U postgres -d autochecker -c "TRUNCATE TABLE student_answers CASCADE;"
    echo "✅ student_answers 삭제 완료"
    ;;

  3)
    echo "grading_results 데이터를 삭제합니다..."
    psql -U postgres -d autochecker -c "TRUNCATE TABLE grading_results CASCADE;"
    echo "✅ grading_results 삭제 완료"
    ;;

  4)
    echo "최근 1시간 데이터를 삭제합니다..."
    psql -U postgres -d autochecker -c "
      DELETE FROM student_answers WHERE created_at > NOW() - INTERVAL '1 hour';
    "
    echo "✅ 최근 1시간 데이터 삭제 완료"
    ;;

  5)
    read -p "삭제할 student_id 입력: " student_id
    echo "student_id='$student_id' 데이터를 삭제합니다..."
    psql -U postgres -d autochecker -c "
      DELETE FROM student_answers WHERE student_id = '$student_id';
    "
    echo "✅ student_id='$student_id' 삭제 완료"
    ;;

  0)
    echo "취소되었습니다."
    exit 0
    ;;

  *)
    echo "❌ 잘못된 선택입니다."
    exit 1
    ;;
esac

echo ""
echo "=== 현재 데이터 개수 확인 ==="
psql -U postgres -d autochecker -c "
  SELECT
    'student_answers' as table_name, COUNT(*) as count
  FROM student_answers
  UNION ALL
  SELECT
    'grading_results', COUNT(*)
  FROM grading_results
  UNION ALL
  SELECT
    'detected_errors', COUNT(*)
  FROM detected_errors;
"