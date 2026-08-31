# 功能区域地图（QiWei-SCRM）

> 本文件是 bug-patrol 的排查坐标系：把项目拆成若干功能区，每区记录核心文件、风险等级、检查点。
> 排查时对照本表定位区域，排查结果写入 `00_debug-notes/bug-patrol/`（该目录已 gitignore）。
>
> 风险等级：🔴 高 / 🟡 中 / 🟢 低。所有路径相对 `src/main/java/cn/iyque/` 除非另有标注。

## R1 企微对接与回调 🔴

**最高风险区**：企微所有事件的入口，出错表现为"客户加了好友但什么都没发生"，且**没有前端报错可看**。

- **核心文件**：
  - `controller/IYcallbackController.java` — GET 验签 / POST 收事件
  - `service/impl/WxCpServiceFactory.java` — 构建 WxCpService，**所有接口共用一个 secret**
  - `service/impl/IYqueConfigServiceImpl.java` — 企微凭据读写（`iyque_config` 表）
  - `utils/IYqueCryptUtil.java` — 回调加解密与验签
- **检查点**：
  - [ ] 回调 1 秒响应窗口：`IYqueCustomerInfoServiceImpl#addCustomerCallBackAction` **是同步的**，
        内部串行 4 次企微调用（getContactDetail → 欢迎语 → markTag → updateRemark）。
        网络抖动或某一步变慢就会整体超时 → 企微重推 → 重复打标签
  - [ ] `iyque_config` 为空或字段缺失时的降级（GET 会直接返回 `error`）
  - [ ] 企微重推导致的重复处理（幂等性）
  - [ ] 可信IP 未配 / secret 未授权客户联系 → 所有接口 401，日志里是 WxErrorException
  - [ ] access_token 过期与并发刷新

## R2 员工活码 / 获客外链 / 群码 🔴

核心获客能力，出错直接影响业务。

- **核心文件**：
  - `service/impl/IYqueUserCodeServiceImpl.java` — 员工活码，调企微 `addContactWay`
  - `service/impl/IYqueShortLinkServiceImpl.java` — 获客外链
  - `service/impl/IYqueChatCodeServiceImpl.java` — 群活码
  - `utils/FileUtils.java` — `buildQr()` 自定义 Logo 二维码
- **检查点**：
  - [ ] `configId` 与本地记录不同步（企微侧删了、本地还在，或反之）
  - [ ] 多员工活码的轮询/分配逻辑
  - [ ] 二维码图片生成失败时是否回退到企微原始 `qrCode`（有 `backupQrUrl` 字段）
  - [ ] 活码删除时是否同步调 `deleteContactWay`
  - [ ] `state` 参数传递——回调靠它反查是哪个活码进来的

## R3 客户自动打标签 / 自动备注 / 欢迎语 🔴

- **核心文件**：
  - `strategy/callback/MakeTagCustomerStrategy.java` — `markTag`
  - `strategy/callback/RemarkCustomerStrategy.java` — `updateRemark`
  - `strategy/callback/SendWelcomeMsgStrategy.java` / `SendPeriodWelcomeMsgStrategy.java`
  - `strategy/callback/SaveCustomerStrategy.java`
  - `strategy/callback/ActionContext.java`
- **检查点**：
  - [ ] **备注 20 字符上限**：企微硬限制，`RemarkCustomerStrategy` 会截断。
        活码名过长会把客户昵称切掉
  - [ ] 三种备注规则（活码名 / 标签名 / 添加时间）分支是否都覆盖
  - [ ] `contactDetail.getFollowedUsers()` 用 `.findFirst().get()` — **空集合会抛 NoSuchElementException**
  - [ ] 标签 ID 已在企微侧被删除时 `markTag` 的报错处理
  - [ ] 每个 Strategy 的异常是否被吞掉（catch 后只 log，不影响后续步骤）

## R4 客户 / 客群 / 员工 / 标签同步 🟡

- **核心文件**：
  - `service/impl/IYqueCustomerInfoServiceImpl.java`
  - `service/impl/IYqueTagServiceImpl.java` · `IYqueTagGroupServiceImpl.java`
  - `service/impl/IYqueUserServiceImpl.java` · `IYqueDeptServiceImpl.java`
- **检查点**：
  - [ ] 分页游标（cursor）翻页是否漏数据
  - [ ] 全量同步与增量回调的数据打架
  - [ ] 客户流失（`DEL_FOLLOW_USER`）状态更新
  - [ ] 同步中断后的重入
  - [ ] 通讯录可见范围外的员工

## R5 认证与权限 🔴

