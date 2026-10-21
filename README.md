# Pourlune

面向海外的离线单机解谜游戏。技术基线：Flutter、纯 Dart 核心、SQLite/sqflite；Firebase 与 AdMob 是可降级的外部服务。B01／B02 已通过限定范围独立验收。B03 已接入60主线＋30每日候选、分层美术、Nunito和本地音频，R01视觉／R02结算音效经第二轮独立复验关闭，已通过本批限定开发与iOS模拟器验收；SDK与发布验证按 B04–B05 推进。

代码仓库：[wangyule0379-max/Pourlune](https://github.com/wangyule0379-max/Pourlune)，主分支 `main`。包含产品文档、原设计档案、内容准备工具，以及已完成 D01–D09 静态设计和有限原型独立验收的 UI 增量、修复过程与验收证据。B01 已完成 iOS 实际操作、原生 SQLite 恢复和双端本机构建；详见 [B01 独立验收](docs/development/review/B01-acceptance.md)。

## 开工入口

- [正式开发批次与独立验收计划](docs/pmpowers/plans/2026-10-22-development-execution.md)：B01–B05 连续推进，当前状态见 [开发跟踪](docs/development/tracking.json)。

- [B02 离线流程交付](docs/development/deliveries/B02.md)：实现与运行证据；[独立验收报告](docs/development/review/B02-acceptance.md)记录通过范围和后续依赖。
- [B03 内容与视觉交付](docs/development/deliveries/B03.md)：90题校验、资源来源与首轮运行证据；最新[R01/R02修复交付](docs/development/evidence/B03-R01/repair-report.md)含101项Flutter回归、23项资源测试、25张原生配对证据及真实边界，非独立验收报告；当前结论见[B03独立验收](docs/development/review/B03-acceptance.md)。
- [协作约定](AGENTS.md)
- [开发准备与真实缺口](docs/pmpowers/specs/development-readiness.md)
- [产品规格](docs/pmpowers/specs/PRD-supplement-v1.1.md) · [技术方案](docs/pmpowers/specs/technical-architecture-v1.0.md) · [数据契约](docs/pmpowers/specs/data-contracts-v1.0.md)
- [AC 验收要求](docs/pmpowers/specs/acceptance-and-content-readiness.md)
- [正式资源、服务资料与首个闭环交接](docs/pmpowers/specs/production-handoff.md)
- [工具链实查](docs/pmpowers/specs/toolchain-check-2026-10-21.md)
- [UI 独立验收报告](docs/design/review/ui-addendum-acceptance.md)

## 已可运行的检查

Flutter 客户端位于 [app/](app/README.md)，核心位于 `packages/pourlune_core/`；固定 Flutter 3.47.2 / Dart 3.13.2。实际测试与构建命令见 [AGENTS.md](AGENTS.md)。开发分支为 `codex/offline-foundation`。

按 [内容工具说明](tools/content/README.md) 建立 Python 3.11+ 的 .venv 并安装固定依赖后，在根目录执行：

```sh
.venv/bin/python -m unittest discover -s tools/content -v
.venv/bin/python tools/content/validate.py docs/content/fixtures/*.json
```

工程夹具仍非生产题库，不能通过发布门槛。B03 独立候选位于 `docs/content/production-candidates/`，相应release＋catalog校验90题通过；运行副本有确定性检查。用法见内容工具说明。候选身份和内容回放不等于真人难度、独立视觉或发布通过。

`docs/design/original/` 保留原件；`ui-addendum/` 已通过限定范围静态及原型验收；`production-candidates/` 保存有来源记录的候选，其中B03运行资源已有本次模拟器验证，本批限定视觉已独立通过，商业权属仍待确认。不要混用这些状态。
