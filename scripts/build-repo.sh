#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="${ROOT_DIR}/repo"
CONFIG_FILE="${ROOT_DIR}/repo.conf"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "缺少配置文件: ${CONFIG_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${CONFIG_FILE}"

required_tools=(
  dpkg-scanpackages
  gzip
  bzip2
  md5sum
  sha256sum
  stat
  date
)

for tool in "${required_tools[@]}"; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "缺少依赖: ${tool}" >&2
    exit 1
  fi
done

mkdir -p "${REPO_DIR}/debs" "${REPO_DIR}/depictions"

cd "${REPO_DIR}"

if compgen -G "debs/*.deb" >/dev/null; then
  dpkg-scanpackages -m "debs" > "Packages"
else
  : > "Packages"
fi

gzip -kf "Packages"
bzip2 -kf "Packages"

write_release_entry() {
  local algo="$1"
  local file="$2"
  local hash size

  case "${algo}" in
    md5)
      hash="$(md5sum "${file}" | awk '{print $1}')"
      ;;
    sha256)
      hash="$(sha256sum "${file}" | awk '{print $1}')"
      ;;
    *)
      echo "不支持的哈希算法: ${algo}" >&2
      exit 1
      ;;
  esac

  size="$(stat -c '%s' "${file}")"
  printf " %s %16s %s\n" "${hash}" "${size}" "${file}"
}

{
  printf "Origin: %s\n" "${REPO_ORIGIN}"
  printf "Label: %s\n" "${REPO_LABEL}"
  printf "Suite: %s\n" "${REPO_SUITE}"
  printf "Version: %s\n" "${REPO_VERSION}"
  printf "Codename: %s\n" "${REPO_CODENAME}"
  printf "Architectures: %s\n" "${REPO_ARCHITECTURES}"
  printf "Components: %s\n" "${REPO_COMPONENTS}"
  printf "Description: %s\n" "${REPO_DESCRIPTION}"
  printf "Date: %s\n" "$(LC_ALL=C date -Ru)"
  printf "MD5Sum:\n"
  write_release_entry "md5" "Packages"
  write_release_entry "md5" "Packages.gz"
  write_release_entry "md5" "Packages.bz2"
  printf "SHA256:\n"
  write_release_entry "sha256" "Packages"
  write_release_entry "sha256" "Packages.gz"
  write_release_entry "sha256" "Packages.bz2"
} > "Release"

cat <<EOF
仓库索引已生成:
  ${REPO_DIR}/Packages
  ${REPO_DIR}/Packages.gz
  ${REPO_DIR}/Packages.bz2
  ${REPO_DIR}/Release

部署地址请确认与你的 Depiction/源地址一致:
  ${REPO_URL}
EOF
