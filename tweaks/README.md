# 插件源码

`repo/` 只放编译好的 `.deb`,这里放这些插件的**源码**。当前面向无根越狱(rootless,例如
Dopamine / roothide),最低系统 iOS 15.0,依赖 ElleKit(不依赖旧版 mobilesubstrate)。

| 插件 | 目录 | 作用 |
| --- | --- | --- |
| SpeedSpring | [`speedspring/`](speedspring) | 加快 SpringBoard 系统动画速度,过热/低电量模式时自动收回倍速 |
| MemSweeper | [`memsweeper/`](memsweeper) | 系统内存告警时清理后台 App |
| BlurBeGone | [`blurbegone/`](blurbegone) | 关闭毛玻璃/半透明渲染,降低 GPU 负载 |
| StorageSweep | [`storagesweep/`](storagesweep) | 定期清理各 App 缓存目录 |
| PowerGuard | [`powerguard/`](powerguard) | 设备过热或开启低电量模式时清理后台 App,减少 CPU/GPU 负载 |

## 环境准备

SpeedSpring / MemSweeper / BlurBeGone / PowerGuard 是 Theos(Logos)工程,需要先装好
[Theos](https://theos.dev) 并设置 `$THEOS`:

```bash
export THEOS=~/theos
```

StorageSweep 是纯脚本 + LaunchDaemon,不需要 Theos,直接 `dpkg-deb` 打包,见
[`storagesweep/README.md`](storagesweep/README.md)。

四个 Theos 工程已经在装有完整 Theos 工具链(clang + 9.3~16.5 SDK)的环境里实际跑过
`make package`,能编译、链接、签名、打出 `.deb`,不是只过了语法检查。构建时发现并修好了两个问题,
供你自己的环境遇到同样报错时参考:

- `TARGET := iphone:clang:latest:15.0` 里的 `latest` 会解析到最新的 SDK(16.5),但当时那套
  Theos 自带的 clang 版本跟 16.5 / 15.6 SDK 自带的 `usr/include/c++/v1/module.modulemap` 有冲突,
  编译期报 `redefinition of module 'std_config'` / `cyclic dependency in module 'Darwin'`。
  换成显式钉住 `iphone:clang:14.5:15.0`(只是编译时用的头文件版本,`-mios-version-min` 仍然是
  15.0,不影响最终产物的最低系统要求)之后编译通过。如果你自己的 Theos 环境没这个问题,
  改回 `latest` 也没问题。
- Filter plist 文件名必须和 `TWEAK_NAME` 完全一致(大小写敏感),比如 `SpeedSpring.plist`
  而不是 `speedspring.plist`,不然 `make package` 最后一步会报缺少 filter plist。现在四个目录
  下的文件名都已经改成正确的大小写。

## 构建

逐个目录构建(已验证可用):

```bash
for t in speedspring memsweeper blurbegone powerguard; do
  (cd "tweaks/$t" && make package)
done
```

单个插件:

```bash
cd tweaks/speedspring
make package   # 生成的 .deb 在 ./packages/ 下
```

`tweaks/Makefile` 提供了一个聚合入口(`cd tweaks && make package`),但部分 Theos 版本上会报
`Theos version mismatch! common.mk [version 0] loaded in tandem with rules.mk [...]`,遇到就用
上面逐个目录的方式,不要在聚合入口上纠结。

四个 Makefile 都已经写死 `THEOS_PACKAGE_SCHEME = rootless`,产物路径会自动带上 `/var/jb` 前缀,
匹配无根越狱的文件系统布局(实测 `.deb` 里的文件确实落在
`var/jb/Library/MobileSubstrate/DynamicLibraries/` 下)。如果哪天换成有根越狱(rootful),
把对应 Makefile 里 `THEOS_PACKAGE_SCHEME` 那一行删掉即可。

正式发布前建议加上 `FINALPACKAGE=1`(去掉调试符号、包名不带 `+debug` 后缀):

```bash
make package FINALPACKAGE=1
```

## 发布到本仓库

```bash
"../scripts/add-package.sh" "/path/to/xxx.deb"
"../scripts/build-repo.sh"
```

流程与仓库根目录 `README.md` 里描述的一致。发布前记得给每个插件生成/更新
`repo/depictions/<bundle-id>.html`(用 `scripts/new-depiction.sh`)。

## 关于私有 API 的说明

MemSweeper / PowerGuard 用到了 `FrontBoard.framework` 的 `FBProcessManager` /
`FBApplicationProcess`(清理后台 App),PowerGuard 还用了 `LowPowerMode.framework` 的
`_PLLowPowerMode`(自动开关低电量模式)。这几个类和方法签名已经对照 Theos 自带的 vendor
头文件核实过(不是凭印象猜的),`_PLLowPowerMode` 的头文件本身标注了
`API_AVAILABLE(ios(15.0))`,跟这几个插件的最低系统要求一致。

不同 iOS 版本的私有 API 方法签名仍然可能变化,升级系统后如果插件失效,需要对照当时系统的
私有头文件重新核实。这是越狱插件开发的常态,不是本仓库特有的问题。
