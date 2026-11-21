# project-plan

[简体中文](README.md) · [English](docs/i18n/README.en.md) · [日本語](docs/i18n/README.ja.md) · [한국어](docs/i18n/README.ko.md) · [Español](docs/i18n/README.es.md) · [Português (BR)](docs/i18n/README.pt-BR.md)

一个用于跨会话保存项目状态的 Codex skill。它只在项目建立时运行一次：生成 `PLAN.md`，并把规则块写入仓库的 `AGENTS.md`。之后的会话按 `AGENTS.md` 执行，不再调用这个 skill。

`git log` 记录代码改了什么，`PLAN.md` 记录目标、决策理由、当前任务和已踩过的坑。

## 运行要求

- 支持 `AGENTS.md` 的 Codex（桌面端或 CLI）
- PowerShell 5.1 及以上（仅脚本需要）

## 安装

```powershell
git clone https://github.com/LDPlong/project-plan.git
cd project-plan
powershell -File scripts/install.ps1
```

默认安装到 `~/.codex/skills/project-plan`。安装到其他位置：

```powershell
powershell -File scripts/install.ps1 -Target D:\path\to\skills\project-plan
```

也可以手动把 `skills/project-plan/` 复制到 Codex 的 skills 目录。

## 使用

### 1. 初始化项目

在项目根目录打开 Codex，发送：

```text
用 project-plan 初始化这个项目的计划清单
```

skill 依次执行：

1. 检查 `PLAN.md` 和 `AGENTS.md` 规则块是否已存在，都存在则停止。
2. 确认目标、验收标准和非目标；无法从对话中推断时才提问。
3. 在项目根目录生成 `PLAN.md`。
4. 把 `references/AGENTS-block.md` 写入 `AGENTS.md` 的标记块；已有块则整块替换。
5. 自查章节、进行中任务数量和有效行数。

### 2. 正常工作

会话开始时，Codex 读取 `PLAN.md` 并从「进行中」继续。任务完成后更新清单，与代码放在同一个 commit。后续不需要再调用 skill。

### 3. 检查清单（可选）

```powershell
powershell -File scripts/check-plan.ps1 -Path PLAN.md
```

输出示例：

```text
[OK] PLAN.md: 27/50 lines, in progress 1, todo 1
```

缺少章节、目标为空、进行中超过 1 条、有效行数超过 50 时，脚本返回退出码 `1`。

## 项目中生成的文件

| 文件 | 内容 |
| --- | --- |
| `PLAN.md` | 目标、范围、当前里程碑、任务、决策、坑 |
| `AGENTS.md` | 原有内容 + 一个带标记的规则块 |

`PLAN.md` 的章节名固定为中文，不要翻译，否则检查脚本和规则块无法匹配。

| 章节 | 内容 |
| --- | --- |
| `## 目标` | 一句话目标，包含验收方式 |
| `## 非目标` | 明确不做的事 |
| `## 当前里程碑` | 当前阶段名称 |
| `## 进行中` | 最多 1 条任务 |
| `## 待做` | 后续任务 |
| `## 决策` | 日期 + 结论 + 理由 |
| `## 坑` | 现象 → 原因 → 解法 |
| `## 归档` | 已完成里程碑，一行一个 |

示例：

```markdown
## 目标
支持邮箱登录；验收：新用户 3 分钟内完成注册并登录。

## 非目标
- 暂不支持第三方登录

## 当前里程碑
M2 用户认证

## 进行中
- [ ] T3 登录接口（JWT 签发 + 刷新）

## 待做
- [ ] T4 密码重置（依赖邮件服务）

## 决策
- 2026-11-21 用 JWT 不引 session：目标是无状态部署

## 坑
- prisma migrate 必须先起本地 PG：否则报 P1001

## 归档
- M1 骨架搭建 已完成（T1-T2，见 git log）
```

## 清单规则

| 规则 | 取值 |
| --- | --- |
| 任务粒度 | 一条 commit |
| 进行中 | 最多 1 条 |
| 文件长度 | 有效行数不超过 50 |
| 决策 | 带日期和理由 |
| 已完成任务 | 每个里程碑折成一行归档 |
| 清单与 git 冲突 | 以 `git log` 为准 |

## 目录结构

```text
skills/project-plan/SKILL.md                      初始化流程
skills/project-plan/references/PLAN-template.md   清单模板
skills/project-plan/references/AGENTS-block.md    写入 AGENTS.md 的规则块
scripts/check-plan.ps1                            清单检查
scripts/install.ps1                               安装 skill
.github/workflows/plan-check.yml                  CI：push / PR 时运行检查
```

## 常见问题

**skill 没有触发怎么办？**
skill 按描述匹配。直接点名：「用 project-plan 初始化这个项目的计划清单」。

**新会话没有读取 PLAN.md？**
确认 Codex 的工作目录在项目根目录或其子目录，并检查 `AGENTS.md` 中是否存在 `<!-- project-plan:begin -->` 和 `<!-- project-plan:end -->` 之间的规则块。也可以在 `~/.codex/AGENTS.md` 加一行兜底：

```markdown
- 若当前工作目录或任一上级目录存在 `PLAN.md`，任务开始前先读它的「目标 / 进行中 / 决策 / 坑」；不存在则忽略此条。
```

**项目里已经有 AGENTS.md 会不会冲突？**
不会。规则块追加在文件末尾，其他内容保持不变；重复执行只替换标记块内的内容。

**PLAN.md 应该放在哪里？**
项目根目录，一个仓库一份，不要放到全局目录。

**PLAN.md 需要提交吗？**
需要。它属于项目状态，应该和代码一样被 review。

**多个项目可以共用一份清单吗？**
不可以。每个项目根目录各自一份。

## 卸载

1. 删除 `~/.codex/skills/project-plan`。
2. 删除 `AGENTS.md` 中两个标记之间的规则块。
3. 如不再需要，删除 `PLAN.md`。

## License

MIT