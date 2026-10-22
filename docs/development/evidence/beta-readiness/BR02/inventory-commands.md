# 本批实际只读inventory命令

2026-10-22T15:55:52Z附近执行；UTC与台北时间分开记录。均成功退出，详device-inventory.json。未构建、安装、启动App、写设置或读取数据库；没有对F9发任何命令。simctl只总列表读取并在保存时仅选专用255890。

```sh
xcrun devicectl list devices
xcrun simctl list devices available --json
xcrun simctl list runtimes --json
/Users/wangyule/Library/Android/sdk/platform-tools/adb devices
```

仅对明确专用emulator-5588执行以下shell只读命令：

```sh
adb -s emulator-5588 shell getprop ro.build.version.release
adb -s emulator-5588 shell getprop ro.build.version.sdk
adb -s emulator-5588 shell getprop ro.product.cpu.abilist
adb -s emulator-5588 shell getprop ro.kernel.qemu
adb -s emulator-5588 shell getprop ro.boot.qemu.avd_name
adb -s emulator-5588 shell getconf PAGE_SIZE
adb -s emulator-5588 shell settings get secure enabled_accessibility_services
```

本机仅读取AndroidSDK system-images下source.properties及Pourlune*.avd/config.ini以核对已装镜像/ABI；不改AVD或下载/启动额外镜像。当前getconf=4096，不能外推其他镜像页大小。Android读屏值null仅是已启用服务配置，不是TalkBack不可安装或读屏通过。
