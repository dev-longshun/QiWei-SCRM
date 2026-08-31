#!/usr/bin/env bash
# 源雀SCRM 本地停止（不删数据，数据在 docker volume 里）
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for p in 8085 2024 1026; do
  pid=$(lsof -ti tcp:$p 2>/dev/null); [ -n "$pid" ] && kill -9 $pid && echo "killed :$p"
done
docker compose -f "$ROOT/deploy/docker-compose.yml" stop
echo "已停止。数据保留，下次 ./deploy/start-local.sh 即可。"
echo "要彻底清库重来： docker compose -f deploy/docker-compose.yml down -v"
