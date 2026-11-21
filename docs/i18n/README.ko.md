# project-plan

[简体中文](../../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português (BR)](README.pt-BR.md)

세션을 넘어 프로젝트 상태를 유지하기 위한 Codex skill입니다. 프로젝트를 만들 때 한 번만 실행되어 `PLAN.md`를 생성하고, 저장소의 `AGENTS.md`에 규칙 블록을 기록합니다. 이후 세션은 `AGENTS.md`를 따르므로 이 skill을 다시 호출할 필요가 없습니다.

`git log`는 코드 변경 이력을, `PLAN.md`는 목표, 판단 이유, 현재 작업, 알려진 문제를 기록합니다.

## 요구 사항

- `AGENTS.md`를 지원하는 Codex(데스크톱 앱 또는 CLI)
- PowerShell 5.1 이상(스크립트 사용 시)

## 설치

```powershell
git clone https://github.com/LDPlong/project-plan.git
cd project-plan
powershell -File scripts/install.ps1
```

기본 설치 위치는 `~/.codex/skills/project-plan`입니다. 다른 위치에 설치하려면:

```powershell
powershell -File scripts/install.ps1 -Target D:\path\to\skills\project-plan
```

`skills/project-plan/` 폴더를 Codex skills 디렉터리로 직접 복사해도 됩니다.

## 사용법

### 1. 프로젝트 초기화

프로젝트 루트에서 Codex를 열고 다음과 같이 요청합니다.

```text
project-plan으로 이 프로젝트의 계획 목록을 초기화해 줘
```

skill은 다음 순서로 동작합니다.

1. `PLAN.md`와 `AGENTS.md`의 규칙 블록이 이미 있는지 확인하고, 둘 다 있으면 중단합니다.
2. 목표, 완료 기준, 범위 밖 항목을 확인합니다. 대화에서 추론할 수 없을 때만 질문합니다.
3. 프로젝트 루트에 `PLAN.md`를 작성합니다.
4. `references/AGENTS-block.md`를 `AGENTS.md`의 마커 블록에 기록합니다. 기존 블록은 교체합니다.
5. 섹션 구성, 진행 중 작업 수, 유효 줄 수를 검사합니다.

### 2. 평소대로 작업

세션이 시작되면 Codex가 `PLAN.md`를 읽고 「进行中」(진행 중) 항목부터 이어서 작업합니다. 작업이 끝나면 계획을 갱신하고 코드와 같은 commit에 포함합니다. 이후에는 skill 호출이 필요 없습니다.

### 3. 계획 검사(선택)

```powershell
powershell -File scripts/check-plan.ps1 -Path PLAN.md
```

출력 예:

```text
[OK] PLAN.md: 27/50 lines, in progress 1, todo 1
```

필수 섹션이 없거나, 목표가 비어 있거나, 진행 중 항목이 2개 이상이거나, 유효 줄 수가 50을 넘으면 종료 코드 `1`을 반환합니다.

## 프로젝트에 생성되는 파일

| 파일 | 내용 |
| --- | --- |
| `PLAN.md` | 목표, 범위, 현재 마일스톤, 작업, 결정, 문제 |
| `AGENTS.md` | 기존 내용 + 마커가 있는 규칙 블록 |

`PLAN.md`의 섹션 이름은 중국어로 고정되어 있습니다. 번역하면 검사 스크립트와 규칙 블록이 일치하지 않으므로 그대로 사용하세요.

| 섹션 | 내용 |
| --- | --- |
| `## 目标` | 한 문장 목표, 완료 기준 포함 |
| `## 非目标` | 명시적으로 하지 않을 일 |
| `## 当前里程碑` | 현재 마일스톤 이름 |
| `## 进行中` | 진행 중 작업, 최대 1개 |
| `## 待做` | 이후 작업 |
| `## 决策` | 날짜, 결정, 이유 |
| `## 坑` | 증상, 원인, 해결 |
| `## 归档` | 완료된 마일스톤, 한 줄에 하나 |

예시:

```markdown
## 目标
이메일 로그인을 지원한다. 신규 사용자가 3분 안에 가입과 로그인을 마치면 완료.

## 非目标
- 외부 ID 로그인은 이번 범위에서 제외

## 当前里程碑
M2 사용자 인증

## 进行中
- [ ] T3 로그인 API(JWT 발급 + 갱신)

## 待做
- [ ] T4 비밀번호 재설정(메일 서비스 의존)

## 决策
- 2026-11-21 session 대신 JWT 사용: 무상태 배포가 목표

## 坑
- prisma migrate는 로컬 PostgreSQL이 필요하다. 없으면 P1001 발생

## 归档
- M1 프로젝트 골격  완료(T1-T2, git log 참고)
```

## 계획 규칙

| 규칙 | 값 |
| --- | --- |
| 작업 단위 | commit 하나 |
| 진행 중 | 최대 1개 |
| 파일 길이 | 유효 줄 50줄 이내 |
| 결정 | 날짜와 이유 포함 |
| 완료 작업 | 마일스톤당 한 줄로 보관 |
| 계획과 git 불일치 | `git log` 우선 |

## 디렉터리 구조

```text
skills/project-plan/SKILL.md                      초기화 절차
skills/project-plan/references/PLAN-template.md   계획 템플릿
skills/project-plan/references/AGENTS-block.md    AGENTS.md에 기록할 규칙 블록
scripts/check-plan.ps1                            계획 검사
scripts/install.ps1                               skill 설치
.github/workflows/plan-check.yml                  CI: push와 pull request에서 검사
```

## FAQ

**skill이 실행되지 않습니다.**
skill은 설명으로 선택됩니다. "project-plan으로 계획 목록을 초기화해 줘"처럼 이름을 직접 지정하세요.

**새 세션이 PLAN.md를 읽지 않습니다.**
Codex 작업 디렉터리가 프로젝트 루트이거나 그 하위인지, `AGENTS.md`에 `<!-- project-plan:begin -->`과 `<!-- project-plan:end -->` 사이의 블록이 있는지 확인하세요. `~/.codex/AGENTS.md`에 다음 한 줄을 추가할 수도 있습니다.

```markdown
- 작업 디렉터리 또는 상위 디렉터리에 `PLAN.md`가 있으면 작업 시작 전에 「目标 / 进行中 / 决策 / 坑」을 읽는다. 없으면 무시한다.
```

**기존 AGENTS.md와 충돌하지 않나요?**
충돌하지 않습니다. 블록은 파일 끝에 추가되고 나머지 내용은 그대로 유지됩니다. 다시 실행하면 마커 안의 내용만 교체됩니다.

**PLAN.md는 어디에 두나요?**
프로젝트 루트입니다. 저장소마다 하나씩 두고, 전역 위치에는 두지 마세요.

**PLAN.md를 commit해야 하나요?**
네. 프로젝트 상태의 일부이므로 코드와 같이 리뷰해야 합니다.

**여러 프로젝트가 하나의 계획을 공유할 수 있나요?**
아니요. 프로젝트 루트마다 별도 파일입니다.

## 제거

1. `~/.codex/skills/project-plan`을 삭제합니다.
2. `AGENTS.md`에서 두 마커 사이의 블록을 삭제합니다.
3. 필요 없으면 `PLAN.md`를 삭제합니다.

## 라이선스

MIT