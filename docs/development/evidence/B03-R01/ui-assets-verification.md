# B03-R01 UI 资源清单与校验证据

2026-10-22；项目根目录执行。本交付只检查图像与来源/显示几何，不修改 PNG、Flutter 源码、原稿、独立审查、追踪或主交付文档；无 stage、commit、push。

当前 UI 命名空间含10张：`calendar`、`chapters`、`cream-frame`、`cream-tile`、`green-frame`、`green-tile`、`logo`、`moon`、`patch-tile`、`success`。7张 RGBA 生成图和3张 RGB 原稿纹理，10份候选与10份App副本逐字节一致，无重复内容。尺寸、模式、字节数、SHA-256、来源证据、人工运行裁切范围详见 `docs/design/production-candidates/runtime/ui/manifest.json`。

`ui_manifest.py` 从 `knit_components.dart` 的 `_art` 表读取8项 Size/Rect，并核对尺寸及边界；cream/green重复纹理使用完整画布。显示范围是已在Flutter源码人工指定的几何，不是自动alpha裁切，也不证明视觉正确。清单绑定完整源码哈希；后续明确几何/源码变动须先检查原因再显式刷新。

3张纹理均与 `docs/design/ui-addendum/assets/` 原型副本字节一致，并逐像素比对 `source-crops.json` 指定的原稿区域。生成素材链接既有选中输出哈希、提示词和生成记录。早期 `logo`、`green-frame`、`moon` 的 root 记录没有列出精确输入文件路径，清单明确保留限制，没有补造输入路径。外部用户目录中的原始生成路径仅作归档元数据，跨机器检查不依赖该路径存在。

旧 `visual_manifest.py` 只增加对独立 `ui/` 命名空间的排除；原23张名单、尺寸、模式、alpha、前窗、来源、哈希和其他额外PNG拒绝规则不变。原有10项测试文件未修改。必须同时执行两份清单检查，UI额外/遗漏文件由独立UI检查拒绝，不能仅运行旧清单代表完整检查。

使用带Pillow的 bundled Python：`/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3`。项目 `.venv` 当前没有Pillow；未安装或修改依赖。下表命令的 `python` 均指该实际解释器。

| 实际命令 | 结果 | 日志 |
|---|---|---|
| `python -m unittest discover -s tools/assets -v`，实现前 | RED：UI工具尚不存在；旧23扫描把新UI视为额外文件，10项既有测试中8项因此被阻断/失败 | `ui-assets-red.log` |
| `python tools/assets/ui_manifest.py --write` | 退出0，仅写UI清单JSON，10张/10副本 | `ui-assets-write.log` |
| `python -m unittest discover -s tools/assets -v`，最终 | 退出0，23/23；既有10项＋新增13项 | `ui-assets-tests.log` |
| `python tools/assets/ui_manifest.py --check`，最终 | 退出0，10张UI/10副本；rights UNCONFIRMED | `ui-assets-check.log` |
| `python tools/assets/visual_manifest.py --check`，最终 | 退出0，原23张/22副本；旧清单未刷新 | `ui-assets-legacy-check.log` |

新增测试使用临时副本注入遗漏/额外文件（候选和运行两侧）、副本漂移、双侧替换、尺寸/模式错误、生成记录摘要和提示词缺失、越界显示裁切、原稿区域像素变化和几何漂移。测试确保即使更新参考摘要，错误原稿裁切像素仍被拒绝；所有破坏操作只发生于临时目录。

所有UI素材保持 `production_candidate`，权属 **UNCONFIRMED**。本证据不是视觉、Flutter运行、设备、SDK、音频、性能或商业使用权通过；Flutter整合验证由根任务统一执行。运行命令和刷新边界同步写入 `tools/assets/README.md`。
