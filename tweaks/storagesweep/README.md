# StorageSweep

纯脚本 + LaunchDaemon 实现,不需要 Theos/编译,直接用 `dpkg-deb` 打包。

## 目录说明

```text
storagesweep/
  DEBIAN/control          # 包信息
  DEBIAN/postinst         # 安装后加载 LaunchDaemon
  DEBIAN/postrm           # 卸载时卸载 LaunchDaemon
  var/jb/usr/libexec/storagesweep.sh              # 实际清理脚本
  var/jb/Library/LaunchDaemons/com.biefan.storagesweep.plist   # 每天触发一次
```

路径按**无根越狱(rootless,如 Dopamine / roothide)**的 `/var/jb` 布局给出。不同无根越狱实现的
`/var/jb` 细节可能有差异,安装前建议先在测试机确认。如果你用的是有根越狱(rootful,如
unc0ver/Taurine/checkra1n),把 `var/jb/` 这一层去掉,直接从 `usr/`、`Library/` 开始打包即可,
`postinst`/`postrm`/plist 里的 `/var/jb` 前缀也要一并去掉。

## 打包

```bash
cd tweaks/storagesweep
dpkg-deb -b . ../../repo/debs/com.biefan.storagesweep_1.0.0_iphoneos-arm64.deb
```

打包后回到仓库根目录执行 `scripts/build-repo.sh` 生成索引。

## 行为说明

- 只清理 `/var/mobile/Containers/Data/Application/*/Library/Caches/` 下**各 App 自己沙盒内**的缓存目录,不触碰系统目录,不需要 root 权限提升之外的额外风险操作。
- 默认清理 7 天未修改的文件,每 24 小时触发一次;可通过以下命令调整:

```bash
defaults write /var/mobile/Library/Preferences/com.biefan.storagesweep.plist enabled -bool true
defaults write /var/mobile/Library/Preferences/com.biefan.storagesweep.plist olderThanDays -int 3
```
