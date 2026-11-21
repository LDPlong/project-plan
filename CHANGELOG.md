# Changelog

## 0.2.0 - 2026-11-21

### Added

- 完成态检测：`进行中` / `待做` 中的 `- [x]` 会告警
- 陈旧度检测：`-MaxAgeDays`，默认 14 天，只告警不阻断
- 重复章节检测：同一 `##` 标题出现两次直接失败
- 验收标准告警：`目标` 中没有「验收」或 acceptance 时提示
- 多分支 / 多 agent 约定，以及「事实以 git、意图以 PLAN」的冲突处理
- README 增加手动初始化路径
- 自检脚本随 skill 一起分发

### Changed

- `非目标` 纳入必需章节，共 6 个：目标 / 非目标 / 进行中 / 待做 / 决策 / 坑
- `scripts/check-plan.ps1` 移到 `skills/project-plan/scripts/`
- 50 行超限处理写明：先归档里程碑，再把旧决策与坑移到 `docs/plan-archive.md`
- 安装脚本默认清理源中已删除的文件，可用 `-KeepExtra` 关闭
- CI 增加「改了源码但没更新 PLAN.md」的告警

## 0.1.0 - 2026-11-21

- 初始版本