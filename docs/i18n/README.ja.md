# project-plan

[简体中文](../../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português (BR)](README.pt-BR.md)

セッションをまたいでプロジェクト状態を保つための Codex skill です。プロジェクト作成時に一度だけ実行し、`PLAN.md` を生成して、リポジトリの `AGENTS.md` にルールブロックを書き込みます。以降のセッションは `AGENTS.md` に従うため、この skill を再度呼び出す必要はありません。

`git log` はコードの変更履歴を、`PLAN.md` は目標、判断理由、現在のタスク、既知の落とし穴を記録します。

## 必要な環境

- `AGENTS.md` に対応した Codex（デスクトップ版または CLI）
- PowerShell 5.1 以上（スクリプトを使う場合のみ）
- バージョン 0.2.0（変更履歴は `CHANGELOG.md`）

## インストール

```powershell
git clone https://github.com/LDPlong/project-plan.git
cd project-plan
powershell -File scripts/install.ps1
```

既定のインストール先は `~/.codex/skills/project-plan` です。別の場所に置く場合：

```powershell
powershell -File scripts/install.ps1 -Target D:\path\to\skills\project-plan
```

`skills/project-plan/` を Codex の skills ディレクトリへ手動でコピーしても構いません。

### 手動セットアップ（skill を使わない）

skill が実行されない場合や、agent に任せたくない場合は、次の 3 ステップで初期化できます。

1. `skills/project-plan/references/PLAN-template.md` をプロジェクトのルートに `PLAN.md` としてコピーし、記入します。
2. `skills/project-plan/references/AGENTS-block.md` をプロジェクトの `AGENTS.md` の末尾に追加します。ファイルがなければ作成します。
3. `powershell -File skills/project-plan/scripts/check-plan.ps1 -Path PLAN.md` を実行します。

## 使い方

### 1. プロジェクトの初期化

プロジェクトのルートで Codex を開き、次のように依頼します。

```text
project-plan でこのプロジェクトの計画リストを初期化してください
```

skill は次の順に処理します。

1. `PLAN.md` と `AGENTS.md` のルールブロックが既にあるか確認し、両方あれば停止します。
2. 目標、完了条件、対象外を確認します。会話から読み取れない場合のみ質問します。
3. プロジェクトのルートに `PLAN.md` を生成します。
4. `references/AGENTS-block.md` を `AGENTS.md` のマーカーブロックへ書き込みます。既存のブロックは置き換えます。
5. 同梱の `scripts/check-plan.ps1` を新しい `PLAN.md` に対して実行します。

### 2. 通常の作業

セッション開始時に Codex が `PLAN.md` を読み、「进行中」（進行中）の項目から作業を続けます。タスク完了時は計画を更新し、コードと同じ commit に含めます。以降 skill の呼び出しは不要です。

### 3. 計画の検査（任意）

```powershell
powershell -File skills/project-plan/scripts/check-plan.ps1 -Path PLAN.md
```

出力例：

```text
[OK] PLAN.md: 29/50 lines, in progress 1, todo 1, warnings 0
```

検査内容は次のとおりです。

失敗（終了コード `1`）：

- 必須の章がない：目标 / 非目标 / 进行中 / 待做 / 决策 / 坑
- 同じ章見出しが複数回出現する
- 目标 が空、またはプレースホルダーのまま
- 进行中 に未完了タスクが 2 件以上ある
- 非空行が 50 行を超える

警告（終了コードには影響しません）：

- 当前里程碑 がない
- 进行中 に未完了タスクがない、または `- [x]` が残っている
- 待做 に `- [x]` が残っている
- 目标 に「验收」または acceptance がない
- 进行中 のタスクがある状態で、14 日以上更新されていない（`-MaxAgeDays 0` で無効化）

「有效行数」は非空行数を指します。

## プロジェクト内に作られるファイル

| ファイル | 内容 |
| --- | --- |
| `PLAN.md` | 目標、範囲、現在のマイルストーン、タスク、判断、落とし穴 |
| `AGENTS.md` | 既存の内容 + マーカー付きルールブロック |

`PLAN.md` の章名は中国語で固定です。翻訳すると検査スクリプトとルールブロックが一致しなくなるため、そのまま使用してください。

