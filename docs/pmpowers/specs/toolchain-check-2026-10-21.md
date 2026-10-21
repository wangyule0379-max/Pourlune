# 2026-10-21 工具链准备实查

范围：本机工具、内容验证环境和版本管理。没有 Flutter 工程，不代表 App 构建、签名、插件或真机通过。

| 检查/操作 | 实际结果 |
|---|---|
| Git 初始化 | 本目录独立仓库，分支 prep/development-readiness；本地基线 8b5a466；无远端、未上传。提交作者为 Codex / codex@localhost，只表示工具创建此快照，不冒用用户身份 |
| Python 隔离环境 | .venv 使用 Python 3.12.14；jsonschema 4.25.1 和传递依赖固定在 tools/content/requirements.txt；不改系统 Python |
| CocoaPods | 按 Homebrew 官方 formula 安装，pod --version 返回 1.17.0；flutter doctor 的 Xcode 项通过 |
| 安装副作用 | Homebrew 同步安装 libyaml 0.2.5、OpenSSL 4.0.3、Ruby 4.0.7_1，更新 ca-certificates 至 2026-10-20；安装日志显示取消旧 OpenSSL 3 的 Homebrew 链接。未运行 brew upgrade 全量升级；其他项目的兼容性未检验 |
| Flutter / Dart | stable 3.47.2 / 3.13.2，未升级；未来工程锁定以首个兼容性验证结果为准 |
| Xcode | 26.6 build 17F113；仅工具诊断通过，尚无 App 构建 |
| Android SDK | 37.0.0，JDK 21.0.12.1；doctor 仍报告 Android license status unknown |

## Android 警告的证据与处理

实际运行 SDK 内 `cmdline-tools/latest/bin/sdkmanager --licenses`，stdin 关闭，未输入接受：退出 0，仅输出 `The --licenses option is no longer needed.`。同目录新版 Android CLI 提供 `android sdk`，本机 CLI 版本 1.0.16261425。

读取本机 Flutter `packages/flutter_tools/lib/src/android/android_workflow.dart` 的 licensesAccepted：仍启动 sdkmanager --licenses，并解析旧版 accepted / not accepted 文本；没有匹配时返回 unknown。SDK 的 licenses 目录已有历史文件，但文件存在不能证明所有未来要用的组件许可和构建均可用。

因此，此处已定位到诊断协议不兼容；没有依据把它等同于用户未接受许可。没有伪造许可文件、批量输入 yes、修改 Flutter 源码或为了消掉警告换掉 SDK。下一步在首个 Android 构建中检查实际使用组件和 Gradle 结果；若需要特定更新再有针对性处理，若出现确实未接受的条款再由有权用户处理。

官方依据：[Homebrew CocoaPods](https://formulae.brew.sh/formula/cocoapods)、[Android CLI](https://developer.android.com/tools/agents/android-cli)。具体版本及诊断来自本机实际输出，非网页推断。

## 复现命令

在仓库根目录：

```sh
pod --version
flutter doctor -v
.venv/bin/python -m unittest discover -s tools/content -v
.venv/bin/python tools/content/validate.py docs/content/fixtures/*.json
git status --short
```

当前 Android 警告保留，不能写“工具链全部通过”。首个 Flutter 工程建立后才能执行 flutter analyze/test/build；本轮未执行这些不存在工程的命令。
