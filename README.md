# Pourlune

面向海外的离线单机解谜游戏。技术基线：Flutter、纯 Dart 核心、SQLite/sqflite；Firebase 与 AdMob 是可降级的外部服务。当前处于开发准备阶段，尚无 Flutter App 工程。

代码仓库：[wangyule0379-max/Pourlune](https://github.com/wangyule0379-max/Pourlune)，主分支 `main`。首批提交包含产品文档、原设计档案、独立验收记录和内容准备工具；仍在修复的 UI 增量目录暂未纳入，待后续单独提交。

## 开工入口

- [协作约定](AGENTS.md)
- [开发准备与真实缺口](docs/pmpowers/specs/development-readiness.md)
- [产品规格](docs/pmpowers/specs/PRD-supplement-v1.1.md) · [技术方案](docs/pmpowers/specs/technical-architecture-v1.0.md) · [数据契约](docs/pmpowers/specs/data-contracts-v1.0.md)
- [AC 验收要求](docs/pmpowers/specs/acceptance-and-content-readiness.md)
- [正式资源、服务资料与首个闭环交接](docs/pmpowers/specs/production-handoff.md)
- [工具链实查](docs/pmpowers/specs/toolchain-check-2026-10-21.md)
- [UI 独立验收报告](docs/design/review/ui-addendum-acceptance.md)

## 已可运行的检查

按 [内容工具说明](tools/content/README.md) 建立 Python 3.11+ 的 .venv 并安装固定依赖后，在根目录执行：

```sh
.venv/bin/python -m unittest discover -s tools/content -v
.venv/bin/python tools/content/validate.py docs/content/fixtures/*.json
```

当前仅有 2 / 3 / 4 色工程夹具，均非完整生产题库。发布模式检查会明确失败；没有自动把样本提升为正式内容。内容检查通过不代表 Dart、Flutter 或真实 SDK 测试通过。

`docs/design/original/` 保留原件；`ui-addendum/` 属于正在修复的设计交付；`production-candidates/` 是待运行验证的资源候选。不要混用。
