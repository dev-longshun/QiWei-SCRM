# 部署发布规范

> 本项目没有对外发版渠道（不是 App、不是 npm 包）。「发布」= **把改动部署到生产服务器**。

## 触发条件

用户说"部署"、"上线"、"发到服务器"、"更新生产"、"跑 deploy" 等。

## 核心原则

1. **先谋后动**：展示将执行的完整命令与影响面，等用户确认再动。
2. **不自动部署**：`deploy/server/deploy.sh` 会重启生产服务，**属于对外动作，必须明确授权**。
3. **改数据库先备份**：任何涉及表结构或数据的变更，先跑一次备份再动。

## 生产环境

| 项 | 值 |
|---|---|
| 服务器 | 腾讯云上海 `122.51.26.145`（资产档案 `../vps/txyun-longjin/`） |
| SSH | `ssh -i ../vps/txyun-longjin/claude-txyun-longjin-ed25519 root@122.51.26.145` |
| 应用路径 | `/root/qiwei-scrm/` |
| 静态前端 | `/var/www/qiwei/{tools,openmobile}` |
| 容器 | `qiwei-backend` / `qiwei-mysql` / `qiwei-redis` |
| 备份 | `/root/qiwei-scrm/backup.sh`，cron 每日 04:17，保留 7 天 |

## 工作流程

### 第一步：确认改了什么、影响哪一侧

- 只改后端 → 只需重打 jar + 重启 backend
- 只改前端 → 只需重新 build + 同步静态文件，**不用重启后端**
- 改了 `deploy/server/config/application.yml` 或 `.env` → 需重启 backend
- 改了 `docker-compose.yml` → 需 `up -d`，必要时 `--force-recreate`
- **改了实体 / 表结构 → 先写 `ALTER` 迁移，先备份，再部署**

### 第二步：展示计划并等确认

展示：改动摘要、将执行的命令、是否重启、是否影响数据、回滚方式。

### 第三步：执行

常规部署（构建 → 上传 → 重启 → 校验，一条龙）：

```bash
./deploy/server/deploy.sh
```

手工分步（只想更新前端时）：

```bash
cd frontEnd/pc && npm run build
rsync -az --delete -e "ssh -i <key>" dist/ root@122.51.26.145:/var/www/qiwei/tools/
ssh -i <key> root@122.51.26.145 'chown -R www-data:www-data /var/www/qiwei && chmod -R a+rX /var/www/qiwei'
```

### 第四步：验证（必做，不能只看"命令没报错"）

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://122.51.26.145/tools/
curl -s -X POST http://122.51.26.145/iyque/iYqueSys/login \
  -H 'Content-Type: application/json' -d '{"username":"<user>","password":"<pwd>"}'
ssh -i <key> root@122.51.26.145 'cd /root/qiwei-scrm && docker compose ps && docker logs qiwei-backend 2>&1 | tail -20'
```

## 数据库变更专项

**⚠️ 最高风险动作。**

1. 先备份：`ssh ... '/root/qiwei-scrm/backup.sh'`，确认 `backups/` 里生成了新文件
2. 展示 `ALTER` 语句给用户看，等确认
3. 执行，再验证表结构与数据条数
4. **绝对禁止**用 `configFile/scrm_push.zip` 里的 SQL 重导已有库——那是**建库脚本**，
   里面全是 `DROP TABLE IF EXISTS`，会清空所有客户数据

## 回滚

- **后端**：保留上一版 jar（部署前 `cp app.jar app.jar.bak`），回滚即换回并 `docker compose restart backend`
- **前端**：重新 build 上一个 commit 的产物并同步
- **数据库**：从 `/root/qiwei-scrm/backups/scrm_ky_YYYYMMDD.sql.gz` 恢复
- **配置**：`.env` / `application.yml` 改动前先备份原文件

## 禁止事项

- ❌ 未经确认直接跑 `deploy.sh` / 重启容器 / 改生产数据
- ❌ 改了数据库不先备份
- ❌ 部署完不验证就报告"已完成"
- ❌ 把 `.env` 里的真实密钥贴进对话、commit 或文档
