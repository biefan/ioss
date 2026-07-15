#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "用法: $0 /path/to/package.deb" >&2
  exit 1
fi

PACKAGE_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="${ROOT_DIR}/repo"
TARGET_DIR="${REPO_DIR}/debs"
TARGET_PATH="${TARGET_DIR}/$(basename "${PACKAGE_PATH}")"

if [[ ! -f "${PACKAGE_PATH}" ]]; then
  echo "文件不存在: ${PACKAGE_PATH}" >&2
  exit 1
fi

if [[ "${PACKAGE_PATH}" != *.deb ]]; then
  echo "只接受 .deb 文件: ${PACKAGE_PATH}" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"

if [[ -e "${TARGET_PATH}" ]]; then
  echo "目标已存在，请先手动处理重名包: ${TARGET_PATH}" >&2
  exit 1
fi

cp "${PACKAGE_PATH}" "${TARGET_PATH}"
echo "已复制到: ${TARGET_PATH}"
echo "下一步执行:"
echo "  \"${ROOT_DIR}/scripts/build-repo.sh\""
