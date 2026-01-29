#!/usr/bin/env python3
"""
한국어 쓰기 자동 채점 시스템 - DB 초기화 스크립트
"""

import psycopg2
import json
from openai import OpenAI
import os
from pathlib import Path

# OpenAI API 설정
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# PostgreSQL 연결 설정
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432"),
    "database": os.getenv("DB_NAME", "korean_grading"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "")
}


def get_embedding(text: str, model="text-embedding-3-small") -> list:
    """OpenAI API를 사용하여 텍스트 임베딩 생성"""
    text = text.replace("\n", " ")
    response = client.embeddings.create(input=[text], model=model)
    return response.data[0].embedding


def init_database():
    """데이터베이스 초기화"""
    print("📊 데이터베이스 초기화 중...")

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    # 스키마 파일 실행
    schema_path = Path(__file__).parent.parent / "database" / "schema.sql"
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema_sql = f.read()

    cur.execute(schema_sql)
    conn.commit()

    print("✅ 데이터베이스 스키마 생성 완료")

    cur.close()
    conn.close()


def load_grading_criteria():
    """채점 기준 데이터를 DB에 로드"""
    print("\n📝 채점 기준 로딩 중...")

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    # JSON 파일 읽기
    criteria_path = Path(__file__).parent.parent / "grading-criteria" / "lesson_2A_1.json"
    with open(criteria_path, 'r', encoding='utf-8') as f:
        criteria_data = json.load(f)

    lesson = criteria_data["lesson"]

    # 1. 과제 정보 저장
    cur.execute("""
        INSERT INTO assignments (assignment_name, lesson_number, required_sentences)
        VALUES (%s, %s, %s)
        RETURNING assignment_id
    """, (
        criteria_data["assignment"]["title"],
        lesson,
        criteria_data["assignment"]["required_sentences"]
    ))
    assignment_id = cur.fetchone()[0]
    print(f"✅ 과제 정보 저장 완료 (ID: {assignment_id})")

    # 2. 채점 기준 저장 (RAG용)
    for category, details in criteria_data["scoring_criteria"].items():
        criteria_text = f"{details['name']}: {details.get('description', '')}"

        # 임베딩 생성
        embedding = get_embedding(criteria_text)

        cur.execute("""
            INSERT INTO grading_criteria
            (lesson_number, category, criteria_name, criteria_description, scoring_rule, examples, embedding)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            lesson,
            category,
            details['name'],
            details.get('description', ''),
            json.dumps(details.get('rules', []), ensure_ascii=False),
            json.dumps(details, ensure_ascii=False),
            embedding
        ))

    conn.commit()
    print(f"✅ 채점 기준 {len(criteria_data['scoring_criteria'])}개 저장 완료")

    # 3. 문법 규칙 저장 (RAG용)
    for grammar in criteria_data["grammar_rules"]:
        grammar_text = f"{grammar['name']}: {grammar['usage']}"

        # 임베딩 생성
        embedding = get_embedding(grammar_text)

        # detection_patterns를 문자열로 변환
        detection_pattern = "|".join(grammar["detection_patterns"])

        cur.execute("""
            INSERT INTO grammar_rules
            (lesson_number, grammar_name, grammar_form, usage_description,
             score_weight, detection_pattern, examples, embedding)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            lesson,
            grammar['name'],
            json.dumps(grammar['forms'], ensure_ascii=False),
            grammar['usage'],
            grammar['score'],
            detection_pattern,
            json.dumps(grammar['examples'], ensure_ascii=False),
            embedding
        ))

    conn.commit()
    print(f"✅ 문법 규칙 {len(criteria_data['grammar_rules'])}개 저장 완료")

    cur.close()
    conn.close()


def create_sample_data():
    """테스트용 샘플 데이터 생성"""
    print("\n🧪 샘플 데이터 생성 중...")

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    # 샘플 학생 생성
    sample_students = [
        ("20240001", "김민준"),
        ("20240002", "이서연"),
        ("20240003", "박지호")
    ]

    for student_number, student_name in sample_students:
        cur.execute("""
            INSERT INTO students (student_number, student_name)
            VALUES (%s, %s)
            ON CONFLICT (student_number) DO NOTHING
        """, (student_number, student_name))

    conn.commit()
    print(f"✅ 샘플 학생 {len(sample_students)}명 생성 완료")

    cur.close()
    conn.close()


def main():
    """메인 실행 함수"""
    print("=" * 60)
    print("한국어 쓰기 자동 채점 시스템 - 데이터베이스 초기화")
    print("=" * 60)

    try:
        # 1. 데이터베이스 초기화
        init_database()

        # 2. 채점 기준 로드
        load_grading_criteria()

        # 3. 샘플 데이터 생성
        create_sample_data()

        print("\n" + "=" * 60)
        print("✨ 초기화 완료!")
        print("=" * 60)

    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
