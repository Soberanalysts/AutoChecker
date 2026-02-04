#!/usr/bin/env python3
"""
OCR 결과를 PostgreSQL에 저장하는 스크립트
batch_result.json에서 학생 답안을 읽어서 DB에 저장
"""

import json
import re
import psycopg2
from pathlib import Path
from datetime import datetime

# 설정
DB_CONFIG = {
    'dbname': 'autochecker',
    'user': 'postgres',
    'password': '',  # 비밀번호가 있다면 입력
    'host': 'localhost',
    'port': 5432
}

OCR_RESULT_FILE = Path("/Users/imseongjin/AutoChecker/ocr_results/batch_result.json")


def extract_student_name(answer_text: str) -> str:
    """
    답안에서 학생 이름 추출
    "저는 XXX라고 합니다" 또는 "저는 XXX입니다" 패턴
    """
    # 패턴 1: "저는 XXX라고 합니다"
    match = re.search(r'저는\s+(\S+?)(?:라고|이라고)\s+합니다', answer_text)
    if match:
        return match.group(1)

    # 패턴 2: "저는 XXX입니다"
    match = re.search(r'저는\s+(\S+?)입니다', answer_text)
    if match:
        return match.group(1)

    return None


def insert_student_answers(answers: list):
    """
    학생 답안을 PostgreSQL에 저장
    """
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    inserted_count = 0

    try:
        for idx, answer_text in enumerate(answers, 1):
            # 학생 이름 추출
            student_name = extract_student_name(answer_text)

            if student_name:
                student_id = f"{student_name}_{str(idx).zfill(3)}"
                print(f"[{idx}] 학생 이름 추출: {student_name}")
            else:
                student_id = f"student_{str(idx).zfill(3)}"
                print(f"[{idx}] 학생 이름 없음 → mock ID 사용: {student_id}")

            # 메타데이터 계산
            char_count = len(answer_text)
            word_count = len(answer_text.split())
            filename = f"쓰기 채점_예문 ({idx}).jpg"

            # DB에 삽입
            cursor.execute("""
                INSERT INTO student_answers
                (student_id, filename, answer_text, char_count, word_count, ocr_model, extracted_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING answer_id;
            """, (
                student_id,
                filename,
                answer_text,
                char_count,
                word_count,
                'gpt-4o',
                datetime.now()
            ))

            answer_id = cursor.fetchone()[0]
            print(f"    ✅ DB 저장 완료 (answer_id: {answer_id}, {char_count}자)")
            inserted_count += 1

        conn.commit()
        print(f"\n총 {inserted_count}개 답안 저장 완료!")

    except Exception as e:
        conn.rollback()
        print(f"❌ 에러 발생: {e}")
        raise
    finally:
        cursor.close()
        conn.close()


def main():
    print("=" * 60)
    print("OCR 결과 → PostgreSQL 저장")
    print("=" * 60)
    print()

    # OCR 결과 파일 읽기
    if not OCR_RESULT_FILE.exists():
        print(f"❌ 파일 없음: {OCR_RESULT_FILE}")
        return

    with open(OCR_RESULT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 답안 추출
    if 'students' in data and len(data['students']) > 0:
        answers = data['students'][0]['answer']
        print(f"📄 {len(answers)}개 학생 답안 발견")
        print()
    else:
        print("❌ 답안 데이터 없음")
        return

    # DB에 저장
    insert_student_answers(answers)

    print()
    print("=" * 60)
    print("완료! 다음 명령으로 확인:")
    print("  psql -U postgres -d autochecker -c 'SELECT * FROM student_answers;'")
    print("=" * 60)


if __name__ == "__main__":
    main()