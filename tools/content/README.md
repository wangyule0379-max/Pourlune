# 离线内容准备工具

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

正式内容使用另一目录（建议 docs/content/production/），全部文件以 production_candidate 标识，内容交付时运行：

```sh
.venv/bin/python tools/content/validate.py --release \
  --catalog docs/content/production/daily-catalog.json \
  docs/content/production/main/*.json docs/content/production/daily/*.json
```

此命令目前尚无对应生产目录，不能作为已通过命令。发布模式要求主线 1–60 完整、ID 唯一、每日目录至少 30 个不同 ID 且全部引用通过回放的每日题；所有输入都是候选内容。目录格式见 daily-catalog.schema.json；主线、每日题格式见 puzzle.schema.json。

日期映射：按本地公历日期算 `d = date - epoch_date` 的整数日差，索引 `((d % n) + n) % n`，从 0 起算。Python 的正除数取模已经非负；Dart 实现保持同样结果。epoch 前日期循环到末尾；不要用 Unix 秒数除以 86400 代替日期差。正式 epoch 和顺序仍由正式目录交付，测试日期不代表产品发布日期。

即使发布模式退出 0，也只证明格式与参考解条件；难度、不同题目的实际差异与编排质量、教学试玩、Dart 一致性及 AC-35 的客户端回放仍需独立验收。这里只维护一个参考验证器，不作为正式客户端运行依赖。
