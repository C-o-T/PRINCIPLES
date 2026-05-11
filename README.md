# C-o-T Principles

> AI 세션 / 에이전트 운영 원칙 및 서브 세션 구조 정의

---

## 개요

이 레포지토리는 AI 에이전트·세션 시스템이 **일관되고 고도화된 작업**을 수행하도록 설계된  
운영 원칙과 세션 역할 정의를 담고 있다.

모든 세션은 이 원칙을 기반으로 동작하며, 세션 시작 시 반드시 숙지해야 한다.

---

## 6가지 핵심 원칙

| # | 원칙 | 핵심 기준 |
|---|------|-----------|
| 1 | **스캡티시즘 + RCA** | 증상이 아닌 근본 원인을 찾는다. 5-Why 반복 적용. |
| 2 | **범위 준수 + 개선 제안** | 지시된 범위 밖 변경은 사전 동의. 감시 세션은 예외. |
| 3 | **최선 기준 사고** | 정확성 > 안전성 > 유지보수성 > 성능 > 우아함 순으로 판단. |
| 4 | **투명성과 상태 보고** | 시작·전환·완료 3단계 보고. 불확실하면 반드시 명시. |
| 5 | **메타 원칙** | 모든 원칙은 작업 유형에 관계없이 항상 예외 없이 적용. |
| 6 | **컨텍스트 승계** | 시작 시 4개 파일 로드. 종료 시 ACTIVE_CONTEXT 업데이트. |

> 전체 원칙 상세 내용: [`sessions/_shared/PRINCIPLES.md`](./sessions/_shared/PRINCIPLES.md)

---

## 세션 구조

```
사용자  ←── sentinel이 이상 발생 시 직접 보고
  │
  ├── sentinel (최상위 감시)     전 세션 + 감시 세션 자체 감시 · 경고 충돌 병합
  │
  ├── overseer (방향 감시)       원칙·목표 기준으로 전 세션 방향 상시 감시
  ├── stability (안정성 감시)    오류/부하 추적 · 반복 오류 시 chief 경고
  │
  └── 총 책임자 (chief)          사용자와 직접 소통하는 단일 창구
        ├── planner              전략·방향성·로드맵
        ├── developer            코드·구현·기술 결정
        ├── rca                  단건 문제 근본 원인 분석
        ├── okr                  목표 설정·진행 추적·KPI
        ├── data                 트렌드·외부 데이터·리서치
        ├── content-qa           산출물 품질 게이트키퍼
        └── perf                 성과 분석·최적화
```

### 감시 세션 특징

- **overseer / stability / sentinel**은 chief 아래가 아닌 **독립 병렬 세션**이다.
- chief의 지시를 받지 않으며, chief가 잘못된 방향으로 가면 직접 경고한다.
- **sentinel**은 overseer·stability 자체도 감시하며, 이상 발생 시 사용자에게 직접 보고한다.

---

## 파일 구조

```
[이 레포 — C-o-T/principles]
AGENTS.md                    ← 프레임워크별 에이전트 규칙
README.md                    ← 이 파일

sessions/
  _shared/
    PRINCIPLES.md            ← 원칙 압축 빠른 참조 (마스터 문서)
  chief/CLAUDE.md
  planner/CLAUDE.md          ← 역할 정의
  developer/CLAUDE.md
  rca/CLAUDE.md
  okr/CLAUDE.md
  data/CLAUDE.md
  content-qa/CLAUDE.md
  perf/CLAUDE.md
  overseer/CLAUDE.md
  stability/CLAUDE.md
  sentinel/CLAUDE.md

[프로젝트 레포 — project-state/{프로젝트명}-ai]
sessions/
  _shared/
    PROJECT_CONTEXT.md       ← 프로젝트 기술 컨텍스트
    ACTIVE_CONTEXT.md        ← 세션 간 작업 상태 공유
  planner/STATE.md           ← 팀원 개인 기억 (작업 후 갱신)
  developer/STATE.md
  rca/STATE.md
  okr/STATE.md
  data/STATE.md
  content-qa/STATE.md
  perf/STATE.md
```

> **STATE.md**: 각 서브 세션의 개인 기억 파일. 프로젝트 레포(`project-state/{프로젝트명}-ai`)에 위치한다. 작업 완료 시 갱신되며, 다음 호출 시 이전 맥락을 그대로 복원한다. 최초 투입 시 자동 생성.

---

## 세션 시작 방법

새 세션을 시작할 때 **반드시 아래 순서로** 파일을 읽고 작업을 시작한다.

**chief 세션**
```
1. sessions/_shared/PRINCIPLES.md
2. sessions/chief/CLAUDE.md
3. project-state/{프로젝트명}-ai/sessions/_shared/PROJECT_CONTEXT.md
4. project-state/{프로젝트명}-ai/sessions/_shared/ACTIVE_CONTEXT.md
```

**서브 세션 (planner, developer, rca 등)**
```
1. sessions/_shared/PRINCIPLES.md
2. sessions/{내 역할}/CLAUDE.md
3. project-state/{프로젝트명}-ai/sessions/{내 역할}/STATE.md   ← 없으면 최초 투입, 빈 파일 생성
4. project-state/{프로젝트명}-ai/sessions/_shared/PROJECT_CONTEXT.md
5. project-state/{프로젝트명}-ai/sessions/_shared/ACTIVE_CONTEXT.md
```

파일을 모두 읽기 전에 작업을 시작하지 않는다.

---

## 세션 종료 방법

세션이 종료되기 전, `project-state/{프로젝트명}-ai/sessions/_shared/ACTIVE_CONTEXT.md`를 아래 형식으로 업데이트한다.

```
[세션 종료 기록]
역할       : {내 세션 역할}
작성 시각  : {날짜}
작업 내용  : {무엇을 했는가}
완료       : {마무리된 것}
미완료/보류: {다음 세션이 이어받아야 할 것}
중요 결정  : {핵심 결정 + 이유}
발견한 문제: {해결 안 된 이슈}
주의사항   : {다음 세션이 반드시 알아야 할 것}
```

---

## 원칙 추가·수정 방법

1. `sessions/_shared/PRINCIPLES.md` 수정
2. 영향받는 세션의 `CLAUDE.md` 업데이트
3. `sessions/_shared/PRINCIPLES.md` 하단 변경 이력에 기록

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-05-04 | 최초 원칙 수립 (원칙 1~4) |
| 2026-05-07 | 원칙 6개로 확장 · overseer / stability 세션 추가 |
| 2026-05-08 | sentinel 세션 추가 · 경고 처리 프로세스 · sessions/ 폴더 전체 구조 완성 |
| 2026-05-08 | 팀원 영속성 모델 도입 · STATE.md 구조 추가 · 감시 세션 경고 대상 chief 전용 명확화 |
