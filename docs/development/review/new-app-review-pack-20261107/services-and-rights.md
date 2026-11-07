# 外部服务及素材权属准备

基线：Cocos 0.5.0(22)，source094727b7；不是旧Flutter服务列表。最终正式候选变化后按差额更新。

## 实际运行服务

| 服务/组件 | 当前作用与证据 | 正式审核说明边界 |
|---|---|---|
| GameMunchies JS0.3.1 | api.gamemunchies.com；配置/冷却及可选择的活跃、新局、广告事件；固定包SHA3177500784c754669d54d85af310ee9461c7e9e464860a6700882f394ce7e513 | 关闭统计不入队/上报；配置、广告资格和奖励独立；不写管理员凭据 |
| Google Mobile Ads iOS13.11.0 | Package.resolved固定；广告加载/展示/奖励回调 | 22是官方测试广告，不能写成商业广告已验证；正式包配置须另核 |
| Google UMP3.1.0 | 广告隐私/请求资格，独立于游戏统计 | 地区/资格可能改变表单或填充，不宣称全球同样广告 |
| GitHub Pages | Pourlune支持/隐私站；用户自行外部访问 | 与当前包披露一致，记录发布版本；不把旧60关说明复用 |
| Cocos2d-JS3.17、WKWebView | 本地引擎/网页资源与原生服务桥 | 无Flutter运行时；不是依赖在线网站才能玩的网页，无远程下载新玩法代码 |
| OpenAI ImageGen | 开发期生成游戏美术 | 非玩家运行服务，不把玩家数据发给AI；不列成运行时AI功能 |

没有账号认证、订阅/内购支付、UGC、排行榜、云存档或运行时AI服务。原旧Flutter的Firebase/Crashlytics不能未经当前包证据写入新审核Notes。公开配置不是管理员凭据，私有SDK不随审核附件公开。

## 当前资源与许可证

| 材料 | 来源/许可证 | 已准备证据与处理 |
|---|---|---|
| Dream Culture | Kevin MacLeod / CC BY4.0 | 包内media/ATTRIBUTION.txt和licenses.html；整曲播放、调低音量和循环，未裁剪变速；本轮官方曲目页已核许可 |
| Water, pouring into glass | giddster / CC0 1.0 | game/assets/audio/CREDITS.md；0.85–3.25秒摘取、单声道、音量与淡入淡出；不是旧edschaefer411438曲目 |
| Nunito | SIL OFL | 完整OFL.txt已抽取 |
| Phosphor Bold图标 | MIT | 完整LICENSE已抽取 |
| Cocos引擎及zlib | 各自随包许可 | 保留三份原许可；不泛称所有第三方文件均MIT |
| vendor Spine扩展 | 随包独立LICENSE | 本包存在即保留通知；该文件不证明游戏使用了第三方Spine素材或持有其编辑器商业许可 |
| 花园/水滴/玻璃/收集器美术 | Pourlune已选方向的ImageGen创作与修改 | 包内CREDITS，原型art说明及本地源文件历史；不冒称第三方独占授权/法律证明 |
| App图标 | 沿用已发布Pourlune图标 | native/icon-manifest.json记录原图及复用哈希；沿用既有权属记录，不另造购买证明 |

官方核对（2026-11-07）：
- [Dream Culture官方曲目/许可](https://remote.incompetech.com/music/royalty-free/index.html?Search=Search&isrc=USUAN1300046)：ISRC USUAN1300046，作者Kevin MacLeod，页面给出CC BY4.0署名许可。未引用第三方转载许可版本。
- [CC BY4.0](https://creativecommons.org/licenses/by/4.0/)：须履行署名、许可链接和修改说明等条件；不宣称作者背书。
- [Water官方原页](https://freesound.org/people/giddster/sounds/386439/)：作者giddster，CC0。

`third-party-notices.zip`从实际上传22的IPA提取许可/归属通知（未打包素材或私有SDK）；`evidence-index.json`逐份记录包路径和哈希，并与工作树比较。此附件提供来源及许可材料，不代替最终包权属核对或尚不存在的授权合同。若Apple需要具体原件，再提供对应材料，不先索要不存在的付费购买发票。

本游戏不提供医疗/金融/博彩等受监管服务，无现金赌注或奖品；相关行业牌照项不适用。该结论限定当前产品范围。
