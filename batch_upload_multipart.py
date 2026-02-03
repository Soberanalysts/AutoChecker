#!/usr/bin/env python3
"""
n8n 배치 워크플로우로 5개 이미지를 한번에 전송
Split In Batches 노드가 내부적으로 루프 처리
"""

import json
import requests
from pathlib import Path

# 설정
N8N_BATCH_URL = "http://localhost:5678/webhook-test/image-ocr-batch"
IMAGE_DIR = Path("/Users/imseongjin/AutoChecker/example")
OUTPUT_FILE = Path("/Users/imseongjin/AutoChecker/ocr_results/batch_result.json")

# 출력 디렉토리 생성
OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

def main():
    print("=" * 50)
    print("n8n 배치 워크플로우 테스트")
    print("=" * 50)
    print()

    # 이미지 파일 목록
    image_files = [
        IMAGE_DIR / f"쓰기 채점_예문 ({i}).jpg"
        for i in range(1, 6)
    ]

    # 파일 존재 확인
    missing_files = [f for f in image_files if not f.exists()]
    if missing_files:
        print("❌ 다음 파일을 찾을 수 없습니다:")
        for f in missing_files:
            print(f"   - {f}")
        return

    print(f"✅ 5개 이미지 파일 확인 완료")
    print()

    # 모든 파일 크기 출력
    total_size = 0
    for idx, img_file in enumerate(image_files, 1):
        size_mb = img_file.stat().st_size / 1024 / 1024
        total_size += size_mb
        print(f"  [{idx}] {img_file.name}: {size_mb:.2f} MB")

    print(f"\n  총 크기: {total_size:.2f} MB")
    print()

    # 멀티파트 폼 데이터 준비
    print("📤 n8n 배치 엔드포인트로 전송 중...")
    print(f"   URL: {N8N_BATCH_URL}")
    print()

    try:
        # 여러 파일을 'data' 필드로 전송
        files = [
            ('data', (img_file.name, open(img_file, 'rb'), 'image/jpeg'))
            for img_file in image_files
        ]

        response = requests.post(
            N8N_BATCH_URL,
            files=files,
            timeout=300  # 5분 타임아웃 (5개 처리)
        )

        # 파일 핸들 닫기
        for _, file_tuple in files:
            file_tuple[1].close()

        print(f"📥 응답 수신: HTTP {response.status_code}")
        print()

        if response.status_code != 200:
            print(f"❌ 에러 발생:")
            print(response.text[:500])
            return

        # 결과 파싱
        result = response.json()

        # 결과 저장
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)

        print("=" * 50)
        print("✅ 배치 처리 완료!")
        print("=" * 50)
        print()

        # 요약 출력
        total_students = result.get("total_students", 0)
        students = result.get("students", [])

        print(f"처리된 학생 수: {total_students}")
        print(f"처리 시간: {result.get('processed_at', 'N/A')}")
        print()

        print("=" * 50)
        print("학생별 결과:")
        print("=" * 50)

        for student in students:
            student_id = student.get("student_id", "?")
            filename = student.get("filename", "N/A")
            status = student.get("status", "unknown")

            status_icon = "✅" if status == "success" else "❌"

            metadata = student.get("metadata", {})
            char_count = metadata.get("char_count", 0)
            word_count = metadata.get("word_count", 0)

            print(f"{status_icon} 학생 {student_id}: {filename}")
            print(f"   - 글자 수: {char_count}자")
            print(f"   - 단어 수: {word_count}개")

            if status != "success":
                error = student.get("error", "Unknown error")
                print(f"   - 에러: {error}")

            print()

        print("=" * 50)
        print(f"결과 파일: {OUTPUT_FILE}")
        print("=" * 50)

    except requests.exceptions.Timeout:
        print("❌ 타임아웃 (5분 초과)")
    except requests.exceptions.RequestException as e:
        print(f"❌ 네트워크 에러: {e}")
    except json.JSONDecodeError as e:
        print(f"❌ JSON 파싱 에러: {e}")
        print(f"응답 내용: {response.text[:500]}")
    except Exception as e:
        print(f"❌ 예상치 못한 에러: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()