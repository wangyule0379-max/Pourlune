# Seaside Corner object generation progress

2026-10-22。五件独立透明物件候选生成并落盘，未提交Git。

- 使用内置 imagegen，分别调用五次；原始boards01/04与现有base均已先查看，只作为风格／镜头／配色参考。不是缩略图放大或裁切。
- piece-1：暖棕色针织码头／平台与棕色立柱；piece-2：蓝白条纹棚屋／白色支柱；piece-3：红白救生圈与浅色绳；piece-4：奶油针织盆与绿色植物；piece-5：蓝白针织海鸥，可见双脚，无栖木。
- 逐张查看原始生成图，所需物件齐全、边缘完整，无水面底座／UI／文字。五张实际原文件均为1254×1254 RGBA，真实透明alpha，实心物件像素没有触及画布边界。生成器的大部分物件核心alpha为252/253，保留原始值，不擅自强制不透明。
- 原始PNG逐字节复制至 `docs/design/production-candidates/runtime/scenes/seaside_corner/piece-1.png`…`piece-5.png` 和 `app/assets/art/scenes/seaside_corner/piece-1.png`…`piece-5.png`。未裁切、缩放、抠图、修alpha或重绘；Pillow仅只读检查尺寸／alpha。
- 每个完整prompt、原始生成路径、输入参考、尺寸、SHA-256、透明／半透明／不透明像素及bbox均记录于 seaside-generation.json。原base前后hash相同。
- 状态为production_candidate；基于用户原图的生成衍生物商业权属确认仍未知，不声明已获商业清权。根任务负责Flutter归一化定位、18进度组合／15里程碑和独立视觉验收；本记录不替代实际叠层运行结果。
