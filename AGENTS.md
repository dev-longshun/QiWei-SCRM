# QiWei-SCRM — Agent 协作协议（Claude / Codex / Grok 通用）

> 本文件是 Claude、Codex 与 Grok 的**唯一协作协议真源**。`CLAUDE.md` 是指向本文件的符号链接，各 agent 读到的内容完全一致。改协议只改本文件。

## 项目定位

**企业微信 SCRM 的私有化部署与二次开发**——基于 [源雀 SCRM 开源版](https://github.com/IYque/Iyque-SCRM)（Apache 2.0）二开，用于管理自有企业微信的客户资产：员工活码获客、客户自动打标签与备注、群发营销、客户/客群/标签同步。技术架构：

- **后端**：Java 17 · Spring Boot 2.7.3 · JPA + MyBatis-Plus · MySQL 8 · Redis · WxJava(weixin-java-cp)
- **前端**：Vue 3 · Vite · Pinia。两个独立工程——`frontEnd/pc`（PC 管理后台）与 `frontEnd/mobile`（企微侧边栏 / H5）
- **部署**：Docker Compose（MySQL + Redis + fat jar）+ nginx 反代

职责边界：

- 改**企微接口调用、业务逻辑、定时任务** → `src/main/java/cn/iyque/`
- 改**管理后台界面** → `frontEnd/pc/`
- 改**员工侧边栏 / 客户 H5**（投诉、公海、H5营销）→ `frontEnd/mobile/`
- 改**部署、nginx、容器、备份** → `deploy/`
- 改**表结构** → 见下方红线，**不能直接改 `configFile/scrm_push.zip`**

## 关联仓库

| 仓库 | 地址 | 定位 |
|------|------|------|
| **origin** | `dev-longshun/QiWei-SCRM` | 本项目，工作分支 `main` |
| **upstream** | `IYque/Iyque-SCRM` | 源雀官方，只拉不推；本地 `master` 分支跟它同步 |
| 服务器资产 | `../vps/txyun-longjin/` | 生产服务器建档与 SSH 密钥（git-crypt 加密） |

## 项目基础信息

- **最低支持版本 / 运行环境**：**JDK 17**（`pom.xml` 的 `maven.compiler.source/target`）· Node **≥ 20**（vite 6 要求）· MySQL 8 · Redis 7
- **工程文件**：`pom.xml` · `frontEnd/pc/package.json` · `frontEnd/mobile/package.json` · `deploy/server/docker-compose.yml`
- **语言 / 技术栈**：Java 17 / Spring Boot 2.7.3 / Vue 3 / Vite 6 / Element Plus(pc) / Vant(mobile)
- **其他关键配置**：
  - 后端端口 **8085**（容器内），生产映射宿主机 **18085**（只绑 127.0.0.1）
  - 生产环境：腾讯云上海 `122.51.26.145`，路径 `/root/qiwei-scrm/`，静态前端 `/var/www/qiwei/`
  - 生产密钥在 `deploy/server/.env`（**不入库**）

## 项目结构

- `src/main/java/cn/iyque/` — 后端。`controller/` · `service/impl/` · `entity/` · `strategy/callback/`（企微回调的动作策略）· `utils/` · `config/`
- `src/main/resources/` — `application.yml`（本地默认配置）· `mapper/`（MyBatis XML）· `prompts/`
- `frontEnd/pc/` — PC 管理后台，路由 base `/tools/`，dev 端口 2024
- `frontEnd/mobile/` — 企微侧边栏 / H5，路由 base `/openmobile/`，dev 端口 1026
- `configFile/` — 上游自带：`nginx.conf` 示例、**`scrm_push.zip`（建表 SQL，52 张表）**
- `deploy/` — 本项目新增的部署脚手架：`docker-compose.yml`(本地) · `server/`(生产) · `部署说明.md` · `实施记录.md`
- `docs/tasks/` — 大任务活档案（task-dossier 用）

## 启动协议（进入仓库先读什么）

进入本仓库后，agent 必须先读取本协议文件，并按需检查：

- 本文件（`AGENTS.md` / `CLAUDE.md`，同一份软链）
- `.claude/skills/*/SKILL.md` —— skill 唯一真源（Codex 经 `.codex/skills`、Grok 经 `.grok/skills` 软链读同一份）
- `deploy/部署说明.md` —— 部署构成、企微对接、上线安全清单
- `deploy/实施记录.md` —— 项目进度、企微后台配置全流程、已踩过的坑

同一规则多处重复时，以更具体、更靠近当前任务的文件优先。

## 开发协议（自动触发 skill）

开始任何任务前，凡触发条件匹配，必须先读取对应 skill（位于 `.claude/skills/`）：

- `protocol-dev`：开发工作流协议。代码修改、bug 调试、commit 生成、分支合并、文档更新等任务时触发。强制"先给方案、等授权、再执行"。
- `task-dossier`：大任务分阶段开发与跨会话续接。分析新功能思路时自动评估是否需分阶段并推荐建档；开新会话 / 上下文将满时自动总结进度并产出续接启动词。
- `model-handoff`：模型间任务交接（主会话 ⇄ 外包 agent，默认 Claude ⇄ Grok；`user-invocable: true`）。规划时若某子任务「范畴可界定、机械、高 token、可独立验证」（如批量扫描上游 diff、全量接口清单梳理、大范围日志爬梳），自动过适配闸门并建议外包代跑；产物**强制拉回源头抽查验证**再采信。
- `bug-patrol`：系统化排查 bug 时触发。功能区划分见 `bug-patrol/references/area-map.md`。
- `sync-skills`：把本项目协议智能适配同步到本机其他仓库时触发。

## 工作流唯一性

- 普通开发任务只用 `.claude/skills/protocol-dev` 作为主工作流；用户明确点名的专项 skill 可按需叠加。
- 用户方案确认后回复"执行 / 开始开发 / 改吧 / 做吧"，必须**直接进入实现与验证**；不得再插入额外的规格文档、计划文档、TDD、代码审查或文档提交门槛。
- 未经用户明确要求，不得自动创建 / 提交设计文档，也不得自动 `git commit`。

## 关键约束

> 本文件只列**红线**与**skill 索引**，**不是操作手册**。凡某任务有对应 skill/reference，**产出结果前必须先读它，严禁凭本文件的概述直接生成**（commit/merge 信息尤其如此）。

**Skill 自动触发（强制）**：任何任务开始前，必须检查 `.claude/skills/`。触发条件匹配当前任务的 skill 必须先读取再执行，禁止跳过；本文件的任何概述都**不构成「已了解规范」**，不得据以跳过 skill。

**红线（完整、绝对）**

- **禁止永久删除**：禁止 `rm` / `rm -rf` / `git clean -f`，删除必须用 `trash`（进废纸篓可恢复）。
- **危险 git 前备份**：`git filter-branch` / `git checkout -- .` / `git restore` / `git reset --hard` 等可能丢文件的命令前，先备份受影响文件。
- **JDK 17 / Spring Boot 2.7 底线**：所有代码必须兼容 **JDK 17** 与 **Spring Boot 2.7.3**。最易踩的是包名——本项目用 `javax.persistence` / `javax.servlet`，**不是** Spring Boot 3 的 `jakarta.*`。详见 `platform-compat-guide.md`。
- **表结构变更**：`configFile/scrm_push.zip` 是上游提供的建表 SQL。**禁止直接重导 SQL 到已有数据库**（会清空全部客户数据）。表结构变更一律写 `ALTER` 迁移脚本；上游更新了该 zip 时，必须 diff 新旧 SQL 后手工写迁移。
- **密钥不入库**：`deploy/server/.env` 含数据库密码、JWT 密钥、管理员密码，已在 `.gitignore`。禁止把任何真实密钥写进代码、配置模板或文档。
- **生产动作需明确授权**：`deploy/server/deploy.sh`、SSH 到生产服务器执行写操作、`docker compose` 重启/删除、数据库变更，**必须先展示完整命令并等用户授权**。只读操作（查看日志、探测状态）可直接执行。
- **上游改动要可追溯**：本仓库是上游的二开。修改上游文件时，commit 信息必须说清「改了什么、为什么」，便于将来 `git merge upstream/master` 时判断冲突取舍。合并流程见 `deploy/部署说明.md` 第八节。

**必须先读对应 reference 才能产出（严禁凭本文件直接做）**

- **commit / merge 信息** → `.claude/skills/protocol-dev/references/commit-guide.md`（格式结构 · type↔emoji 映射 · Merge 专用 `chore:🔀` 格式 · merge 用 `git diff --cached` 而非 `git diff HEAD`）——不读不得生成。
- **分支合并** → `merge-guide.md` + `commit-guide.md`；合并必须 `--no-commit --no-ff`，未经用户再次明确要求不执行 `git commit`。
- **Bug 调试** → `debug-guide.md`｜**写后端/前端代码** → `platform-compat-guide.md`｜**方案输出 / 回复格式** → `format-guide.md`｜**标准交互工作流** → `workflow-guide.md`｜**部署发布** → `release-guide.md`｜**构建 / 运行** → protocol-dev「构建与运行规范」
