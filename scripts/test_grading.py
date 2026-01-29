#!/usr/bin/env python3
"""
테스트용 채점 스크립트 - 샘플 답안으로 채점 시스템 테스트
"""

import requests
import json
import base64
from pathlib import Path

# n8n Webhook URL
WEBHOOK_URL = "http://localhost:5678/webhook/submit-answer"

# 샘플 학생 답안 (텍스트)
SAMPLE_ANSWERS = {
    "excellent": {
        "student_number": "20240001",
        "student_name": "김민준",
        "text": """안녕하세요. 저는 다니엘이라고 합니다.
제 고향은 베트남 하노이인데 베트남의 북쪽에 있습니다.
하노이는 크지 않지만 사람들이 많고 활기찬 도시입니다.
제가 소개하고 싶은 곳은 호안끼엠 호수인데 경치가 아주 좋습니다.
제 고향은 쌀국수가 유명하지만 너무 맵지 않습니다.
저는 한국 친구들에게 제 고향을 소개하려고 이 글을 씁니다."""
    },
    "good": {
        "student_number": "20240002",
        "student_name": "이서연",
        "text": """저는 마리아라고 합니다.
제 고향은 스페인 바르셀로나인데 지중해 근처에 있습니다.
바르셀로나는 크고 아름다운 도시입니다.
제가 소개하고 싶은 곳은 사그라다 파밀리아입니다.
제 고향은 파에야가 유명합니다.
저는 한국에서 공부하려고 왔습니다."""
    },
    "needs_improvement": {
        "student_number": "20240003",
        "student_name": "박지호",
        "text": """저는 존이라고 합니다.
제 고향은 미국 뉴욕입니다.
뉴욕는 큰 도시입니다.
제가 좋아하는 곳은 센트럴 파크입니다.
햄버거가 유명합니다."""
    }
}


def test_grading(answer_type="excellent"):
    """채점 시스템 테스트"""

    sample = SAMPLE_ANSWERS[answer_type]

    # 요청 데이터 구성
    payload = {
        "student_number": sample["student_number"],
        "student_name": sample["student_name"],
        "assignment_id": 1,  # 2A-1과
        "extracted_text": sample["text"]  # 실제로는 OCR 결과가 들어감
    }

    print(f"\n{'='*60}")
    print(f"테스트 답안 유형: {answer_type.upper()}")
    print(f"학생: {sample['student_name']} ({sample['student_number']})")
    print(f"{'='*60}\n")
    print("학생 답안:")
    print(sample["text"])
    print(f"\n{'='*60}\n")

    try:
        # n8n Webhook 호출
        print("채점 중...")
        response = requests.post(WEBHOOK_URL, json=payload, timeout=60)

        if response.status_code == 200:
            result = response.json()

            print("\n✅ 채점 완료!\n")
            print(f"{'='*60}")
            print("채점 결과")
            print(f"{'='*60}\n")

            # 점수 출력
            scores = result["scores"]
            print(f"📊 총점: {scores['total_score']}/100점\n")

            print("세부 점수:")
            print(f"  - 과제 수행도: {scores['task_completion']['score']}/{scores['task_completion']['max_score']}점")
            print(f"  - 핵심 문법 사용: {scores['grammar_usage']['score']}/{scores['grammar_usage']['max_score']}점")
            print(f"  - 내용 적절성: {scores['content_adequacy']['score']}/{scores['content_adequacy']['max_score']}점")
            print(f"  - 조직력: {scores['organization']['score']}/{scores['organization']['max_score']}점")
            print(f"  - 어휘 사용: {scores['vocabulary']['score']}/{scores['vocabulary']['max_score']}점")
            print(f"  - 문법 정확성: {scores['grammar_accuracy']['score']}/{scores['grammar_accuracy']['max_score']}점")

            # 피드백 출력
            feedback = result["feedback"]
            print(f"\n{'='*60}")
            print("피드백")
            print(f"{'='*60}\n")

            print("✅ 잘한 점:")
            for strength in feedback["strengths"]:
                print(f"  {strength}")

            if feedback["improvements"]:
                print("\n📝 개선할 점:")
                for improvement in feedback["improvements"]:
                    print(f"  {improvement}")

            print(f"\n💬 종합 의견:")
            print(f"  {feedback['overall_comment']}\n")

            return result

        else:
            print(f"❌ 오류 발생: HTTP {response.status_code}")
            print(response.text)
            return None

    except requests.exceptions.Timeout:
        print("❌ 타임아웃 오류: 채점 시간이 너무 오래 걸립니다.")
        return None
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        return None


def main():
    """메인 실행 함수"""
    print("\n" + "="*60)
    print("한국어 쓰기 자동 채점 시스템 - 테스트")
    print("="*60)

    print("\n어떤 답안을 테스트하시겠습니까?")
    print("1. 우수 답안 (excellent)")
    print("2. 양호 답안 (good)")
    print("3. 미흡 답안 (needs_improvement)")
    print("4. 모두 테스트")

    choice = input("\n선택 (1-4): ").strip()

    if choice == "1":
        test_grading("excellent")
    elif choice == "2":
        test_grading("good")
    elif choice == "3":
        test_grading("needs_improvement")
    elif choice == "4":
        for answer_type in ["excellent", "good", "needs_improvement"]:
            test_grading(answer_type)
            input("\n다음 테스트를 진행하려면 Enter를 누르세요...")
    else:
        print("잘못된 선택입니다.")


if __name__ == "__main__":
    main()
