# 出水口校准修复 · 2026-10-26

状态：总控已独立实际验看通过；修复版专用模拟器已置前，保留32步未完成盘面并停止自动输入。本批不发布，TestFlight15保持。

## 对应问题与实现

沿用总控的[根因定位](../review/pour-stream-origin-20261026.md)。生产仅修改 geometry.dart、paint.dart：原lip在素材(.58/.42,.10)前针织圈位置，改为实际开口两侧(.68/.32,.05)，约166×309裁片的(113,16)/(53,16)。内腔开口多边形一起对齐，保留水位、倾角求解、源瓶对齐/缩放、流柱共用这个真实唇点，未单独挪一条线。

水流在接收瓶之后、运输源瓶之前绘制，源瓶玻璃和前口圈遮挡水流根部，仍连续画到接收液面。原素材、颜色、时长、容积计数、口圈间隙算法、选择/换选、规则、存档、题库、SDK和依赖均未改。静止4层以下液体的体积截面不受顶部开口调整影响。

生产修复源 `00c121c4d2f1f958092f2a7019b8194ab9855e77`；后续 `8f9f749` 只把光栅回归第二条路线改为7→5，实际覆盖负倾角。已编译/安装的221项运行输入与这两个提交均相同；不是重编或混用画面。来源/hash见 evidence/pour-stream-origin-20261026/native-source.json、runtime-inputs.json。

## 自动差额验证

- 新增两项回归：将实际流柱点逆变换回素材像素，按独立观察的开口边界核对，并验证保留液面相交；另直接渲染真实素材，比较水流经过时源口圈不透明针织像素。七/八瓶、左右/跨行、1/4层及起中后代表保留。
- RED：旧口点y=30.9像素落在开口8–24范围外；旧绘制覆盖26个不透明源口圈像素。校准后还单独恢复旧绘制顺序做受控mutation，回归抓到11像素覆盖，finally逐字节恢复生产代码。
- 最终相关39项通过，包括口圈真实8px间隙、连续流/真实Flame时钟、边界/读数带、体积/归位/取消、控制器/持久化和换选；最终左右倾角两项再次通过。3文件分析无问题、format无差异。
- 初次相关命令误列两个不存在的测试文件，退出失败（flame_frame_test、flame_clock_test）；后续按实际文件清单完整重跑39项通过。早期像素采样在缩小源瓶处没有不透明覆盖点，已调整为总有效覆盖守卫，并补真正负倾角路线；未以空采样当通过。首次分析的两处测试样式提示已修复。
- 正常lib/main.dart独立iOS Simulator debug构建成功71.2秒，Firebase none、ads disabled、NoAdID；未重跑无差额全平台/全题库/字号矩阵或已终态发布CI。

## 正常 main 实拍与保存

专用D79（Pourlune Liquid Color QA，iPhone17/iOS26.5），独立身份dev.pourlune.pourOriginValidation，正常字号1206×2622，独立新库pour_stream_origin.sqlite。保留旧orange/tap等所有命名库；普通2AE、F9及其窗口未操作。运行库首次从历史QA只读快照克隆，再用正式main31定义的前20参考步/完整undo历史及QA额外空瓶准备。不是自然解锁、首次难度或广告发奖证明。

首片已知作者完成第21步后，CUA报告用户改变Simulator；fresh状态为24步。额外3步如实归为非作者操作，原片与native-receipt.json保留；未回拨/重置。随后作者从已观察状态完成25–28步，再以正常操作完成29–32步用于真正左右倾角。最终实际SQLite32步、revision33、history32、integrity ok，仍可操作且未完成；回执native-final-receipt.json。

| 原速短片 | 实际动作（0起索引） | 原片区间 |
|---|---|---|
| right-down-original-speed.mp4 | 第25步0→7 O4，向右下 | native-original.mov 58.5–60.5s |
| left-tilt-original-speed.mp4 | 第31步7→5 O4，真正负倾角 | left-native-original.mov 11.8–13.7s |
| right-tilt-original-speed.mp4 | 第32步5→7 O4，正倾角 | left-native-original.mov 23.6–25.5s |
| up-original-speed.mp4 | 第28步7→0 O4，跨行缩放负倾角 | native-original.mov 99.4–101.3s |

均系统AVFoundation passthrough截取，无变速/插帧；video-metadata.json核源到呈现时间比例1。完整原片仅本地保存，不将161MB原片放入Git。作者实际看原生59.50、73.40、100.20、12.60/24.40及接触表；水流从口边接出、圈面未被流柱直接覆盖、两圈分离、连续到接收液面；自查不替代独立验收。

实际原片记录及只读冻结Runner/kernel同源已核。首两次项目路径录屏被录制服务文件写入权限拒绝，改用允许的/private/tmp输出后成功，再复制项目；没有修改系统安全/隐私设置或重启全局服务。

## 边界与接续

仅正常字号本次代表图审；物理设备、所有盘面/轨迹及特殊字号未重验。保持已发布15，不自动创建/上传16，不改商店、AdMob或Google Play。总控逐一核470项hash，并实际看左右/向下/缩放向上8张原生帧后通过，详[独立复核](../review/pour-stream-origin-20261026-independent.md)。父未重复运行工具链，也未声称看完两段完整原片。随后仅对D79窗口执行Raise；fresh AX仍32步、已保存、瓶按钮可操作，shown-to-user.txt/png保留实际凭据。没有再点击游戏或改库，已停止自动输入留给用户。
