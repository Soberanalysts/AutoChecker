#!/bin/bash

# AutoChecker PostgreSQL 데이터베이스 자동 셋업 스크립트

set -e  # 에러 발생 시 즉시 중단

echo "========================================="
echo "AutoChecker DB 셋업 시작"
echo "========================================="
echo

# 설정
DB_NAME="autochecker"
DB_USER="postgres"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="$SCRIPT_DIR/schema.sql"

# 1. 데이터베이스 존재 확인
echo "[1/4] 데이터베이스 확인 중..."
if psql -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo "⚠️  '$DB_NAME' 데이터베이스가 이미 존재합니다."
    read -p "삭제하고 새로 만드시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  → 기존 DB 삭제 중..."
        psql -U $DB_USER -c "DROP DATABASE $DB_NAME;" 2>/dev/null || true
        echo "  ✅ 삭제 완료"
    else
        echo "  → 기존 DB 유지. 스키마만 재실행합니다."
    fi
fi

# 2. 데이터베이스 생성 (존재하지 않을 경우)
if ! psql -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo "[2/4] 데이터베이스 생성 중..."
    psql -U $DB_USER -c "CREATE DATABASE $DB_NAME WITH ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';"
    echo "  ✅ '$DB_NAME' 데이터베이스 생성 완료"
else
    echo "[2/4] 데이터베이스 이미 존재 (생략)"
fi

# 3. 스키마 실행
echo "[3/4] 스키마 실행 중..."
if [ ! -f "$SCHEMA_FILE" ]; then
    echo "  ❌ 에러: $SCHEMA_FILE 파일이 없습니다."
    exit 1
fi

psql -U $DB_USER -d $DB_NAME -f "$SCHEMA_FILE" > /dev/null
echo "  ✅ 스키마 실행 완료"

# 4. 테이블 확인
echo "[4/4] 생성된 테이블 확인 중..."
echo
psql -U $DB_USER -d $DB_NAME -c "
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
"

echo
echo "========================================="
echo "✅ 셋업 완료!"
echo "========================================="
echo
echo "데이터베이스 정보:"
echo "  - 이름: $DB_NAME"
echo "  - 사용자: $DB_USER"
echo "  - 스키마: public"
echo
echo "다음 명령으로 접속 가능:"
echo "  psql -U $DB_USER -d $DB_NAME"
echo
echo "샘플 쿼리:"
echo "  SELECT * FROM error_types;"
echo "  SELECT * FROM evaluation_criteria;"
echo "========================================="