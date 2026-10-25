# 由持有人本人创建Pourlune upload key（仅准备，未执行）

本批用户没有现存Android key。以下是给本人在远端Mac终端交互执行的步骤，执行侧没有运行这些命令，也没有生成任何测试/正式私钥。只在用户本人决定创建后使用；密码留在本机，勿发聊天或写入命令行。不要查找或复用FishPilot资产，不创建或重置Play app-signing key。

本机已只读核对：Microsoft OpenJDK21.0.12.1，JAVA home为/Library/Java/JavaVirtualMachines/microsoft-21.jdk/Contents/Home；其bin/keytool和bin/jarsigner可用；/usr/bin/keytool为系统入口。具体版本见java-toolchain.json。依据[Android签名指南](https://developer.android.com/studio/publish/app-signing)、[JDK21 keytool](https://docs.oracle.com/en/java/javase/21/docs/specs/man/keytool.html)及[jarsigner密码文件修饰符](https://docs.oracle.com/en/java/javase/17/docs/specs/man/jarsigner.html)。JAR签名用于上传AAB，Play最终APK app-signing证书须另回读，不能混同。

## 1 本人交互创建，不覆盖已有文件

复制此块到本人可交互的远端终端；keytool会要求本人设置并确认口令。alias/证书CN只是应用标识，不虚构经营者姓名/地址。PKCS12使用相同store/key口令。

```sh
(
  set -eu
  umask 077
  pourlune_signing_dir="$HOME/.local/share/pourlune-signing"
  mkdir -p "$pourlune_signing_dir"
  chmod 700 "$pourlune_signing_dir"
  pourlune_upload_key="$pourlune_signing_dir/pourlune-upload.p12"
  if [ -e "$pourlune_upload_key" ] || [ -L "$pourlune_upload_key" ]; then
    echo 'Existing asset found; refusing to overwrite. Stop and verify it.' >&2
    exit 1
  fi
  /Library/Java/JavaVirtualMachines/microsoft-21.jdk/Contents/Home/bin/keytool     -genkeypair -v -storetype PKCS12 -keystore "$pourlune_upload_key"     -alias pourlune-upload -keyalg RSA -keysize 3072 -sigalg SHA256withRSA     -validity 10000 -dname 'CN=Pourlune Upload' </dev/tty
  chmod 600 "$pourlune_upload_key"
)
```

命令仍要求实际交互，不接受password argv；若未显示交互或创建失败，停止并保留错误，不反复覆盖/换密钥。请把加密keystore及口令分别备份到本人控制的可靠安全位置，核对备份可恢复；不要上传Git仓库或把文件发到聊天。丢失/泄露的后续upload-key恢复须按Play正式流程另行处理，不承诺可恢复从未备份的资产。

## 2 只查看公开证书指纹（也由本人执行）

下块只导出公开证书到管道，终端只显示SHA256指纹；keytool可能另在终端询问store口令。不导出私钥。

```sh
/Library/Java/JavaVirtualMachines/microsoft-21.jdk/Contents/Home/bin/keytool   -exportcert -rfc -alias pourlune-upload   -keystore "$HOME/.local/share/pourlune-signing/pourlune-upload.p12" </dev/tty   | /opt/homebrew/bin/openssl x509 -noout -fingerprint -sha256
```

本人确认指纹和alias后，将“已创建、允许该本地路径供Pourlune签名使用”的授权及公开指纹告知架构即可，勿提供密码。签名入口要求指纹pin；错误alias、非PrivateKeyEntry、debug证书、未生效/过期证书均失败关闭。

## 3 获准签名后，密码以本地受限文件供工具读取

本步骤也由本人交互执行，仅将刚才同一口令写入仓库外0600文件。不会把口令打印、放argv或环境；若文件已存在拒绝覆盖。不要通过聊天传递。口令可按本人安全流程在不使用时移除，今后需要时再交互准备；不要自动修改keystore口令。

```sh
/Volumes/data/'App Development'/Pourlune/.venv/bin/python - <<'PY_PASSWORD'
from pathlib import Path
import getpass, os
folder = Path.home() / '.local/share/pourlune-signing'
assert folder.is_dir() and folder.stat().st_mode & 0o077 == 0
password = getpass.getpass('Existing upload keystore password (not displayed): ')
assert len(password) >= 6 and '\n' not in password and '\r' not in password
fd = os.open(folder / 'store-password', os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
with os.fdopen(fd, 'w') as target:
    target.write(password + '\n')
PY_PASSWORD
```

执行侧在得到创建完成及使用授权后，用beta_build的--android-keystore、--android-key-alias、--android-store-password-file和--android-certificate-sha256接入。可选独立key口令文件同样须仓库外私密权限。工具不创建密码文件或密钥，不打印keytool/jarsigner原始错误，不将密码/密码路径放manifest；实际签名和Play签名连续性仍需真实资产后验证。
