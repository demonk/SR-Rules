#!/usr/bin/env python3
"""为 dist/*.conf 生成 Shadowrocket 一键导入二维码，输出到 qrcode/<配置名>.png

二维码内容格式（固定地址，指向 latest 标签下最近一次成功构建的产物）:
    shadowrocket://config/add/https://raw.githubusercontent.com/<REPO>/<REF>/dist/<name>.conf

可用环境变量覆盖: QR_REPO(默认 demonk/SR-Rules)、QR_REF(默认 latest)
依赖: pip install 'qrcode[pil]'
"""
import os
import sys
from pathlib import Path

try:
    import qrcode
except ImportError:
    sys.exit("缺少 qrcode 库: pip install 'qrcode[pil]'")

REPO_ROOT = Path(__file__).resolve().parent.parent
DIST_DIR = REPO_ROOT / "dist"
OUT_DIR = REPO_ROOT / "qrcode"

REPO = os.environ.get("QR_REPO", "demonk/SR-Rules")
REF = os.environ.get("QR_REF", "latest")


def main() -> None:
    files = sorted(DIST_DIR.glob("*.conf")) if DIST_DIR.is_dir() else []
    if not files:
        sys.exit(f"{DIST_DIR} 下没有 .conf 产物，请先运行 scripts/build.sh")

    OUT_DIR.mkdir(exist_ok=True)
    for f in files:
        url = f"https://raw.githubusercontent.com/{REPO}/{REF}/dist/{f.name}"
        content = f"shadowrocket://config/add/{url}"
        img = qrcode.make(content, box_size=8, border=2)
        out = OUT_DIR / f"{f.stem}.png"
        img.save(out)
        print(f"{out.name}  <-  {content}")

    print(f"完成：{len(files)} 个二维码 -> {OUT_DIR}")


if __name__ == "__main__":
    main()
