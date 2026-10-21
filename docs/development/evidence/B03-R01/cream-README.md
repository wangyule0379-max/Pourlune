# B03-R01 奶油针织空白框生成证据

- 用途：复用原 P04/P06 奶油针织卡片和按钮材质的一张独立空白框；真实文字和图标由客户端覆盖。
- 生成：内置 `image_gen.imagegen`，以原始 `02_Tutorial_Play_Pause.png` 为风格参考，透明背景。选中第二次生成，精确提示词和参考 SHA-256 见 `cream-generation.json`。
- 输出：`docs/design/production-candidates/runtime/ui/cream-frame.png` 与 `app/assets/art/ui/cream-frame.png` 均直接复制生成原始 PNG，未裁剪、缩放、修像或重编码。两份 SHA-256 相同：`3206046294264ddec7b2d3b8024e5b7f38f75ce50d4145297e273a97c93b5769`。
- 几何：1896 × 830，RGBA；alpha>0 bbox `[0,1,1896,807]`，alpha≥32 可见主体 bbox `[39,99,1860,730]`（右、下坐标不包含）。四角透明。原始输出保留极低 alpha 的边缘散点；不能将 alpha>0 bbox 当成干净物体边界。
- 建议：原图坐标 `Rect.fromLTRB(220, 210, 1676, 620)` 可作为 centerSlice 起点。圆角和边缘留在固定区，中心为低对比针织；实际图像映射、控件比例和九宫格效果由集成任务校准。大卡片与短按钮拉伸后的针脚比例需分别检查。
- 状态：参考派生候选，权属 **UNCONFIRMED**。仅完成生成图目视检查、alpha 几何测量和字节一致性核验；不代表独立视觉验收、Flutter 运行或商业使用权通过。本任务未改源码、pubspec、测试或资源清单，未运行构建／模拟器，未暂存或提交。
