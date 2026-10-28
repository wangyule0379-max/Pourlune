# 固定接收瓶 R02：代码与检查完成，待新原生验收

用户否决上一版接收瓶下沉；5220a23的整体验收已撤回。当前只让源瓶运动，目标及其余瓶坐标、角度、比例全时段恒定；旧选择回落继续由既有独立测试保护，不把它当目标下沉。targetDrop/receivingDrop、目标lift缓存与邻瓶借位已删除，前景源瓶和水柱保留。

按总控选定方向，仅第一排前有一个静态倒水空间。使用原旋转材料矩形、原针织口包络与最大倾角1.72的实际投影极值计算最小高度，再在初次页面布局一次fit两排；不在动作开始/结束时改变其它瓶。不改变倾角/水量、时间线、标题/操作区，不画出原canvas，不引入每排重复通道。无下排目标时去掉标签内未使用的目标垫预留，保留真实编号/容量；字号与触控不缩小。

正常402×874/Nunito的实测静态瓶宽：4/5瓶106→96.23（-9.21%），6瓶98.72→89.36（-9.47%），7/8瓶82.50不变；仍为原两排/顺序/标签/操作区。完整探针与前后尺寸见layout-before-after.json。父已允许有限初始尺寸适配；这不是倒水时缩放目标或整盘动态缩放。

旧358×470六瓶78像素守卫在单上方空间构图下实际得到68.3569，失败日志stationary-single-space-first.log保留（该中间run还有已修的残留参数编译错误，不作通过依据）。守卫改为至少64，明确继续拒绝先前55像素双通道方案，同时原48px点击域、完整容量/标签和几何检查仍保留。该差额待父实际新图判断，不以改断言替代验收。

有效检查：stationary-red.log先证旧实现4瓶目标在10ms下沉；stationary-focused-final.log的18项通过，覆盖实际4—8瓶非源瓶全时间恒定、源瓶>=.9且不出界、原生材料口间隙、水柱入瓶、前景像素、快速换选与Hint几何；stationary-layout-matrix.log正常字号4个矩阵用例通过（各含既有5种页面尺寸）；stationary-analyze.log无问题。未重复全套应用/core/工具/旧CI；旧482通过属于已撤回方案历史，不冒充本R02全套。

正常main新QA将单独冻结供Computer经已有标准Xcode GUI NoBuild路径安装；原QA和TestFlight18不覆盖为新发行。实际新录像/总控验收尚未完成；F9、SDK/统计默认值、存档/奖励与发布均不改。

## 冻结候选（新原生待验）

实现源d7ec5d7f7d75ade1e5c6ccfefd7d32c58d3c36af。正常main新Simulator debug编译成功，显示名Pourlune Pour QA R2；身份/命名库与原专用QA一致，Firebase none、ads disabled、GM disabled。新只读包build/pour-flight-fix-20261028/ios-qa-2/Runner.app共361文件，manifest SHA256 e132ffd79f928ca2066d9d06a3a53686f97523bf4cf318d9ccff8bf3092c3c09。旧QA1保留冻结。

新ignored标准GUI运行工程xcode-frozen-launch-2/PourFlightFixedReceiverQA.xcodeproj，唯一scheme PourFlightFixedReceiver_NoBuild_20261028；零源/阶段/依赖/包/脚本。静态解析路径、arm64/iphonesimulator、独立身份及无debug-dylib模式确认，Products副本361hash与原包相同，预先采用标准可读写权限；原包仍只读。仅供Computer对既有2894经Xcode UI Run Without Building；未安装/运行本R02，不是已验或已发行。完整静态凭据见qa2-launch-descriptor.json。
