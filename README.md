# SR-Rules —— Shadowrocket 规则每日合并

每天北京时间 9:00 自动从 [Johnshall/Shadowrocket-ADBlock-Rules-Forever](https://github.com/Johnshall/Shadowrocket-ADBlock-Rules-Forever) 拉取上游配置，与本地 [`sr_custom_banlist.conf`](sr_custom_banlist.conf) 合并后提交到本仓库 `dist/` 目录（文件名与上游一致）。

## 合并逻辑

- **命名约定（自动匹配）**：本地自定义规则文件以 `sr_custom_<X>.conf` 命名，脚本自动发现所有此类文件，每个文件**只合并进名字包含 `<X>` 的上游配置**：
  - `sr_custom_banlist.conf` → 仅 `*banlist*` 的配置（当前为 `sr_top500_banlist.conf`、`sr_top500_banlist_ad.conf`）；
  - 例如新增 `sr_custom_whitelist.conf` → 自动仅合并进 `*whitelist*` 配置，无需改脚本；
  - 一个上游配置可同时命中多个自定义文件（如 `sr_custom_banlist.conf` 与 `sr_custom_top500_banlist.conf`），按文件名顺序依次插入；
  - 未命中任何自定义文件的配置原样透传到 `dist/`。
- 自定义规则整块插入到命中的上游配置 `[Rule]` 段的**最前面**；Shadowrocket 规则自上而下匹配，因此自定义规则优先于上游规则生效（可用来覆盖上游的 DIRECT/REJECT 行为）；
- 每个来源块以 `# >>> auto-merged from <文件名> begin ... >>>` / `# <<< ... end <<<` 标记；
- 规则文件为空 → 构建失败；规则全部注释 → 视为有意停用，警告后按仅注释块合并；
- 构建脚本会校验下载完整性（必须包含 `[Rule]` 段），异常时任务失败、不会产生坏提交。

## 同步的配置清单

`sr_top500_banlist_ad.conf`、`sr_top500_whitelist_ad.conf`、`sr_top500_banlist.conf`、`sr_top500_whitelist.conf`、`sr_cnip_ad.conf`、`sr_cnip.conf`、`sr_direct_banad.conf`、`sr_proxy_banad.conf`、`sr_backcn.conf`、`sr_backcn_ad.conf`、`sr_ad_only.conf`

增删上游配置：修改 `scripts/build.sh` 里的 `CONFIGS` 数组；新增自定义规则集：直接创建 `sr_custom_<X>.conf` 文件即可。

## 产物固定访问地址

每次构建成功后，workflow 会把 `latest` 标签强制移动到最新提交，因此以下地址**永久固定**，始终指向最近一次成功构建的产物（Shadowrocket 订阅地址直接填它即可）：

```
https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/<配置文件名>
```

全部 11 个：

| 配置 | 固定地址 |
| --- | --- |
| sr_top500_banlist_ad.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_top500_banlist_ad.conf |
| sr_top500_whitelist_ad.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_top500_whitelist_ad.conf |
| sr_top500_banlist.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_top500_banlist.conf |
| sr_top500_whitelist.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_top500_whitelist.conf |
| sr_cnip_ad.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_cnip_ad.conf |
| sr_cnip.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_cnip.conf |
| sr_direct_banad.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_direct_banad.conf |
| sr_proxy_banad.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_proxy_banad.conf |
| sr_backcn.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_backcn.conf |
| sr_backcn_ad.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_backcn_ad.conf |
| sr_ad_only.conf | https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/sr_ad_only.conf |

> 说明：`latest` 是"移动标签"，每次构建后被 `-f` 重打到新 commit；若需要**版本快照**语义（同一 URL 内容永久不变），可基于它再打带日期的标签或直接使用对应 commit 的 raw 地址。

## 二维码（qrcode/）

每个配置对应一张固定内容的导入二维码（`qrcode/<配置名>.png`），扫码即在 Shadowrocket 中打开配置导入页。二维码内容为：

```
shadowrocket://config/add/https://raw.githubusercontent.com/demonk/SR-Rules/latest/dist/<配置文件名>
```

- 因指向 `latest` 标签，二维码**一次生成、永久有效**，内容不随每日构建变化；
- 二维码不随每日构建生成（内容为静态地址，无需重建）。仅当 `build.sh` 的 `CONFIGS` 清单增删时，手动重新生成一次并提交：`.venv/bin/python scripts/gen_qrcodes.py`（首次需 `python3 -m venv .venv && .venv/bin/pip install "qrcode[pil]"`）；
- 二维码图片同样有固定地址，例如 `https://raw.githubusercontent.com/demonk/SR-Rules/latest/qrcode/sr_top500_banlist_ad.png`。

## 使用方式

1. 仓库 Settings → Actions → General → Workflow permissions 选择 **Read and write permissions**（或保持代码里的 `permissions: contents: write` 生效的前提：账户未强制默认只读）；
2. 把本仓库推到 GitHub，工作流即按 `0 1 * * *`（UTC）= 北京时间 9:00 自动运行；
3. 合并后的文件从固定 raw 地址引入 Shadowrocket（见上方"产物固定访问地址"）

## 本地手动构建

```bash
bash scripts/build.sh   # 产物在 dist/
```
