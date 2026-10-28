# GameMunchies 0.2.0 设备验收前基线

2026-10-28 21:54–21:56 Asia/Taipei。通过现有后台会话只读观察；最近七天为 10/22–10/28，数据更新时间是后台显示的最后上报时间，非观察时间。

| 游戏 / 环境 / 平台 | 应用标识 | 活跃安装 | 开局 | 广告展示 | SDK广告加载失败 | 最后上报 |
|---|---|---:|---:|---:|---:|---|
| Pourlune App / 正式 / iOS | com.pourlune.app | 1 | 9 | 1 | 0 | 10/28 20:08:46 |
| Pourlune App / 正式 / Android | com.pourlune.app | — | — | — | — | 等待数据 |
| Pourlune Integration Test / 测试 / iOS | dev.pourlune.gamemunchiesValidation | 2 | 14 | 2 | 28 | 10/28 15:26:46 |
| Pourlune Integration Test / 测试 / Android | dev.pourlune.pourlune_dev | 2 | 2 | 0 | 0 | 10/28 15:14:27 |

正式游戏 ID `8feaf0dc-ec12-4308-ac58-16b2180f2d63`；测试游戏 ID `566121d2-a3f5-4950-8bd9-6ff2f673a0ac`。后台在所观察的数据页提供展示与加载失败计数，未见请求、加载成功、关闭、奖励等完整漏斗数；收入显示未接入。无数据以破折号表示，不能视为零。

测试游戏已发布广告设置：iOS v4（10/28 14:12）与 Android v1（10/28 13:40），总开关、插屏、下一关、增加一个瓶子激励场景均开启；插屏最小间隔均为 180 秒。配置发布状态不证明设备已拉取或实际展示。未编辑或发布配置。

设备只读观察：Simulator 的 `Pourlune GM QA 20261028`、iOS 26.5 窗口正在显示已存关卡；既有证据识别为 iPhone 17 Pro `2894A85E-04FC-4857-A856-3BEFF2CCB565`。Android Studio Running Devices 显示 `Pourlune GM QA 20261028 API 36.0` / `emulator-5554`。历史原生记录指出独立 iOS 身份及 `gm_api_native_recovery_20261028.sqlite`、Android 同名独立库；先前 Android 恢复正常 main APK 且正常库仍存在。此轮未读取库内容，也未确认当前安装包哈希或 Android 可交互性；旧证据报告其 UI 点击路由受限。新包未安装，设备未操作或清理；F9 和普通存档未触碰。

截图及可访问性文本与本文件同目录。此次未造事件、修改后台、使用凭据或进行发布。

## 管理接口漏斗补充（22:12 Asia/Taipei）

上述“页面未见完整漏斗”仅是旧页面展示限制，不代表后台没有：现有已登录管理会话通过 `GET /api/admin/stats` 实际返回 `funnel`。对测试游戏按今日、iOS/Android 分别查询，不加版本和 `appVersion=0.5.0+19` 四份返回均已保存为同目录 `test-*-funnel-*.txt`。四份漏斗 `hasData=false`，各阶段均为0、两种转化率为 null；不加版本时 iOS `legacyAdImpressions=2`、Android 为0，版本过滤时两者均为 null。`totals` 在带版本过滤后仍返回平台总体指标，不能把它当成 build19 专属统计。以上仅为新测试前基线，非 SDK 0.2.0 运行结果。

GitHub Pourlune 仓库 Actions 通过界面新增 `GAMEMUNCHIES_DART_SDK_ARCHIVE_V2`，GitHub 显示 Repository secret added，列表可见 V1 原有及 V2 新增；内容未回显，未触发工作流或发布。GitHub 不提供密钥明文回读，后续构建还需验证消费结果。
