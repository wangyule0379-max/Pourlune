# 开发准备执行计划

Goal：补齐当前可独立完成的开工准备，交付可运行的内容检查和明确的剩余依赖。

Architecture：本轮只建立仓库、Python 离线内容工具、技术交接资料；不创建 Flutter App，不改动 UI 执行聊天的文件。

Tech Stack：本机 Git、Python 3.11+ 与 jsonschema；既有 Flutter / Xcode / Android 工具链仅诊断；补装 CocoaPods。

Spec：[开发准备清单](../specs/development-readiness.md)、[数据契约](../specs/data-contracts-v1.0.md)、[AC 清单](../specs/acceptance-and-content-readiness.md)。

Global Constraints：原件不改；不上传、不创建业务账号、不接受未知条款；内容候选和静态证据不能冒充运行验收。UI 增量由既有聊天继续修复。

## Task 1：工具链与本地版本管理

- 诊断 sdkmanager 与 Flutter doctor 的输出兼容性；不通过伪造许可文件或修改 Flutter 源码消除警告。
- 安装 CocoaPods，运行 pod --version 与 flutter doctor -v，写实际检查记录。
- 建立本地 Git 和忽略项，当前准备使用 prep/development-readiness 分支；无远端配置。
- 本地提交使用明确的 Codex 工具身份，不伪造用户姓名或邮箱。UI 活跃交付不纳入本轮提交。

## Task 2：内容校验工具（先失败、后实现）

Files：tools/content/validate.py、tools/content/test_validate.py、requirements.txt、README.md；docs/content/contracts/daily-catalog.schema.json；docs/content/fixtures/。

Interfaces：读取既有 puzzle.schema.json；validate_puzzle 返回最终棋盘与步数；CLI 接收一个或多个题目，完整发布模式增加主线覆盖、每日目录及候选状态检查。

- 先写手算规则、原关卡快照、损坏数据与 CLI 退出码测试，运行并确认缺失实现导致失败。
- 实现完整 Schema 检查、跨字段守恒、连续倒入、标签胜利、目录完整性、日期映射。
- 添加 2/3 色参考夹具，仅作为工程数据，不填充虚假的正式题库。
- 全套 unittest 通过；实际夹具通过；现有不完整题库在发布模式下必须失败并说明缺失。

## Task 3：落实交付与入口

- 正式资源清单覆盖瓶体、3 个场景、字体、声音与来源；每项明确可接入条件及当前证据。
- 建立外部账号/发布身份交接表，集中收集必要信息，秘密不入表。
- 建立第一个可玩闭环的实施顺序与验收入口，更新 AGENTS、开发准备清单和根 README。
- 只跑实际存在的内容工具，不跑不存在的 Flutter 构建。

## Review Focus

重点检查异常 JSON / 空输入不能误通过、目录重复/不存在的题目、参考夹具混入正式目录、日期跨年与 epoch 前映射、目标标签参与胜利、初始即通关/提前通关后仍有参考动作、资料间状态一致，以及忽略规则是否遗漏秘密。

## 执行记录

- Ruling：当前目录尚非 Git 仓库且另一个聊天在更新 UI，采用本地独立准备分支及文件边界，不搬迁共享目录；代价是提交时必须显式排除仍在变动的 UI 文件。
- Ruling：本轮采用小型开发准备工具；保留本计划内执行记录，不引入额外任务脚本框架。
- Task 1: complete：Git 基线 8b5a466；CocoaPods 1.17.0 已安装，Xcode doctor 通过；Android 旧输出解析的 unknown 已定位并保留实际状态，真实构建待工程阶段。
- Task 2: complete：先运行缺失实现的失败测试，再完成 16 项；独立审查发现两处问题，新增 3 项测试先失败后修复，全套 19/19。三份夹具回放通过，发布完整性按预期失败；详见内容工具审查记录。
- Task 3: complete：正式资源/账号交接、首个闭环实施顺序、README、AGENTS、数据和准备清单已更新；Nunito 候选文件与 OFL 已归档；12 份 Markdown 的本地链接通过。
- Final: fixed：报告覆盖输入与浮点舍入误过约束均 RED→GREEN，suite 19/19；没有延后的小问题。
- Final: Ruling：独立审查未覆盖的题库品质、Dart/SDK/设备及跨机器依赖等保持待验收，不能将工具通过扩大成产品通过；若忽略此界线会导致错误放行，因此已在各交接文档明确。
- Final: Ruling：保留新建本地准备分支，不推送、不另选未知远端或主分支；这是用户要求持续完善的可逆范围。仅有本地历史，远端备份仍待用户提供归属。当前不是待合并到另一个既有分支的任务，不发起重复集成选项确认。
