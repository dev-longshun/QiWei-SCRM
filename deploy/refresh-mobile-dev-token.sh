#!/usr/bin/env bash
# 移动端本地调试 token 刷新（有效期 7 天，过期后页面会弹"登录状态已过期"）
# 原因：frontEnd/mobile/src/config.js 里硬编码了一个 dev token，上游提交时就是过期的
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/frontEnd/mobile/src/config.js"
OLD=$(grep -o "eyJhbGciOiJIUzM4NCJ9\.[A-Za-z0-9_.-]*" "$CFG" | head -1)
NEW=$(curl -s -X POST http://127.0.0.1:8085/iYqueSys/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"iyque","password":"iyque.cn"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
[ -z "$NEW" ] && { echo "取 token 失败，后端 8085 起来了吗？"; exit 1; }
sed -i '' "s|$OLD|$NEW|" "$CFG"
echo "已更新 config.js 的 dev token（7 天有效）。浏览器硬刷新 Cmd+Shift+R 生效。"
