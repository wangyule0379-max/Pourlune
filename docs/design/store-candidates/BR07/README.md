# BR07 本地商店素材候选

**local-candidate / UNCONFIRMED / not-approved-for-publication**。两张成品仅供本地审查；商业权属仍未确认，未上传商店或支持站。这不是App截图、正式运行证据或商店接受结论。

|输出|格式|用途|
|---|---|---|
|[play-icon-512.png](play-icon-512.png)|512×512、RGBA8（32-bit PNG）、379,110bytes|现有1024AppIcon整幅LANCZOS缩小，无裁边、无新增圆角蒙版；alpha恒255|
|[feature-graphic-1024x500.png](feature-graphic-1024x500.png)|1024×500、RGB8（24-bit PNG无alpha）、560,872bytes|既有天蓝背景、针织字标、Color Studio场景与5物件的宣传排版，包含两行短句|

准确文案：`Match colors, uncover cozy scenes`，视觉分行为`Match colors,`与`uncover cozy scenes`。没有价格、排名、评论、商店徽章、广告奖励或性能承诺。完整场景只表达可收集的场景美术，不表示某玩家已解锁或当前App截图。建议替代文字：`Pourlune's knitted wordmark and an assembled Color Studio scene, with the words Match colors, uncover cozy scenes.`

## 分层与来源

[layout.json](layout.json)固定12项输入的路径/SHA256/大小及图像尺寸；[manifest.json](manifest.json)记录输出hash、实际图层摆放、文字bbox、工具版本与未获准发布状态。

- 图标来源是现有`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`，不重画品牌。
- 横幅背景取`app/assets/art/backgrounds/game.png`顶部1024×500区域，不拉伸；针织场景/字标使用现有PNG透明层，保持原图比例。天蓝底仅作背景取样，原文件保留完整。
- 场景使用`app/assets/art/scenes/color_studio/base.png`与piece-1…5，位置逐项对应`scene_art.dart`现有normalized rects；所有层按contain等比缩放。背景/字标/scene的图层顺序与坐标均可编辑复现。
- 文案由现有Nunito variable font的800字重、32px绘制；字体与OFL路径也纳入固定输入。字体许可不能覆盖图像权属。
- 既有美术来源与权属沿用[运行美术manifest](../../production-candidates/runtime/manifest.json)、[UI manifest](../../production-candidates/runtime/ui/manifest.json)及BR06的rights-gap.md；不把ImageGen历史来源记录或视觉接受当商业授权。本轮没有新生成美术。

## 复现

使用现有运行时Python3.12.14 / Pillow12.3.0（未新增安装依赖）。项目根目录运行到一个新的ignored子目录：

```sh
/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 docs/design/store-candidates/BR07/export.py --output build/br07-reproduce-new
```

[export.py](export.py)先拒绝输入hash漂移和现有输出文件，再做标准尺寸导出与分层渲染，不会覆盖这两张已冻结候选。本轮已在`build/br07-repro-check/`复现，两PNG及manifest逐字节一致；该目录是ignored检查副本，不是另一个发布源。不要直接重跑默认输出覆盖候选。原件、app/assets、BR06文件和二进制均未改。

本地格式依据：[Google Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en)。512图标符合该PNG模式/大小要求，横幅为指定1024×500无alpha；最终权属、素材审核和真实上架接受仍需各自闭环。官方规格已于2026-10-23的BR06核对，本批没有把推荐宣传资格或图片技术格式当商店整体通过。

原尺寸及横幅512宽/图标128宽缩放检查见`docs/development/evidence/beta-readiness/BR07/scaled-inspection.png`。这是本地文件缩放检视图，不是系统/模拟器截图。正式App截图缺口仍保留，不进行任何F9或受限采集操作。
