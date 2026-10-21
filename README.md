# Pourlune

面向海外的离线单机解谜游戏。技术基线：Flutter、纯 Dart 核心、SQLite/sqflite；Firebase 与 AdMob 是可降级的外部服务。当前已建立 Flutter App 与纯 Dart 核心；B01 工程及离线切片通过独立验收，B02 完整离线流程已通过限定范围的独立验收；正式内容、美术、SDK 和发布验证按 B03–B05 推进。

代码仓库：[wangyule0379-max/Pourlune](https://github.com/wangyule0379-max/Pourlune)，主分支 `main`。包含产品文档、原设计档案、内容准备工具，以及已完成 D01–D09 静态设计和有限原型独立验收的 UI 增量、修复过程与验收证据。B01 已完成 iOS 实际操作、原生 SQLite 恢复和双端本机构建；详见 [B01 独立验收](docs/development/review/B01-acceptance.md)。

## 开工入口

- [正式开发批次与独立验收计划](docs/pmpowers/plans/2026-10-22-development-execution.md)：B01–B05 连续推进，当前状态见 [开发跟踪](docs/development/tracking.json)。

- [B02 离线流程交付](docs/development/deliveries/B02.md)：实现与运行证据；[独立验收报告](docs/development/review/B02-acceptance.md)记录通过范围和后续依赖。
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

当前仅有 2 / 3 / 4 色工程夹具，均非完整生产题库。发布模式检查会明确失败；没有自动把样本提升为正式内容。内容检查通过不代表 Dart、Flutter 或真实 SDK 测试通过。

`docs/design/original/` 保留原件；`ui-addendum/` 已通过限定范围的静态及原型验收；`production-candidates/` 是待运行验证的资源候选。不要混用。