- **核心文件**：
  - `utils/JwtUtils.java` — **密钥来自 `IYQUE_JWT_SECRET` 环境变量**（上游硬编码已改）
  - `config/JwtConfig.java` — 拦截器与白名单
  - `controller/IYqueLoginController.java`
  - `aop/RateLimitAspect.java` — 登录限流，5 次失败锁 5 分钟（Redis）
- **检查点**：
  - [ ] 白名单 `excludePathPatterns` 是否漏放或多放（多放 = 越权）
  - [ ] 密钥长度与算法：48 字节 → HS384，64 字节 → HS512。改密钥会让所有已签发 token 失效
  - [ ] Redis 不可用时限流切面的行为（是放行还是拒绝）
  - [ ] 企微 H5 侧 `weComLogin` 的 authCode 换 token 流程

## R6 文件与素材 🟡

- **核心文件**：
  - `controller/FileController.java` — `/file/fileView/`（白名单内，**未鉴权**）、`/file/openUpload`
  - `service/impl/IYqueMaterialServiceImpl.java`
  - 配置：`iyque.uploadDir`（生产为 `/app/upload`，挂载到宿主机）
- **检查点**：
  - [ ] `fileView` 在 JWT 白名单里 → **路径穿越风险**，确认有无 `../` 过滤
  - [ ] 上传大小上限（`spring.servlet.multipart` 20MB，nginx `client_max_body_size` 也是 20M，两处要一致）
  - [ ] 容器重建后 upload 目录是否还在（靠 volume 挂载）

## R7 群发营销 🟡

- **核心文件**：`service/impl/IYqueGroupMsgServiceImpl.java` · `controller/IYqueGroupMsgController.java`
- **检查点**：
  - [ ] 企微群发频次限制与失败重试
  - [ ] 大批量任务的异步与超时
  - [ ] 附件 media_id 过期（企微临时素材 3 天）

## R8 前端 · PC 管理后台 🟡

- **核心文件**：`frontEnd/pc/src/`（`sys.config.ts` · `utils/request.js` · `router/routes.js` · `views/config/agent.vue`）
- **检查点**：
  - [ ] `sys.config.ts` 的环境匹配：production 是兜底环境，靠 `location.origin` 拼 `BASE_API`
  - [ ] 401 拦截与跳登录
  - [ ] 页面上的静态提示文案 ≠ 接口错误（排查前先确认哪个）

## R9 前端 · 移动端 / H5 🟡

- **核心文件**：`frontEnd/mobile/src/`（`sys.config.js` · `config.js` · `stores/index.js` · `router/permission.js` · `utils/request.js`）
- **检查点**：
  - [ ] 企微 OAuth 授权链路（`getWcRedirect` → `weComLogin`），本机浏览器打开必然走不通
  - [ ] `config.js` 里的硬编码 dev token 只在 `NODE_ENV=development` 注入，7 天过期
  - [ ] `router/routes.js` 的 `meta.noAuth`——哪些页面不需要企微授权
  - [ ] JS-SDK 需要可信域名，未备案时不可用

## R10 部署与运维 🟡

- **核心文件**：`deploy/server/`（`docker-compose.yml` · `config/application.yml` · `nginx-*.conf` · `deploy.sh`）
- **检查点**：
  - [ ] 容器内存上限（生产机 3.6G，三容器上限合计 2.15G）
  - [ ] nginx `proxy_pass` 末尾斜杠——决定 `/iyque` 前缀是否被剥掉
  - [ ] `.env` 变量是否都被 compose 正确注入（尤其 `PUBLIC_BASE`）
  - [ ] 备份 cron 是否真的在跑（`/var/log/qiwei-backup.log`）

## R11 AI 能力（未启用）🟢

- **核心文件**：`chain/` · `factory/AiModelFactory.java` · `service/impl/IYqueKnowledge*`
- **说明**：需要 Milvus 向量库和大模型 key，当前未部署。`application.yml` 里的智谱 key 是上游公共 demo key，**不可用于生产**。

---

## 排查状态总览

排查后在此登记各区状态（✅ 已排查 / 🔄 需复查 / ⬜ 未排查）与基线 commit：

- R1 企微对接与回调：⬜ 未排查
- R2 员工活码 / 获客外链：⬜ 未排查
- R3 自动打标签 / 备注 / 欢迎语：⬜ 未排查
- R4 客户 / 客群 / 标签同步：⬜ 未排查
- R5 认证与权限：⬜ 未排查
- R6 文件与素材：⬜ 未排查
- R7 群发营销：⬜ 未排查
- R8 前端 PC：⬜ 未排查
- R9 前端移动端：⬜ 未排查
- R10 部署运维：⬜ 未排查
- R11 AI 能力：⬜ 未排查（未启用）
