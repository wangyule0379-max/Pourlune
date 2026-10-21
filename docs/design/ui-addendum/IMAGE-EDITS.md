# 局部图像编辑记录

2026-10-21；使用内置 `image_gen.imagegen`，不是 CLI/API fallback。原件只作引用，未覆盖。仅编辑瓶体资产，不重新生成21页。

## 编辑1：容量／目标语义和中性缓冲瓶

输入：原 `boards/06_Extra_Bottle_States.png`，P18为编辑目标。

Prompt:

> Use case: precise-object-edit. Edit target: supplied Pourlune board, only P18 bottle assets (right panel). Output a single clean horizontal sprite sheet of FIVE isolated bottles on genuinely transparent background: four full mixed-liquid target bottles and one empty neutral buffer bottle. Preserve exactly original bright knitted 3D bottle material, cream cable-knit side sleeves, transparent glass and pale translucent liquids. Five equal-size bottles in a row, front-on, generous gap, no UI, no text, no labels below, no shadows outside objects. First four are P18 top row bottles, but correct knit top+bottom trim color to match target: orange, GREEN, PURPLE, BLUE respectively (P18 second and third bottle trim must match target, not upper liquid). Keep their 4 contiguous liquid layers and circle/triangle/diamond/square symbols exactly as source. Fifth bottle empty transparent glass, trim CREAM NEUTRAL, no liquid, no liquid symbols. Add four subtle dark navy short capacity tick marks on the right glass edge of all five bottles aligned to quarter capacity. Do not generate a screen, do not redesign the bottles, do not include calendar, room, flowers, ads, plus-one badge, interface text. Maintain identical bottle proportions across all five assets.

保存：`assets/bottles-edited.png`（1983×793，RGBA），单瓶 `bottle-0`～`bottle-4.png`。渲染时使用同一图片盒等比contain；裁切仅拆资产，不改液层。

## 编辑2：教学两色各2单位

输入：原 `boards/02_Tutorial_Play_Pause.png`（编辑目标P04）＋上一步 `bottles-edited.png`（材料／比例参照）。

Prompt:

> Use case: precise-object-edit. Create ONLY a transparent horizontal sprite sheet of TWO tutorial bottles from P04 (left of image 1), in exact material and proportions of image 2. Bottle 1 orange knit trim; Bottle 2 BLUE knit trim matching its blue-square goal (correct original green trim). Both bottles equal-size, straight upright, front view, no hand, no arrow, no target label below, no UI text. Each bottle contains TWO contiguous pale liquid segments: upper HALF = pale peach orange with one dark orange circle symbol; lower HALF = pale sky blue with one dark blue square symbol. Each segment occupies exactly TWO of FOUR capacity units. Four subtle navy capacity ticks on right glass edge at quarter heights (1,2,3,4), no numerals. Preserve original cream knitted side sleeve, bright glass, clean flat shared boundary, meniscus at top only; no dividing gap at quarter ticks. Keep same soft knitted 3D aesthetic and generous separation between bottles. Output just two transparent assets on a transparent background.

保存：`assets/tutorial-edited.png`（1774×887，RGBA），单瓶 `tutorial-0.png`、`tutorial-1.png`。裁切框分别300/30/550/840、930/30/550/840。

## 已检查

输出已打开并置于实际图册查看。目标装饰／标签映射、4档容量、2单位教学段、缓冲无符号、浅色液体、针织材质保留。图片是参考渲染，液体仍烘焙在单瓶图中，不能当作正式客户端动态液体分层资源。

## 原稿保真补充（不新增导航页）

### 编辑3：P04最小原框架修改

输入：`assets/source-tutorial.png`（原02板P04裁切）。内置image_gen提示词：

> Use case: precise-object-edit. This is an approved Pourlune UI screen, edit it MINIMALLY. Preserve the exact screen composition, sky blue subtly lit backdrop, bright original knitted 3D material, flowers, moon, all existing buttons, text, font sizes and positions, hand, selected highlight and arrow. Change ONLY: (1) upper-right target bottle knit rim and base from green to BLUE matching its blue square target badge. (2) both bottom EMPTY buffer bottles knit rim and base to neutral cream, preserve their transparent glass, no liquid or symbols. (3) add four short dark-blue capacity tick marks on right glass edge of each bottle at quarter heights for capacity 4; ticks must align across bottles, no numerals. Top bottles still show only TWO contiguous half-height liquid colors, peach top and pale blue bottom, each half represents two units, exactly same liquids and symbols as input. Keep every existing English word verbatim, including 'Level 1', 'Tap a bottle.', 'Then tap an empty bottle.', 'Empty or matching color.', 'Skip', 'Undo', 'Hint'. Do not add new navigation, labels, text or decoration. Output same portrait screen, no phone bezel, no additional canvas, no style exploration.

输出 `assets/tutorial-frame-edited.png`。自查发现上排刻度未生成，故原框架状态 `tutorial-fidelity` 在HTML中以原生标记层补上两瓶刻度（橙瓶左侧避开手势、蓝瓶右侧）。两种液体各2单位、目标蓝外套与蓝方形标签、底部缓冲中性均已保留。它是静态保真稿；自适应／可访问组件样例见 `tutorial`。

### 编辑4：P18整框候选——未采用

输入：`assets/source-seven.png`。要求保留全部背景／文字／控件，仅将下排三瓶统一为上排瓶体宽高、中性奶油瓶、加四档刻度。提示重点为“all SEVEN bottles must have IDENTICAL visible glass-body width, height and proportions, top row FOUR and bottom row THREE centered, use top-row size as reference”。输出仍有下排宽度偏差且第一缓冲瓶橙色瓶口未改，因此没有复制为交付资产、没有作为尺寸通过证据。被弃用候选不属于最终交付。

### 编辑5：P18保留原框架，清空棋盘供统一组件排布

输入：`assets/source-seven.png`。提示词：

> Use case: precise-object-edit. Remove ONLY all seven bottles, their four round target badges, and yellow reward glow from the middle board area of this approved Pourlune P18 screen, filling those removed areas seamlessly with the existing sky blue background. Keep absolutely everything else intact: exact text, fonts, all button positions and appearance, 'Level 12' and moon, back and pause icons, green check toast 'Extra bottle added', goal instruction 'Match the color tags', all knitted flowers/landscape at bottom, and the bottom controls 'Undo', 'Hint', 'Bottle added'. Do not create any bottles or new objects. The middle must be clean empty sky blue ready for native bottle components. Keep same portrait aspect ratio and all UI positions, do not resize or redesign any controls. Output an image with the seven bottles and target labels removed; no extra text.

输出 `assets/seven-background-edited.png`。`seven-fidelity` 在这个原框架上复用编辑1的单瓶，以同一84×177图盒排4+3，底排居中。尺寸由HTML组件保证，不依赖生成模型猜测。原P18文字、背景、针织花卉和控件保留；新瓶含四档刻度、目标装饰一致、缓冲瓶中性。可操作／窄屏／大字号样例仍为 `seven`。

## R1：修复裁切边缘（R05）

未重新生成图片。错误来自初版将1983px宽原片等分为5块：等分线跨过瓶体边缘，bottle-1/-3带邻瓶竖条，bottle-0/-4被截到画布边。已从相同`bottles-edited.png`重新提取各瓶专属范围；结果仍396×793 RGBA、不缩放主体、不重画颜色／刻度。精确区间和透明扩边见`assets/bottle-crops.json`及`tools/split-bottles.cjs`。旧裁片保存于`revision-r1/before/assets/`供对照。

所以本轮是既有图像资产的正确拆分，不是新的图像生成或风格修改；来源原片保持原样。
