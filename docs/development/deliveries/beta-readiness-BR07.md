# BR07 有界本地商店素材交付

2026-10-23，作者交付，待架构独立验收。按已授权两项，完成既有视觉的512图标及1024×500 feature graphic；**仅本地候选，权属UNCONFIRMED，not-approved-for-publication**。不等待用户重复批准本地准备，不扩大为新设计或正式截图。

|要求|结果|证据|
|---|---|---|
|BR07-1 Play icon|512×512 RGBA8/PNG32，379,110bytes，全帧缩小，无新增裁边/圆角mask；alpha恒255|docs/design/store-candidates/BR07/play-icon-512.png；SHA256 a722121bd62aa48aeeef164d1e24122ac9616d0fb0ea75ca51113891356e6079|
|BR07-2 Feature graphic|1024×500 RGB8/PNG24，无alpha，560,872bytes；原天蓝背景、针织字标、Color Studio base与5物件等比排版；真实短句Match colors, uncover cozy scenes|docs/design/store-candidates/BR07/feature-graphic-1024x500.png；SHA256 97aff80a8d5ea0b5343230b7b108a167d897ff79bcb3ef52e022a85996595027|
|来源/图层/复现|12固定输入hash；layout保留字体/字重/位置/层级、scene normalized rect；export.py标准导出，拒绝源漂移/覆盖|候选README、layout.json、manifest.json；export.log、reproduce.log、verification.json|

实际采用确定性原图导出/分层排版，没有新ImageGen调用或新生成的美术。原图商业权属限制最终使用，但没有据此阻止可逆本地准备。完整场景是已有可收集场景的宣传展示，不称当前玩家进度、App截图或正式运行画面。文案无价格/排名/评价/徽章/广告或性能虚假承诺。

## 实际检查

- 用现有Python3.12.14/Pillow12.3.0执行export.py成功；再到新的ignored `build/br07-repro-check/`完整复现，两PNG与manifest均逐字节相同。12输入hash与尺寸匹配，scene5个rect与现有Dart值一致，图层全部contain等比，未修改源图。
- PNG解析/校验、8bit色深/color type6与2、目标尺寸、icon≤1024KB及alpha255通过；icon像素与完整1024原图的标准缩小结果完全一致，无隐式裁切。文字内容/bbox通过；取未绘字原背景点测文字对比10.25:1，仅是该局部静态测量，不称全图可访问性认证。
- 实际打开两张原尺寸文件，以及横幅512宽/icon128宽检视图；字标、短句、月亮/星与场景清楚，无可见拉伸、裁字或覆盖。`scaled-inspection.png`为文件派生检查，非屏幕采集。作者视觉自查不替代架构独立视觉接受。
- 原件/app/assets/BR06冻结文件未修改；只读核对BR06两个精确包hash及各397来源一致。没有运行App全量、CI、Flutter/Dart/pub/SPM/Xcode/设备或签名命令，没有新key、重建或重签，没有操作F9/窗口或绕过Cocoa513/EPERM采集限制。
- 无公开上传或支持站改动；独立网站及App源码仓库状态不由本批改变。主仓未stage/commit/push；旧motion-polish及后台emulator日志排除。

## 保留范围与集中待办

正式App当前正常入口截图仍缺：本宣传图不能替代；受限采集不重试/换工具/路径/委派。两组原视觉与派生图商业权属依据仍按BR06/rights-gap.md收敛，来源记录不等授权。

本地可逆素材准备已完成。剩余实际目标年龄/测试国家地区、私有测试账号名单/手机条件、图像权属、适用本人账号/出口/App Signing声明仍交架构集中处理；实际商店上传、Beta审核、开轨道/邀请及生产运行未授权。正式分发后真机安装/升级/存档/链接/音触觉/读屏/性能等未验，USB不是普遍上传前门槛。密钥、主体、邮箱和已上线支持站不再作为用户待办。

一次fresh终审与最终CLI状态在本批evidence/BR07/author-final-review.md及此报告收尾记录；不改BR06已冻结共享交接文件。整体接受及精准提交由架构执行。

最终安全检查点（2026-10-23）：唯一fresh终审C0/I0/M0，成品、12来源、图层及复现步骤已冻结。BR07无Flutter/Dart/pub/SPM/Xcode/设备/签名命令在途，CLI RELEASED；新收到LY布局优先任务，先交本批检查点，不将素材混入布局提交或公开发布。架构按BR07/scope-manifest.json独立验收，本方继续新授权LY范围。
