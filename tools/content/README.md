# 离线内容准备工具

## 当前主线 v2（60关重设计）

主线作者输入为 `docs/content/design/main60-authored-v2.json`，逐关契约为
`main60-level-contracts-v2.json`。58关新定义已替换运行和候选副本，1/12原字节、30每日及日历保持。
历史 `author_candidates.py` 的无参数生成流程属于旧B03，不再用于重建当前主线；它的 `--check`
仍可只读核对候选和打包副本。不要用旧4关循环schedule覆盖新内容。

```sh
.venv/bin/python tools/content/author_main60_v2.py --output build/main60-reproduce
.venv/bin/python tools/content/author_candidates.py --check
.venv/bin/python tools/content/validate.py --release --catalog app/assets/catalog/daily.json app/assets/puzzles/main/*.json app/assets/puzzles/daily/*.json
```

第一条只输出复现结果；仅明确加 `--install` 才写60主线副本，且先拒绝未知并发差额。
有序BFS证据在完整预算内证明排除范围；unknown不能充下界，参考长度不是人类难度。
单关策略、正反分支与历史错误保留在 `docs/development/evidence/main60-content-redesign/`。
真实Dart提示/旧快照及SQLite升级检查见 `main60_v2_test.dart`、`main60_upgrade_test.dart`。
实际视觉、首次体验和TestFlight仍是单独门槛，题库工具通过不等发布批准。

在仓库根目录运行，Python 3.11+。本轮实际环境为 Python 3.12.14。系统自带 Python 3.9 不用于本工具。

下例 `python3.12` 指可用的 Python 3.12 解释器。本机实际使用 `/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3` 创建了 .venv；当前可直接运行后两条命令，无须重复创建。

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install -r tools/content/requirements.txt
.venv/bin/python -m unittest discover -s tools/content -v
.venv/bin/python tools/content/validate.py docs/content/fixtures/*.json
```

工具做 JSON Schema 2020-12 检查、颜色与标签约束、最大连续倒入、逐步回放及终局检查；不调用网络、广告或求解服务。所有参考解不加额外瓶。原第 12 关还由测试逐步比对原稿的颜色、单位和棋盘快照。

输入异常、重复 ID、非法动作、未达到目标或胜利后仍有动作都失败。输出 JSON；退出码 0 通过，1 内容不合格，2 参数/报告写入错误。`--report path.json` 同时保存报告；父目录须存在。

数值字段只使用十进制整数 JSON token，不使用小数或科学计数法；避免浮点舍入将非法版本或索引变为合法值。重复对象键和 NaN/Infinity 也拒绝。报告路径不得覆盖题目、目录或 Schema，包括同路径、符号链接和硬链接。

当前 3 个样本均为 reference_fixture。1 / 21 仅借用主线身份格式测试 2 / 3 色数据，不是正式关卡方案；12 来自原设计包。不要通过改一个状态字段把工程样本冒充经过试玩的完整题库。

B03 候选位于 `docs/content/production-candidates/`，逐题副本位于 `app/assets/puzzles/main/`、`app/assets/puzzles/daily/`，目录副本位于 `app/assets/catalog/daily.json`。当前为 60 道主线＋30 道每日，全部 `production_candidate`；这不是独立难度、视觉或发布验收通过。

```sh
.venv/bin/python tools/content/validate.py --release \
  --catalog docs/content/production-candidates/catalog/daily.json \
  --report docs/development/evidence/B03/content-release.json \
  docs/content/production-candidates/puzzles/main/*.json \
  docs/content/production-candidates/puzzles/daily/*.json
.venv/bin/python tools/content/author_candidates.py --check
```

发布模式还会拒绝准确重复、全局颜色映射＋整只带标签瓶位重排的等价题，以及忽略标签后仅改变目标归属的液体结构变体。最后一种是额外的内容质量门槛：即使目标关系不同，当前90题也不以换标签重复局面。审查跨主线与每日整体执行。不会把目标标签约束从真实胜利规则中删除。

`author_candidates.py` 是离线、确定性内容编排脚本，不进入客户端。无参数运行会依照固定 seed 重建候选 JSON 与打包副本，并刷新自动搜索和 hash 报告。`--check` 只读比较完整相对路径集合及 SHA-256；缺失、多余、改变任何字节都失败。生成器从限定色块结构取样、过滤两种规范化棋盘重复，再用有上限的 weighted best-first search 寻找固定目标合法解。搜索超时是预算用尽，不是无解；不声称参考解最短。main-001 为教学延续有意保留旧夹具定义；main-012 原定义和15步原解不改；main-021 新定义用 content_version 2。其他题不是重命名工程夹具。

全量 Dart 回放和初始／中段提示预算检查（工作目录 `packages/pourlune_core/`）：

```sh
POURLUNE_CONTENT_REPORT=../../docs/development/evidence/B03/content-dart-budgets.json \
  dart test test/production_content_test.dart
```

详细编排与局限见 `docs/development/evidence/B03/content-evaluation.md`。Python 发布退出0仅证明格式、跨字段、反重复门槛与合法参考回放；人类试玩和设备表现仍由实际运行证据和独立验收确认。

日期映射：按本地公历日期算 `d = date - epoch_date` 的整数日差，索引 `((d % n) + n) % n`，从 0 起算。Python 的正除数取模已经非负；Dart 实现保持同样结果。epoch 前日期循环到末尾；不要用 Unix 秒数除以 86400 代替日期差。正式 epoch 和顺序仍由正式目录交付，测试日期不代表产品发布日期。

即使发布模式退出 0，也只证明格式与参考解条件；难度、不同题目的实际差异与编排质量、教学试玩、Dart 一致性及 AC-35 的客户端回放仍需独立验收。这里只维护一个参考验证器，不作为正式客户端运行依赖。
