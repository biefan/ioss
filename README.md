# iOS 越狱插件库

这是一个最小可维护的个人越狱插件库骨架，适合托管到 GitHub Pages、Nginx 静态目录或任意可公开访问的 HTTP 目录。

## 目录结构

```text
repo/
  debs/           # 放你的 .deb 包
  depictions/     # 插件介绍页（HTML）
  Packages        # 自动生成
  Packages.gz     # 自动生成
  Packages.bz2    # 自动生成
  Release         # 自动生成
  index.html      # 仓库首页
scripts/
  add-package.sh
  build-repo.sh
  new-depiction.sh
tweaks/           # 插件源码（Theos 工程 / 打包脚本），构建产物放进 repo/debs/
repo.conf
```

插件源码见 [`tweaks/README.md`](tweaks/README.md)。

## 使用方式

1. 修改 `repo.conf` 里的仓库信息，尤其是 `REPO_URL`。
2. 把 `.deb` 包放到 `repo/debs/`。
3. 为每个插件创建介绍页，文件放到 `repo/depictions/`。
4. 执行 `scripts/build-repo.sh` 生成 `Packages`、`Release` 等索引文件。
5. 把 `repo/` 整个目录部署到你的静态站点根目录或子路径。

## 托管方式

当前仓库已经预留了 GitHub Pages 工作流配置。你可以直接把这个目录推到 GitHub 仓库，然后启用 Pages Actions 部署。

- 如果你用 GitHub 默认域名，仓库地址通常会是 `https://你的用户名.github.io/仓库名/`
- 如果你用自定义域名，可以后面再补，不影响现在先开始写插件
- 但要注意：插件控制文件里的 `Depiction` 是绝对 URL，域名一旦变了，旧包里的介绍页地址也会跟着失效，所以正式发包前最好把最终域名定下来

## 推荐插件包字段

你的 `.deb` 包控制文件建议至少包含：

```text
Package: com.example.mytweak
Name: MyTweak
Version: 1.0.0
Architecture: iphoneos-arm64
Description: 示例插件说明
Maintainer: Your Name
Author: Your Name
Section: Tweaks
Depends: mobilesubstrate
Depiction: https://your-domain.example/repo/depictions/com.example.mytweak.html
```

`Depiction` 指向的是网页，不依赖某个特定客户端私有格式，兼容性更稳。如果你把整个当前仓库直接部署到 GitHub Pages，那么实际路径通常会是 `https://你的用户名.github.io/仓库名/depictions/...`。

## 常用命令

```bash
"./scripts/add-package.sh" "/path/to/your-package.deb"
"./scripts/new-depiction.sh" "com.example.mytweak" "MyTweak"
"./scripts/build-repo.sh"
```

## 发布建议

- 你的源地址建议保持稳定，例如 `https://repo.example.com/`
- 不要把未发布或测试中的 `.deb` 直接混在正式源里
- 如果后续要分稳定版和测试版，可以再拆成 `stable/`、`beta/` 两套仓库
