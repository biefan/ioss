#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "用法: $0 com.example.package \"Package Name\"" >&2
  exit 1
fi

BUNDLE_ID="$1"
PACKAGE_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_FILE="${ROOT_DIR}/repo/depictions/${BUNDLE_ID}.html"
CONFIG_FILE="${ROOT_DIR}/repo.conf"

mkdir -p "$(dirname "${TARGET_FILE}")"

if [[ -e "${TARGET_FILE}" ]]; then
  echo "介绍页已存在: ${TARGET_FILE}" >&2
  exit 1
fi

cat > "${TARGET_FILE}" <<EOF
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${PACKAGE_NAME}</title>
    <style>
      :root {
        color-scheme: light;
        --bg: #f5f5f7;
        --card: #ffffff;
        --text: #111111;
        --muted: #666666;
        --line: #e5e5ea;
        --accent: #007aff;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", sans-serif;
        background: linear-gradient(180deg, #fafafa 0%, var(--bg) 100%);
        color: var(--text);
      }

      .wrap {
        max-width: 760px;
        margin: 0 auto;
        padding: 32px 20px 60px;
      }

      .hero,
      .card {
        background: var(--card);
        border: 1px solid var(--line);
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.06);
      }

      .hero {
        padding: 28px;
        margin-bottom: 18px;
      }

      .tag {
        display: inline-block;
        margin-bottom: 12px;
        padding: 6px 10px;
        border-radius: 999px;
        background: rgba(0, 122, 255, 0.1);
        color: var(--accent);
        font-size: 13px;
      }

      h1,
      h2 {
        margin: 0 0 12px;
      }

      p,
      li {
        line-height: 1.7;
        color: var(--muted);
      }

      .card {
        padding: 24px;
        margin-top: 16px;
      }

      ul {
        padding-left: 20px;
        margin: 0;
      }

      code {
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        color: var(--text);
      }
    </style>
  </head>
  <body>
    <main class="wrap">
      <section class="hero">
        <div class="tag">Jailbreak Tweak</div>
        <h1>${PACKAGE_NAME}</h1>
        <p>把这里改成你的插件介绍、适配系统、功能亮点和使用说明。</p>
      </section>

      <section class="card">
        <h2>功能说明</h2>
        <ul>
          <li>功能 1：替换成真实描述</li>
          <li>功能 2：补充使用前提</li>
          <li>功能 3：说明兼容范围</li>
        </ul>
      </section>

      <section class="card">
        <h2>兼容信息</h2>
        <p>包标识：<code>${BUNDLE_ID}</code></p>
        <p>适配系统：请填写，例如 iOS 14 - iOS 16</p>
        <p>依赖说明：请填写，例如 ElleKit / libhooker / mobilesubstrate</p>
      </section>
    </main>
  </body>
</html>
EOF

echo "已创建介绍页: ${TARGET_FILE}"

if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"
  if [[ -n "${REPO_URL:-}" ]]; then
    CLEAN_REPO_URL="${REPO_URL%/}"
    echo "建议在 .deb 控制文件里填写:"
    echo "  Depiction: ${CLEAN_REPO_URL}/depictions/${BUNDLE_ID}.html"
  fi
fi
