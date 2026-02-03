#!/usr/bin/env python3
"""
5개 이미지 파일 OCR 처리 및 구조화된 데이터로 정리
"""

import json
import requests
import time
from pathlib import Path
from typing import List, Dict

# 설정
N8N_URL = "http://localhost:5678/webhook-test/image-ocr"
IMAGE_DIR = Path("/Users/imseongjin/AutoChecker/example")
OUTPUT_DIR = Path("/Users/imseongjin/AutoChecker/ocr_results")

# 출력 디렉토리 생성
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def extract_text_from_image(image_path: Path) -> Dict:
    """이미지에서 텍스트 추출"""
    print(f"  처리 중: {image_path.name}")

    try:
        with open(image_path, 'rb') as f:
            files = {'data': (image_path.name, f, 'image/jpeg')}
            response = requests.post(N8N_URL, files=files, timeout=60)
            response.raise_for_status()
            return response.json()
    except Exception as e:
        print(f"  ❌ 에러: {e}")
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
        print(f"[{idx}/5] {image_path.name}")

        if not image_path.exists():
            print(f"  ⚠️  파일 없음")
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

        print(f"  ✅ 완료: {output_file.name}")

        # API 과부하 방지
        if idx < len(image_files):
            time.sleep(2)

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