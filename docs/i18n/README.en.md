# project-plan

[简体中文](../../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português (BR)](README.pt-BR.md)

A Codex skill that keeps project state across sessions. It runs once, when a project is created: it writes `PLAN.md` and adds a rule block to the repository's `AGENTS.md`. Later sessions follow `AGENTS.md`; the skill is not called again.

`git log` records what changed in the code. `PLAN.md` records the goal, the reasons behind decisions, the current task, and known pitfalls.

## Requirements

- Codex with `AGENTS.md` support (desktop app or CLI)
- PowerShell 5.1 or later, for the scripts
- Version 0.2.0; see `CHANGELOG.md`

## Installation

```powershell
git clone https://github.com/LDPlong/project-plan.git
cd project-plan
powershell -File scripts/install.ps1
```

The default target is `~/.codex/skills/project-plan`. To install somewhere else:

```powershell
powershell -File scripts/install.ps1 -Target D:\path\to\skills\project-plan
```

You can also copy `skills/project-plan/` into your Codex skills directory manually.

### Manual setup (no skill required)

If the skill does not run, or you prefer not to let the agent do it, initialize in three steps:

1. Copy `skills/project-plan/references/PLAN-template.md` to `PLAN.md` in the project root and fill it in.
2. Append `skills/project-plan/references/AGENTS-block.md` to the project's `AGENTS.md`; create the file if it does not exist.
3. Run `powershell -File skills/project-plan/scripts/check-plan.ps1 -Path PLAN.md`.

## Usage

### 1. Initialize a project

Open the project root in Codex and send:

```text
Initialize the project plan with the project-plan skill.
```

The skill performs these steps:

1. Checks whether `PLAN.md` and the `AGENTS.md` rule block already exist. If both exist, it stops.
2. Confirms the goal, acceptance criteria, and out-of-scope items. It asks only when these cannot be inferred from the conversation.
3. Writes `PLAN.md` in the project root.
4. Writes `references/AGENTS-block.md` into the marked block in `AGENTS.md`, replacing an existing block.
5. Runs its bundled `scripts/check-plan.ps1` against the new `PLAN.md`.

### 2. Work normally

At the start of a session, Codex reads `PLAN.md` and continues from the item under "进行中" (in progress). When a task is finished, the plan is updated and committed together with the code. No further skill calls are needed.

### 3. Check the plan (optional)

```powershell
powershell -File skills/project-plan/scripts/check-plan.ps1 -Path PLAN.md
```

Example output:

```text
[OK] PLAN.md: 29/50 lines, in progress 1, todo 1, warnings 0
```

The script checks the following.

Fails (exit code `1`):

- A required section is missing: 目标 / 非目标 / 进行中 / 待做 / 决策 / 坑
- A section heading appears more than once
- 目标 is empty or still a placeholder
- 进行中 has two or more unchecked tasks
- Non-empty lines exceed 50

Warns (exit code unchanged):

- 当前里程碑 is missing
- 进行中 has no unchecked task, or still contains `- [x]`
- 待做 still contains `- [x]`
- 目标 has no "验收" or "acceptance" wording
- A task is in progress and the file has not changed for 14 days (`-MaxAgeDays 0` disables this)

"Effective lines" means non-empty lines.

## Files created in a project

| File | Content |
| --- | --- |
| `PLAN.md` | Goal, scope, current milestone, tasks, decisions, pitfalls |
| `AGENTS.md` | Existing content plus one marked rule block |

Section names in `PLAN.md` are fixed and written in Chinese. Do not translate them, or the checker and the rule block will not match.

| Section | Content |
| --- | --- |
| `## 目标` | One-sentence goal, including how completion is verified |
| `## 非目标` | Items explicitly out of scope |
| `## 当前里程碑` | Name of the current stage |
| `## 进行中` | At most one task |
| `## 待做` | Upcoming tasks |
| `## 决策` | Date, decision, reason |
| `## 坑` | Symptom, cause, fix |
| `## 归档` | Completed milestones, one per line |

Example:

```markdown
## 目标
Support email sign-in; done when a new user can register and sign in within three minutes.

## 非目标
- No third-party sign-in for now

## 当前里程碑
M2 User authentication

## 进行中
- [ ] T3 Sign-in endpoint (JWT issue + refresh)

## 待做
- [ ] T4 Password reset (depends on the mail service)

## 决策
- 2026-11-21 JWT instead of sessions: the deployment target is stateless

## 坑
- prisma migrate needs a local PostgreSQL instance, otherwise P1001

## 归档
- M1 Project skeleton completed (T1-T2, see git log)
```

## Plan rules

| Rule | Value |
| --- | --- |
| Task size | One commit |
| In progress | At most one item on the main branch |
| File length | 50 non-empty lines or fewer |
| Decisions | Include date and reason |
| Completed tasks | One archive line per milestone |
| Over the limit | Archive milestones first, then move old decisions and pitfalls to `docs/plan-archive.md` |
| Branches | Each branch keeps its own `进行中`; the main branch collapses it to one item on merge |
| Plan vs. git | Facts come from `git log`, intent comes from `PLAN.md`; confirm conflicts manually |

## Repository layout

```text
skills/project-plan/SKILL.md                        Initialization procedure
skills/project-plan/references/PLAN-template.md     Plan template
skills/project-plan/references/AGENTS-block.md      Rule block for AGENTS.md
skills/project-plan/scripts/check-plan.ps1          Plan checker (installed with the skill)
scripts/install.ps1                                 Skill installer, cleans removed files
.github/workflows/plan-check.yml                    CI: plan check + missing-update warning
CHANGELOG.md                                        Version history
```

## FAQ

**The skill did not run.**
Skills are selected by description. Name it explicitly: "Initialize the project plan with the project-plan skill." If that still fails, use the manual setup above.

**A new session does not read PLAN.md.**
Make sure Codex starts in the project root or a subdirectory, and that `AGENTS.md` contains the block between `<!-- project-plan:begin -->` and `<!-- project-plan:end -->`. You can also add a fallback line to `~/.codex/AGENTS.md`:

```markdown
- If PLAN.md exists in the working directory or any parent directory, read its 目标 / 进行中 / 决策 / 坑 sections before starting a task; ignore this rule otherwise.
```

**The project already has an AGENTS.md. Will it conflict?**
No. The block is appended at the end of the file and the rest is left unchanged. Re-running replaces only the content between the markers.

**Where should PLAN.md live?**
In the project root. One file per repository. Do not use a global location.

**Should PLAN.md be committed?**
Yes. It is part of the project state and should be reviewed like code. In a public repository the plan also becomes public history; if that is not acceptable, use a private repository or add `PLAN.md` to `.gitignore` (cross-session state then only exists locally).

**Can several projects share one plan?**
No. Each project root has its own file.

## Uninstall

1. Delete `~/.codex/skills/project-plan`.
2. Remove the block between the two markers in `AGENTS.md`.
3. Delete `PLAN.md` if it is no longer needed.

## License

MIT