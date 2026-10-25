# Pourlune 资源检查

在项目根目录运行。图像脚本需要 Python 3.11+ 与 Pillow；当前项目 `.venv` 没有 Pillow，可使用已发现的 Codex bundled Python：

```sh
/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tools/assets/visual_manifest.py --check
/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tools/assets/ui_manifest.py --check
/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m unittest discover -s tools/assets -v
```

安装有 Pillow 的其他 Python 也可运行相同命令；不要求生成原始 PNG 在另一台机器的用户目录中仍然存在。

`visual_manifest.py` 继续负责原23张背景、瓶层、场景和品牌源图；尺寸、格式、透明度、前窗和来源规则不变。新增的 `runtime/ui/` 子目录由 `ui_manifest.py` 独立负责，旧检查仅将该命名空间排除，其他未登记 PNG 仍拒绝。应同时运行两个 `--check`，不能用一个替代另一个。

`ui_manifest.py` 固定检查10张UI候选和10份App副本，写入 `docs/design/production-candidates/runtime/ui/manifest.json`：

- 名单完整性、尺寸/模式、SHA-256、重复内容及候选与运行副本逐字节一致。
- 7张生成图的选中输出哈希、来源记录与提示词链接；生成记录中提供的原稿参考哈希也核验。早期logo/green-frame/moon记录没有列出精确生成输入路径，清单保留此证据限制，不补造来源信息。
- 3张原稿纹理与原型副本逐字节一致，并与 `source-crops.json` 指定原稿区域逐像素一致。
- 从 `knit_components.dart` 的人工 `_art` 表读取8项画布尺寸和显示裁切范围；两张重复纹理使用完整画布。验证范围没有越界，并绑定源码哈希。这是运行显示几何，不是自动alpha裁图，也不改PNG。
- 全部素材保持 `production_candidate` 与权属 `UNCONFIRMED`；文件检查不授予商用权，也不代表Flutter、设备或独立视觉验收通过。

`--check` 只读取；`--write` 只刷新对应JSON清单。只有明确资源或人工显示几何变更后才运行相应 `--write`，先检查变更原因，不能用刷新掩盖意外漂移。UI清单不刷新或改动旧23张清单。

回归测试在临时目录注入丢文件、额外文件、副本漂移、错误尺寸/模式、来源摘要/提示词缺失、错误原稿裁切和越界/变化几何；不改正式素材。原有10项视觉资源测试保留。

音频脚本独立于图像检查，可用项目Python运行：

```sh
.venv/bin/python tools/assets/audio_generate.py --check
.venv/bin/python tools/assets/audio_verify.py
```

`audio_generate.py` 不带 `--check` 会生成音频，`export_icons.py` 会导出平台图标；只有明确资源变更任务才使用这些写入路径。

T-R01 native launch resources reuse `assets/art/ui/logo.png` with KnitArt's existing display bounds. `startup_assets.py` only crops/resizes/pads density outputs; it does not redraw art or change rights status. Use the bundled Pillow Python above:

```sh
python3 tools/assets/startup_assets.py          # exact output drift check
python3 -m unittest discover -s tools/assets -p test_startup_native.py -v
```

`--write` is only for an explicitly intended native startup resource update. It writes iOS 1x/2x/3x launch wordmarks and Android density wordmarks plus transparent 288dp system-icon canvases with a 176dp mark inside the 192dp safety circle. Existing Flutter UI art/manifests remain unchanged.
