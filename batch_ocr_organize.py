#!/usr/bin/env python3
"""
5개 이미지 파일 OCR 처리 및 구조화된 데이터로 정리
"""

import json
import requests
import time
from pathlib import Path
from typing import Dict

# 설정
N8N_URL = "http://localhost:5678/webhook-test/image-ocr"
IMAGE_DIR = Path("/Users/imseongjin/AutoChecker/example")
OUTPUT_DIR = Path("/Users/imseongjin/AutoChecker/ocr_results")

# 출력 디렉토리 생성
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def extract_text_from_image(image_path: Path) -> Dict:
    """이미지에서 텍스트 추출"""
    print(f"  처리 중: {image_path.name}")
    print(f"  파일 크기: {image_path.stat().st_size / 1024 / 1024:.2f} MB")

    try:
        with open(image_path, 'rb') as f:
            files = {'data': (image_path.name, f, 'image/jpeg')}
            print(f"  → n8n으로 전송 중...")
            response = requests.post(N8N_URL, files=files, timeout=120)

            print(f"  ← 응답 상태: {response.status_code}")

            if response.status_code != 200:
                print(f"  ❌ HTTP {response.status_code}: {response.text[:200]}")
                return {
                    "error": f"HTTP {response.status_code}",
                    "error_detail": response.text,
                    "extracted_text": "",
                    "metadata": {}
                }

            response.raise_for_status()
            result = response.json()

            # 성공 여부 확인
            if result.get("success"):
                char_count = result.get("metadata", {}).get("char_count", 0)
                print(f"  ✅ 추출 성공: {char_count}자")
            else:
                print(f"  ⚠️  응답은 받았으나 success=false")

            return result

    except requests.exceptions.Timeout:
        print(f"  ❌ 타임아웃 (120초 초과)")
        return {"error": "Timeout", "extracted_text": "", "metadata": {}}
    except requests.exceptions.RequestException as e:
        print(f"  ❌ 네트워크 에러: {e}")
        return {"error": str(e), "extracted_text": "", "metadata": {}}
    except json.JSONDecodeError as e:
        print(f"  ❌ JSON 파싱 에러: {e}")
        print(f"  응답 내용: {response.text[:200]}")
        return {"error": "Invalid JSON", "extracted_text": "", "metadata": {}}
    except Exception as e:
        print(f"  ❌ 예상치 못한 에러: {e}")
        return {"error": str(e), "extracted_text": "", "metadata": {}}

def main():
    print("=" * 50)
    print("이미지 OCR 일괄 처리 및 데이터 정리")
    print("=" * 50)
    print()

    # 이미지 파일 목록
    image_files = [
        IMAGE_DIR / f"쓰기 채점_예문 ({i}).jpg"
        for i in range(1, 6)
    ]

    # 각 이미지 처리
    results = []
    for idx, image_path in enumerate(image_files, 1):
        print()
        print(f"{'=' * 50}")
        print(f"[{idx}/5] {image_path.name}")
        print(f"{'=' * 50}")

        if not image_path.exists():
            print(f"  ⚠️  파일 없음: {image_path}")
            result = {
                "student_id": idx,
                "image_file": image_path.name,
                "answer": "",
                "metadata": {},
                "ocr_status": "file_not_found",
                "error": "File not found"
            }
            results.append(result)
            continue

        # OCR 실행
        ocr_result = extract_text_from_image(image_path)

        # 결과 저장
        result = {
            "student_id": idx,
            "image_file": image_path.name,
            "answer": ocr_result.get("extracted_text", ""),
            "metadata": ocr_result.get("metadata", {}),
            "ocr_status": "success" if not ocr_result.get("error") else "failed",
            "error": ocr_result.get("error")
        }
        results.append(result)

        # 개별 파일 저장
        output_file = OUTPUT_DIR / f"result_{idx}.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(ocr_result, f, ensure_ascii=False, indent=2)

        print(f"  💾 저장: {output_file.name}")

        # API 과부하 방지를 위한 딜레이
        if idx < len(image_files):
            print(f"  ⏳ 대기 중... (3초)")
            time.sleep(3)

    print()
    print("=" * 50)
    print("결과 정리 중...")
    print("=" * 50)

    # 통합 결과 저장
    all_results = {
        "total_students": len(results),
        "processed_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "students": results
    }

    output_file = OUTPUT_DIR / "all_results.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_results, f, ensure_ascii=False, indent=2)

    print(f"✅ 통합 결과: {output_file}")

    # 각 학생별 답안만 추출
    answers_only = {
        f"student_{r['student_id']}": {
            "answer": r["answer"],
            "char_count": r["metadata"].get("char_count", 0),
            "word_count": r["metadata"].get("word_count", 0)
        }
        for r in results if r["ocr_status"] == "success"
    }

    answers_file = OUTPUT_DIR / "answers_only.json"
    with open(answers_file, 'w', encoding='utf-8') as f:
        json.dump(answers_only, f, ensure_ascii=False, indent=2)

    print(f"✅ 답안만: {answers_file}")

    # 요약 출력
    print()
    print("=" * 50)
    print("추출 요약:")
    print("=" * 50)
    for result in results:
        status = "✅" if result["ocr_status"] == "success" else "❌"
        char_count = result["metadata"].get("char_count", 0)
        word_count = result["metadata"].get("word_count", 0)
        print(f"{status} 학생 {result['student_id']}: {char_count}자, {word_count}단어")

    print()
    print("=" * 50)
    print("결과 파일:")
    print("=" * 50)
    print(f"- 개별 결과: {OUTPUT_DIR}/result_1.json ~ result_5.json")
    print(f"- 통합 결과: {OUTPUT_DIR}/all_results.json")
    print(f"- 답안만: {OUTPUT_DIR}/answers_only.json")
    print("=" * 50)

if __name__ == "__main__":
    main()