#!/usr/bin/env bash
#
# build.sh —— 每日构建脚本
# 1. 从 Johnshall/Shadowrocket-ADBlock-Rules-Forever 拉取上游配置
# 2. 合并规则（命名约定）：本地自定义规则文件以 sr_custom_<X>.conf 命名，
#    只合并进"名字包含 <X>"的上游配置，并置于 [Rule] 段最前（优先生效）。
#    例: sr_custom_banlist.conf  -> 只合并进 *banlist*.conf
#        sr_custom_whitelist.conf -> 只合并进 *whitelist*.conf
#    一个上游配置可命中多个自定义文件（如 banlist 与 top500_banlist），全部按序合并。
# 3. 合并结果输出到 dist/，文件名与上游配置一致；未命中任何自定义文件的配置原样透传。
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${REPO_ROOT}/dist"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

BASE_URL="https://johnshall.github.io/Shadowrocket-ADBlock-Rules-Forever"

# 需要同步的上游配置清单（新增/删除配置改这里即可）
CONFIGS=(
  sr_top500_banlist_ad.conf
  sr_top500_banlist.conf
  sr_top500_whitelist_ad.conf
  sr_top500_whitelist.conf
  sr_cnip_ad.conf
  sr_cnip.conf
  sr_direct_banad.conf
  sr_proxy_banad.conf
  sr_backcn.conf
  sr_backcn_ad.conf
  sr_ad_only.conf
)

fail() { echo "ERROR: $*" >&2; exit 1; }

# ---------- 自动发现自定义规则文件（sr_custom_<X>.conf） ----------
shopt -s nullglob
CUSTOM_FILES=( "${REPO_ROOT}"/sr_custom_*.conf )
shopt -u nullglob

[[ ${#CUSTOM_FILES[@]} -gt 0 ]] || fail "在 ${REPO_ROOT} 下未找到任何 sr_custom_*.conf 自定义规则文件"

custom_key() {  # sr_custom_<X>.conf -> <X>
  local b
  b="$(basename "$1")"
  b="${b#sr_custom_}"
  echo "${b%.conf}"
}

for cf in "${CUSTOM_FILES[@]}"; do
  [[ -s "$cf" ]] || fail "自定义规则文件为空: $cf"
  if ! grep -qE '^[[:space:]]*(DOMAIN|IP|GEOIP|PROCESS|AND|OR|NOT)' "$cf"; then
    echo "WARNING: $(basename "$cf") 中没有生效的规则行（已全部注释，将按仅注释块合并）" >&2
  fi
done

echo "发现自定义规则文件 ${#CUSTOM_FILES[@]} 个:"
for cf in "${CUSTOM_FILES[@]}"; do
  echo "  - $(basename "$cf")  ->  只合并进名字包含 '$(custom_key "$cf")' 的配置"
done

# ---------- 逐个配置下载并按规则合并 ----------
mkdir -p "${OUT_DIR}"

processed=0
for name in "${CONFIGS[@]}"; do
  url="${BASE_URL}/${name}"
  raw="${TMP_DIR}/${name}"

  echo "==> 下载 ${url}"
  curl -fsSL --retry 5 --retry-delay 3 --speed-limit 10240 --speed-time 30 --max-time 600 -o "${raw}" "${url}" \
    || fail "下载失败: ${url}"

  # 基本完整性校验：必须包含 [Rule] 段，避免把错误页提交进仓库
  grep -q '^\[Rule\]' "${raw}" || fail "${name} 中未找到 [Rule] 段，疑似下载内容异常，中止"

  # 收集名字匹配命中的自定义文件
  matching=()
  match_names=""
  for cf in "${CUSTOM_FILES[@]}"; do
    key="$(custom_key "$cf")"
    [[ -n "${key}" ]] || continue
    if [[ "${name}" == *"${key}"* ]]; then
      matching+=("${cf}")
      match_names="${match_names} $(basename "${cf}")"
    fi
  done

  if [[ ${#matching[@]} -eq 0 ]]; then
    cp "${raw}" "${OUT_DIR}/${name}"
    echo "    无匹配的自定义规则，原样透传 -> dist/${name}"
  else
    awk -v list="$(printf '%s\n' "${matching[@]}")" '
      BEGIN { n = split(list, files, "\n") }
      { print }
      /^\[Rule\][[:space:]]*$/ && !inserted {
        for (i = 1; i <= n; i++) {
          b = files[i]
          sub(/.*\//, "", b)
          print "# >>> auto-merged from " b " begin (do not edit this block) >>>"
          while ((getline line < files[i]) > 0) print line
          close(files[i])
          print "# <<< auto-merged from " b " end <<<"
        }
        inserted = 1
      }
      END { if (!inserted) exit 2 }
    ' "${raw}" > "${OUT_DIR}/${name}"

    # 校验每个命中的自定义块都已插入
    for cf in "${matching[@]}"; do
      grep -qF "auto-merged from $(basename "${cf}") begin" "${OUT_DIR}/${name}" \
        || fail "${name} 合并失败（缺少 $(basename "${cf}") 块）"
    done
    echo "    已合并:${match_names} -> dist/${name}"
  fi

  processed=$((processed + 1))
done

echo "完成：共处理 ${processed}/${#CONFIGS[@]} 个配置到 ${OUT_DIR}"
