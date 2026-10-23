# ADM01：AdMob 登记与同批封测接入

2026-10-23。用户直接授权“申请Google AdMob，并接入吧”“可以一块测试”。该范围在已授权TestFlight/Play closed之内增加真实AdMob配置与测试广告联测；不需要重复通用方案批准。原开发唯一实施，架构独立验收；构建与平台CLI继续串行。目标是让本人安装封测版后能验证现有激励/插屏闭环，同时保持离线解谜、动作保存与奖励一次性到账。

## ADM01-1：先核对已有实现和账号（一个事实清单）

复用B04 ServiceConfig/GoogleAdsTransport/AdCoordinator/UMP，不新增Banner、开屏或广告业务位置。当前ServiceConfig可显式test，但firebase_build.py固定disabled；不能只给出AdMob ID就称已接入。

只读检查已有登录Google/AdMob/AdSense及账号状态，沿用用户既定发布身份。已开通则复用账号，只增加Pourlune独立资源；没有则推进注册准备。国家/时区/币种/付款主体不由证书或语言猜测；必须本人接受的服务协议、验证或真实支付/税务信息集中列出具体页面/所缺项。不能代签、购买、扩大IAM，也不改FishPilot项目/广告位/钥匙。不要将公开支持邮箱自动等同当前登录账号。

## ADM01-2：Pourlune 平台登记（一个公开配置清单）

用户已授权申请/接入，可在现有已开通账号中直接创建尚不存在的Pourlune iOS/Android未发布应用、各自必要的激励与插屏广告位，避免重建已有资源。正式身份com.pourlune.app，实际商店App记录/链接核实后关联；封测私有入口不冒充公开上架。记录平台、App ID、unit ID、归属、审核/验证真实状态和控制台回读证据。关闭可选user metrics及无关采集，保留已有独立开关。

核对app-ads.txt当前要求和实际publisher ID/开发者网站根位置；GitHub Pages项目子路径不自动等于平台要求的站点根。仅在已授权网站/账号范围内提出可审真实方案，不复制FishPilot发布商字段或悄改主域站点；测试广告不等待正式商业审核才开发。

## ADM01-3：封测参数与SDK门控（一个最小实现差额）

提供显式、可审计的封测测试广告模式。默认正式release仍disabled；仅本次明确beta candidate参数开启test，不能借修改默认值令全部release投真实广告。优先用各平台Google官方测试unit，确保本人未知设备也不会请求可计费真实广告；将Pourlune真实App ID与测试unit模式分别记录并验证。若必须使用自有unit，则先有真实测试设备保证与安全回退，不能要求用户点击真实广告验证。

保留锁版本与现有native初始化/UMP资格、拒绝/离线、非个性化边界及Analytics/Crashlytics独立默认off。13+受众不等于所有用户成年或免于地区/未成年同意要求，按实际当前SDK政策核对，不猜用户年龄、强制同意或写零数据。原生AppID与平台/身份参数错配应拒绝，测试与生产unit不能混用。只修必要工具/配置/实现，不重构B04业务。

## ADM01-4：配置一致的资料（一个更新矩阵）

核对实际SDK/权限/网络/UMP消息与现有隐私站/Apple隐私/Play Data safety及contains ads/封测说明。启用测试广告也要如实记录第三方SDK处理，不能沿用“广告关闭因此无处理”的表述。公开支持隐私站必要事实同步在用户已授权Pourlune站内；不擅自新增跟踪或替用户签法律声明。适用必填本人事实集中交接。

## ADM01-5：先聚焦验收，再新封测候选（一个交付）

保存当前已生成0.5.0+7/BR08包及哈希，标注ads disabled基线，不能覆盖或当新增广告测试版。ADM实现通过父独立聚焦验收/新精确CI后，用下一个未占用build号生成新的签名候选，复用Apple profile/BR05 key，核包包括真实native AppID/测试unit与启动参数、SDK/权限、来源锁资源签名符号。不可先上传未验的新增广告实现。

在专用QA身份/库和允许设备上真实SDK有限验证加载/展示/关闭、激励回调到账、重复/中断/保存失败/Next门控；用替身测试边界不冒充真实广告结果。只允许官方Test Ad/明确test mode，受限截图录屏不得绕过。网络失败明确保存错误与未验项，不改TLS/代理。测试广告可用不等于正式广告填充/AdMob审核通过，不测收益或以点击刷量。

完整交付docs/development/deliveries/admob-beta-integration.md、evidence/admob-beta-integration/；父review/admob-beta-integration-acceptance.md。包交付及商店进度继续BR08索引，但明确版本/广告模式不同。父实际核包后继续已授权TestFlight/Play closed。本人手机只能经商店安装，真实手机广告反馈在分发可用后验证，不要求USB。

## ADM01-6：持续推进和真实缺口（一个最终安装/待办说明）

账号注册本人依赖不阻塞可独立的测试模式、参数/披露与保存测试。开发收齐能做项，集中列明准确账户步骤和必需信息，不重复主体/邮箱/已生成key。商店年龄/地区/账号未知不得猜；仅本人测试，不扩大邀请或公开生产发布。已有LY/FB测试不重跑全量；新增风险定向验证。

## 当前官方依据（2026-10-23实际读取）

- https://developers.google.com/admob/flutter/test-ads ：官方sample unit或自有unit+test devices；模拟器自动测试设备，手机需保障；测试流量与正式广告分开。
- https://support.google.com/admob/answer/9989980?hl=en ：未发布应用可先登记测试；支持商店公开关联与readiness审核另行要求。
- https://support.google.com/admob/answer/15948559?hl=en ：账号设置/付款信息与商业广告资格。执行具体步骤时查当前账号页面和官方资料，不把旧稿作为控制台现状。

F9设备/窗口、旧包/普通DB/FirebaseQA保护及采集限制继续；FIREBASE_ANALYTICS_WITHOUT_ADID=1。秘密不入Git/日志，父和开发不得并发平台CLI。内部可做项不断档，真实强制本人操作才集中提出。
