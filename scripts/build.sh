#!/usr/bin/env bash
#
# build.sh —— 每日构建脚本
# 1. 从 Johnshall/Shadowrocket-ADBlock-Rules-Forever 拉取上游配置
# 2. 将本地 sr-custom-banlist.conf 合并进每个配置的 [Rule] 段（置于段首、优先生效）
# 3. 合并结果输出到 dist/，文件名与上游配置一致
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CUSTOM_FILE="${REPO_ROOT}/sr-custom-banlist.conf"
OUT_DIR="${REPO_ROOT}/dist"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

BASE_URL="https://johnshall.github.io/Shadowrocket-ADBlock-Rules-Forever"

# 需要同步并合并的上游配置清单（新增/删除配置改这里即可）
CONFIGS=(
  sr_top500_banlist_ad.conf
  sr_top500_whitelist_ad.conf
  sr_top500_banlist.conf
  sr_top500_whitelist.conf
  sr_cnip_ad.conf
  sr_cnip.conf
  sr_direct_banad.conf
  sr_proxy_banad.conf
  sr_backcn.conf
  sr_backcn_ad.conf
  sr_ad_only.conf
)

BEGIN_MARK='# >>> custom-banlist begin (auto-merged, do not edit this block) >>>'
END_MARK='# <<< custom-banlist end (auto-merged) <<<'

fail() { echo "ERROR: $*" >&2; exit 1; }

[[ -f "${CUSTOM_FILE}" ]] || fail "本地自定义规则文件不存在: ${CUSTOM_FILE}"

# 校验自定义规则文件：空文件视为异常直接失败；
# 全部规则被注释（0 条生效）视为"有意停用"，警告后继续（合并块只含注释，不影响上游规则）
if [[ ! -s "${CUSTOM_FILE}" ]]; then
  fail "自定义规则文件为空: ${CUSTOM_FILE}"
fi
if ! grep -qE '^[[:space:]]*(DOMAIN|IP|GEOIP|PROCESS|AND|OR|NOT)' "${CUSTOM_FILE}"; then
  echo "WARNING: 自定义规则文件中没有生效的规则行（已全部注释，产物将回退为纯上游规则）" >&2
fi

mkdir -p "${OUT_DIR}"

merged=0
for name in "${CONFIGS[@]}"; do
  url="${BASE_URL}/${name}"
  raw="${TMP_DIR}/${name}"

  echo "==> 下载 ${url}"
  curl -fsSL --retry 5 --retry-delay 3 --speed-limit 10240 --speed-time 30 --max-time 600 -o "${raw}" "${url}" \
    || fail "下载失败: ${url}"

  # 基本完整性校验：必须包含 [Rule] 段，避免把错误页提交进仓库
  grep -q '^\[Rule\]' "${raw}" || fail "${name} 中未找到 [Rule] 段，疑似下载内容异常，中止"

  awk -v begin="${BEGIN_MARK}" -v end="${END_MARK}" -v custom="${CUSTOM_FILE}" '
    { print }
    /^\[Rule\][[:space:]]*$/ && !inserted {
      print begin
      while ((getline line < custom) > 0) print line
      close(custom)
      print end
      inserted = 1
    }
    END { if (!inserted) exit 2 }
  ' "${raw}" > "${OUT_DIR}/${name}"

  # 校验合并结果
  grep -qF "${BEGIN_MARK}" "${OUT_DIR}/${name}" || fail "${name} 合并失败（未插入自定义规则块）"

  echo "    已合并 -> dist/${name} ($(wc -l < "${OUT_DIR}/${name}" | tr -d ' ') 行)"
  merged=$((merged + 1))
done

echo "完成：共合并 ${merged}/${#CONFIGS[@]} 个配置到 ${OUT_DIR}"
