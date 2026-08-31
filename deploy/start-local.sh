#!/usr/bin/env bash
# 源雀SCRM 本地一键启动（macOS）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$ROOT/deploy/logs"; mkdir -p "$LOG"

# SQL 来自仓库自带的 configFile/scrm_push.zip，不单独进版本库
[ -f "$ROOT/deploy/sql/scrm_push.sql" ] || {
  echo "[0/4] 解压建表 SQL ..."
  mkdir -p "$ROOT/deploy/sql"
  unzip -o -q "$ROOT/configFile/scrm_push.zip" -d "$ROOT/deploy/sql"
  rm -rf "$ROOT/deploy/sql/__MACOSX"
}

echo "[1/4] 启动 MySQL + Redis ..."
docker compose -f "$ROOT/deploy/docker-compose.yml" up -d
until docker exec iyque-mysql mysqladmin ping -h127.0.0.1 -uroot -proot --silent >/dev/null 2>&1; do sleep 2; done
echo "     MySQL ready (127.0.0.1:10179, db=scrm_ky)"

echo "[2/4] 启动后端 :8085 ..."
[ -f "$ROOT/target/iyque-code-1.0-SNAPSHOT.jar" ] || (cd "$ROOT" && mvn -B clean package -DskipTests)
nohup java -jar "$ROOT/target/iyque-code-1.0-SNAPSHOT.jar" > "$LOG/backend.log" 2>&1 &
until grep -q "Started IyQueApplication" "$LOG/backend.log" 2>/dev/null; do sleep 2; done
echo "     后端已启动"

echo "[3/4] 启动 PC 后台 :2024 ..."
(cd "$ROOT/frontEnd/pc" && nohup npm run dev > "$LOG/pc.log" 2>&1 &)

echo "[4/4] 启动移动端 :1026 ..."
(cd "$ROOT/frontEnd/mobile" && nohup npm run dev > "$LOG/mobile.log" 2>&1 &)

sleep 6
echo
echo "=========================================="
echo " PC 后台   http://localhost:2024/tools/"
echo " 移动端    http://localhost:1026/openmobile/"
echo " 后端 API  http://localhost:8085"
echo " 账号/密码 iyque / iyque.cn"
echo "=========================================="
