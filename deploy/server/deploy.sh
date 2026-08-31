#!/usr/bin/env bash
# 源雀SCRM 部署/更新脚本（在本机 Mac 上运行，推送到 txyun-longjin 腾讯云上海）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
KEY="/Users/longshun/Desktop/Program/00_use/vps/txyun-longjin/claude-txyun-longjin-ed25519"
HOST="root@122.51.26.145"
SSH="/usr/bin/ssh -o StrictHostKeyChecking=no -i $KEY"
APP=/root/qiwei-scrm
WEB=/var/www/qiwei

echo "[1/5] 构建"
(cd "$ROOT" && mvn -q -B clean package -DskipTests)
(cd "$ROOT/frontEnd/pc" && npm run build >/dev/null)
(cd "$ROOT/frontEnd/mobile" && npm run build >/dev/null)

echo "[2/5] 上传后端"
$SSH $HOST "mkdir -p $APP/{app,config,sql,upload,data} $WEB"
rsync -az -e "$SSH" "$ROOT/target/iyque-code-1.0-SNAPSHOT.jar" "$HOST:$APP/app/app.jar"
rsync -az -e "$SSH" "$ROOT/deploy/server/docker-compose.yml" "$ROOT/deploy/server/.env" "$HOST:$APP/"
rsync -az -e "$SSH" "$ROOT/deploy/server/config/" "$HOST:$APP/config/"

echo "[3/5] 上传前端"
rsync -az --delete -e "$SSH" "$ROOT/frontEnd/pc/dist/"     "$HOST:$WEB/tools/"
rsync -az --delete -e "$SSH" "$ROOT/frontEnd/mobile/dist/" "$HOST:$WEB/openmobile/"
$SSH $HOST "chown -R www-data:www-data $WEB && chmod -R a+rX $WEB"

echo "[4/5] 重启后端"
$SSH $HOST "cd $APP && docker compose up -d && docker compose restart backend"

echo "[5/5] 校验"
sleep 8
$SSH $HOST "cd $APP && docker compose ps"
curl -s -o /dev/null -w "http://122.51.26.145/tools/  => %{http_code}\n" http://122.51.26.145/tools/