| 章 | 内容 |
| --- | --- |
| `## 目标` | 目標を一文で。完了条件を含める |
| `## 非目标` | 対象外の項目 |
| `## 当前里程碑` | 現在のマイルストーン名 |
| `## 进行中` | 進行中のタスク（最大 1 件） |
| `## 待做` | 今後行うタスク |
| `## 决策` | 日付、判断、理由 |
| `## 坑` | 症状、原因、対処 |
| `## 归档` | 完了したマイルストーンを 1 行ずつ |

記入例：

```markdown
## 目标
メールアドレスでログインできるようにする。新規ユーザーが 3 分以内に登録とログインを完了できたら完了。

## 非目标
- 外部 ID によるログインは今回対象外

## 当前里程碑
M2 ユーザー認証

## 进行中
- [ ] T3 ログイン API（JWT の発行と更新）

## 待做
- [ ] T4 パスワード再設定（メール送信基盤に依存）

## 决策
- 2026-11-21 JWT を採用し session は使わない：ステートレスなデプロイが目的

## 坑
- prisma migrate はローカルの PostgreSQL が必要。未起動だと P1001 になる

## 归档
- M1 プロジェクト基盤 完了（T1-T2、git log 参照）
```

## 計画のルール

| ルール | 値 |
| --- | --- |
| タスクの粒度 | commit 1 回分 |
| 進行中 | メインブランチで最大 1 件 |
| ファイル長 | 非空行 50 行以内 |
| 判断 | 日付と理由を書く |
| 完了タスク | マイルストーンごとに 1 行へ集約 |
| 上限超過 | 先にマイルストーンをアーカイブし、古い判断と落とし穴を `docs/plan-archive.md` へ移す |
| ブランチ | 各ブランチが自分の「进行中」を管理し、マージ時にメインブランチで 1 件に収束させる |
| 計画と git の不一致 | 事実は `git log`、意図は `PLAN.md`。矛盾は人が確認する |

## ディレクトリ構成

```text
skills/project-plan/SKILL.md                       初期化手順
skills/project-plan/references/PLAN-template.md    計画テンプレート
skills/project-plan/references/AGENTS-block.md     AGENTS.md に書き込むルールブロック
skills/project-plan/scripts/check-plan.ps1         計画の検査（skill に同梱）
scripts/install.ps1                                skill のインストールと不要ファイルの削除
scripts/verify-skill.ps1                           検査スクリプトの自己テスト（15 ケース）
.github/workflows/plan-check.yml                   CI：計画検査 + 未更新の警告
CHANGELOG.md                                       変更履歴
```

## FAQ

**skill が実行されません。**
skill は説明文で選択されます。「project-plan で計画リストを初期化してください」のように名前を明示してください。それでも実行されない場合は、上記の手動セットアップを使ってください。

**新しいセッションが PLAN.md を読みません。**
Codex の作業ディレクトリがプロジェクトのルートかその配下にあること、`AGENTS.md` に `<!-- project-plan:begin -->` と `<!-- project-plan:end -->` のブロックがあることを確認してください。`~/.codex/AGENTS.md` に次の 1 行を追加する方法もあります。

```markdown
- 作業ディレクトリまたは上位ディレクトリに `PLAN.md` があれば、タスク開始前に「目标 / 进行中 / 决策 / 坑」を読む。なければ無視する。
```

**既存の AGENTS.md と競合しませんか。**
競合しません。ブロックはファイル末尾に追加され、他の内容は変更されません。再実行時はマーカー内だけが置き換わります。

**PLAN.md はどこに置きますか。**
プロジェクトのルートです。リポジトリごとに 1 ファイルとし、グローバルな場所には置かないでください。

**PLAN.md は commit しますか。**
はい。プロジェクト状態の一部として、コードと同じようにレビューしてください。公開リポジトリでは計画内容も公開履歴に残ります。それが困る場合はプライベートリポジトリを使うか、`PLAN.md` を `.gitignore` に追加してください（その場合、セッション間の状態はローカルにのみ残ります）。

**複数のプロジェクトで 1 つの計画を共有できますか。**
できません。プロジェクトのルートごとに 1 ファイルです。

## アンインストール

1. `~/.codex/skills/project-plan` を削除します。
2. `AGENTS.md` の 2 つのマーカーの間のブロックを削除します。
3. 不要であれば `PLAN.md` を削除します。

## ライセンス

MIT