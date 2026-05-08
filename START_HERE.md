# 세션 시작 가이드

이 파일을 읽고 있다면 아래 순서대로 준비한다.
준비가 완료되면 사용자에게 "[준비 완료]" 보고 후 지시를 기다린다.

---

## 이 레포의 역할

`C-o-T/PRINCIPLES` 는 **AI 멀티 세션 원칙 시스템 템플릿**이다.

| 레포 | 역할 | 포함 파일 |
|------|------|-----------|
| `C-o-T/PRINCIPLES` | 원칙·설정 전용 (pull만) | AGENT_PRINCIPLES.md, CLAUDE.md, sessions/{role}/CLAUDE.md |
| `C-o-T/{프로젝트명}-ai` | 프로젝트별 상태 전용 (push/pull) | STATE.md, ACTIVE_CONTEXT.md, PROJECT_CONTEXT.md |

**PRINCIPLES 레포에는 절대 push하지 않는다.**
모든 작업 상태(STATE.md, ACTIVE_CONTEXT.md)는 프로젝트 레포에만 저장한다.

---

## 1단계 — 파일 다운로드

아직 로컬에 없다면:

```
git clone https://github.com/C-o-T/PRINCIPLES
```

이미 있다면:

```
git pull
```

---

## 2단계 — 프로젝트 레포 준비

작업할 프로젝트가 있다면 해당 프로젝트의 AI 상태 레포를 클론/풀한다.

```bash
# 기존 프로젝트 (이어서 작업):
git clone https://github.com/C-o-T/{프로젝트명}-ai
# 또는
cd {프로젝트명}-ai && git pull

# 새 프로젝트 (최초):
# chief가 자동으로 GitHub에 {프로젝트명}-ai 레포를 생성한다.
```

현재 운영 중인 프로젝트 레포:

| 프로젝트 | GitHub 레포 | 설명 |
|----------|------------|------|
| joomidang | `C-o-T/joomidang-ai` | 역직구 전통주 플랫폼 |
| dataverse | `C-o-T/dataverse-ai` | 데이터 수집·가공 인프라 |

---

## 3단계 — 필수 파일 읽기 (순서대로)

아래 5개 파일을 순서대로 읽는다. 모두 읽기 전에 작업을 시작하지 않는다.

**PRINCIPLES 레포에서 읽기:**
1. `AGENT_PRINCIPLES.md` — 운영 원칙 전체
2. `sessions/chief/CLAUDE.md` — chief 역할 정의

**프로젝트 레포에서 읽기 (프로젝트 레포가 있을 때):**
3. `sessions/chief/STATE.md` — chief 개인 기억 (없으면 최초 투입 — 빈 파일 생성)
4. `sessions/_shared/PROJECT_CONTEXT.md` — 프로젝트 기술 컨텍스트
5. `sessions/_shared/ACTIVE_CONTEXT.md` — 현재 진행 중인 작업 상태

프로젝트 레포가 없을 때: PRINCIPLES 레포 읽기(1~2)만 완료 후, 어떤 프로젝트를 시작할지 사용자에게 확인한다.

---

## 4단계 — 필수 파일 존재 여부 확인

**PRINCIPLES 레포에 있어야 할 파일:**

```
AGENT_PRINCIPLES.md
CLAUDE.md
START_HERE.md
sessions/_shared/PRINCIPLES.md
sessions/chief/CLAUDE.md          sessions/planner/CLAUDE.md
sessions/developer/CLAUDE.md      sessions/rca/CLAUDE.md
sessions/okr/CLAUDE.md            sessions/data/CLAUDE.md
sessions/content-qa/CLAUDE.md     sessions/perf/CLAUDE.md
sessions/overseer/CLAUDE.md       sessions/stability/CLAUDE.md
sessions/sentinel/CLAUDE.md
```

**프로젝트 레포에 있어야 할 파일:**

```
sessions/_shared/ACTIVE_CONTEXT.md
sessions/_shared/PROJECT_CONTEXT.md
sessions/chief/STATE.md
sessions/planner/STATE.md          sessions/developer/STATE.md
sessions/rca/STATE.md              sessions/okr/STATE.md
sessions/data/STATE.md             sessions/content-qa/STATE.md
sessions/perf/STATE.md             sessions/overseer/STATE.md
sessions/stability/STATE.md        sessions/sentinel/STATE.md
```

파일이 하나라도 없으면 git pull을 다시 실행한다.

---

## 주의사항

- **PRINCIPLES 레포**는 pull 전용이다 — 절대 push하지 않는다.
- **프로젝트 레포**는 push/pull 모두 사용한다 — 모든 상태 파일이 여기에만 저장된다.
- `sessions/{role}/STATE.md`는 해당 역할 세션 본인만 수정한다.
- 작업 완료 후 반드시 해당 STATE.md와 ACTIVE_CONTEXT.md를 갱신하고 종료한다.

---

## 준비 완료 보고 형식

파일을 모두 읽은 후 아래 형식으로 보고한다.

```
[준비 완료]
읽은 파일   : AGENT_PRINCIPLES.md / chief/CLAUDE.md / chief/STATE.md /
              PROJECT_CONTEXT.md / ACTIVE_CONTEXT.md
작업 프로젝트: {프로젝트명 또는 "미정"}
이전 작업   : {ACTIVE_CONTEXT에서 파악한 미완료 사항 요약, 없으면 "없음"}
대기 중     : 지시를 기다립니다.
```
