# SR-Rules —— Shadowrocket 规则每日合并

每天北京时间 9:00 自动从 [Johnshall/Shadowrocket-ADBlock-Rules-Forever](https://github.com/Johnshall/Shadowrocket-ADBlock-Rules-Forever) 拉取上游配置，与本地 [`sr-custom-banlist.conf`](sr-custom-banlist.conf) 合并后提交到本仓库 `dist/` 目录（文件名与上游一致）。

## 合并逻辑

- 自定义规则整块插入到每个上游配置 `[Rule]` 段的**最前面**；
- Shadowrocket 规则自上而下匹配，因此自定义规则优先于上游规则生效（可用来覆盖上游的 DIRECT/REJECT 行为）；
- 构建脚本会校验下载完整性（必须包含 `[Rule]` 段），异常时任务失败、不会产生坏提交。

## 同步的配置清单

`sr_top500_banlist_ad.conf`、`sr_top500_whitelist_ad.conf`、`sr_top500_banlist.conf`、`sr_top500_whitelist.conf`、`sr_cnip_ad.conf`、`sr_cnip.conf`、`sr_direct_banad.conf`、`sr_proxy_banad.conf`、`sr_backcn.conf`、`sr_backcn_ad.conf`、`sr_ad_only.conf`

增删配置：修改 `scripts/build.sh` 里的 `CONFIGS` 数组即可。

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

## 使用方式

1. 仓库 Settings → Actions → General → Workflow permissions 选择 **Read and write permissions**（或保持代码里的 `permissions: contents: write` 生效的前提：账户未强制默认只读）；
2. 把本仓库推到 GitHub，工作流即按 `0 1 * * *`（UTC）= 北京时间 9:00 自动运行；
3. 合并后的文件从固定 raw 地址引入 Shadowrocket（见上方"产物固定访问地址"）

## 本地手动构建

```bash
bash scripts/build.sh   # 产物在 dist/
```
