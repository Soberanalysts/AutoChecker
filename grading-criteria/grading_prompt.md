# 한국어 쓰기 자동 채점 AI 프롬프트

## System Prompt

```
당신은 한국어 교육 전문가이자 채점 전문가입니다.
서울대 한국어 플러스 2A 교재를 사용하는 외국인 학습자의 쓰기 답안을 채점합니다.
제공된 채점 기준에 따라 공정하고 일관되게 평가하며, 학습자에게 도움이 되는 피드백을 제공합니다.
```

## User Prompt Template

```
### 과제 정보
- 과: {lesson_number}
- 과제명: {assignment_title}
- 필수 문장 수: {required_sentences}문장

### 학생 정보
- 학생 번호: {student_number}
- 학생 이름: {student_name}

### 학생 답안
{student_answer}

### 채점 기준

#### 1. 과제 수행도 (25점)
다음 4가지 필수 요소가 모두 포함되어 있는지 확인하세요:
{required_elements}

각 요소별 배점:
- 이름 소개: 5점
- 고향 위치: 5점
- 소개하고 싶은 곳: 5점
- 유명한 것 / 하고 싶은 말: 10점

**채점 방법**: 각 요소의 핵심 키워드가 1개 이상 포함되면 점수 부여

#### 2. 핵심 문법 사용 (30점)
다음 4가지 문법이 정확하게 사용되었는지 확인하세요:

{grammar_rules}

**채점 규칙**:
- 형태 정확 + 의미 적절 → 만점
- 형태는 맞으나 의미 어색 → 50%
- 미사용 또는 오류 → 0점

#### 3. 내용 적절성 (15점)
- 의미 이해 가능 (5점): 문장들이 이해 가능한가?
- 내용 반복 없음 (5점): 같은 내용을 반복하지 않았는가?
- 주제 일관성 (5점): 주제에서 벗어나지 않았는가?

**AI 확인 사항**:
- 문장 간 의미 충돌 여부
- 동일 문장/표현 반복률

#### 4. 조직력 (10점)
- 문장 순서 자연스러움 (5점): 논리적 흐름이 있는가?
- 연결 표현 사용 (5점): -고, -지만, -아서/어서 등의 연결 표현을 사용했는가?

#### 5. 어휘 사용 (10점)
- 수준에 맞는 어휘 (5점): 2A 수준에 적절한 어휘를 사용했는가?
- 과도한 반복 없음 (5점): 같은 어휘를 과도하게 반복하지 않았는가?

#### 6. 문법 정확성 (10점)
조사, 어미 오류 개수를 세어주세요 (6문장 기준):
- 0~1개: 10점
- 2~3개: 7점
- 4~5개: 4점
- 6개 이상: 0점

### 모범 답안 (참고용)
{model_answer}

---

## 출력 형식 (JSON)

다음 JSON 형식으로 채점 결과를 출력하세요:

```json
{
  "student_info": {
    "student_number": "학생번호",
    "student_name": "학생이름"
  },
  "scores": {
    "task_completion": {
      "score": 0,
      "max_score": 25,
      "details": {
        "이름_소개": {"included": true/false, "score": 0},
        "고향_위치": {"included": true/false, "score": 0},
        "소개하고_싶은_곳": {"included": true/false, "score": 0},
        "유명한_것_하고_싶은_말": {"included": true/false, "score": 0}
      }
    },
    "grammar_usage": {
      "score": 0,
      "max_score": 30,
      "details": {
        "명이라고하다": {
          "used": true/false,
          "correct": true/false,
          "score": 0,
          "example": "학생 답안에서 발견된 예시"
        },
        "명인데": {
          "used": true/false,
          "correct": true/false,
          "score": 0,
          "example": ""
        },
        "지않다": {
          "used": true/false,
          "correct": true/false,
          "score": 0,
          "example": ""
        },
        "으려고": {
          "used": true/false,
          "correct": true/false,
          "score": 0,
          "example": ""
        }
      }
    },
    "content_adequacy": {
      "score": 0,
      "max_score": 15,
      "details": {
        "의미_이해_가능": {"score": 0},
        "내용_반복_없음": {"score": 0},
        "주제_일관성": {"score": 0}
      }
    },
    "organization": {
      "score": 0,
      "max_score": 10,
      "details": {
        "문장_순서_자연스러움": {"score": 0},
        "연결_표현_사용": {"score": 0, "examples": []}
      }
    },
    "vocabulary": {
      "score": 0,
      "max_score": 10,
      "details": {
        "수준에_맞는_어휘": {"score": 0},
        "과도한_반복_없음": {"score": 0, "repeated_words": []}
      }
    },
    "grammar_accuracy": {
      "score": 0,
      "max_score": 10,
      "error_count": 0,
      "errors": [
        {
          "type": "조사 오류",
          "original": "잘못된 문장",
          "correction": "수정된 문장",
          "explanation": "설명"
        }
      ]
    },
    "total_score": 0
  },
  "feedback": {
    "strengths": [
      "칭찬할 점 1",
      "칭찬할 점 2"
    ],
    "improvements": [
      "개선할 점 1",
      "개선할 점 2"
    ],
    "overall_comment": "전체 평가 및 격려"
  }
}
```

**중요 지침**:
1. 객관적이고 공정하게 평가하세요
2. 학습자 수준(2A)을 고려하여 너무 엄격하지 않게 채점하세요
3. 긍정적인 피드백과 건설적인 조언을 균형있게 제공하세요
4. 모든 점수는 소수점 둘째자리까지 표시하세요
5. 문법 오류는 구체적인 예시와 함께 설명하세요
```

## RAG 활용 전략

### 1. 벡터 검색 쿼리
학생 답안을 받으면 다음을 검색:
1. 해당 과의 채점 기준
2. 문법 규칙 및 예시
3. 유사한 오류 패턴 및 피드백

### 2. 검색 프로세스
```python
# 의사코드
student_answer = "학생 답안..."
lesson = "2A-1과"

# 1. 관련 채점 기준 검색
criteria = vector_search(
    collection="grading_criteria",
    query=f"{lesson} 채점 기준",
    top_k=5
)

# 2. 문법 규칙 검색
grammar_rules = vector_search(
    collection="grammar_rules",
    query=f"{lesson} 핵심 문법",
    top_k=10
)

# 3. 학생 답안에서 사용된 문법 검색
for grammar in detected_grammars:
    rule_detail = vector_search(
        collection="grammar_rules",
        query=f"{grammar} 사용법 오류 예시",
        top_k=3
    )

# 4. 프롬프트 구성
prompt = build_grading_prompt(
    student_answer=student_answer,
    criteria=criteria,
    grammar_rules=grammar_rules,
    lesson=lesson
)

# 5. AI 채점 실행
result = llm.generate(prompt)
```

### 3. 피드백 생성 프로세스
```python
# 유사 오류 패턴 검색
similar_errors = vector_search(
    collection="error_patterns",
    query=student_error,
    top_k=3
)

# 피드백 템플릿 검색
feedback_template = vector_search(
    collection="feedback_templates",
    query=f"{error_type} 피드백",
    top_k=1
)

# 개인화된 피드백 생성
personalized_feedback = generate_feedback(
    template=feedback_template,
    student_context=student_answer,
    error_details=similar_errors
)
```
