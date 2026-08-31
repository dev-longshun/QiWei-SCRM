# 平台 / 版本兼容性规范 (The "VERSION-CHECK" Rule)

在编写任何有版本兼容约束的代码之前，**必须先确认项目的最低支持版本**，避免使用不兼容的 API。

## 当前项目配置

| 层 | 最低版本 | 配置位置 |
|---|---|---|
| 后端 JDK | **17** | `pom.xml` → `maven.compiler.source/target`、`java.version` |
| Spring Boot | **2.7.3** | `pom.xml` → `<parent>` 与 `springboot.version` |
| MySQL | 8.0 | `deploy/server/docker-compose.yml`（镜像 `mysql:8.0.36`） |
| Redis | 7 | 同上（`redis:7-alpine`） |
| Node | **≥ 20** | Vite 6 要求；本机实测 22 可用 |
| Vite | 6 | `frontEnd/*/package.json` |

## 强制检查流程

1. **方案设计阶段**：提出技术方案时，如涉及较新的 API / 语法特性，必须确认其最低支持版本
2. **编码阶段**：使用的所有 API 必须兼容上表版本
3. **如需使用新版本 API**：必须做可用性检查或提供降级实现

## 本项目实际踩过的版本坑

### 后端：Spring Boot 2.7 ≠ 3.x（最高频错误）

Spring Boot 2.7 仍在 **Java EE (`javax.*`)** 命名空间，**不是** Boot 3 的 Jakarta EE (`jakarta.*`)。
写实体类、过滤器、Servlet 相关代码时最容易搞错：

- `javax.persistence.*`（`@Entity` `@Id` `@Column` `@Lob`）→ **不是** `jakarta.persistence.*`
  - 参考现有代码：`src/main/java/cn/iyque/entity/IYqueConfig.java`
- `javax.servlet.*`（`HttpServletRequest` 等）→ **不是** `jakarta.servlet.*`
- `javax.validation.*` → **不是** `jakarta.validation.*`

> 症状：编译报 `package jakarta.persistence does not exist`，或注解不生效、实体不被扫描。

### 后端：JDK 17 的语法边界

可用：`record` · `sealed` · `switch` 表达式 · 文本块 · `var` · `instanceof` 模式匹配。
**不可用**（JDK 21+）：虚拟线程（`Thread.ofVirtual()`）· `SequencedCollection`（`list.getFirst()`）·
record 模式匹配 · `switch` 的模式匹配（JDK 21 才转正）。

### 后端：JWT 库是 jjwt 0.12.x 新 API

`pom.xml` 用 `jjwt.version 0.12.6`，API 与网上多数 0.9/0.11 教程不同：

- 新：`Jwts.builder().subject(x).signWith(key).compact()` / `Jwts.parser().verifyWith(key).build()`
- 旧（**不可用**）：`setSubject()` / `signWith(alg, key)` / `parserBuilder()`
- 参考现有代码：`src/main/java/cn/iyque/utils/JwtUtils.java`
- 签名算法由密钥长度自动决定：48 字节 → HS384，64 字节 → HS512

### 前端：PC 工程的 peer 依赖冲突

`frontEnd/pc` 的 `@vitejs/plugin-vue-jsx@3` 声明 peer `vite ^4 || ^5`，而项目用 vite 6，
导致 `npm install` 与 `npm ci` 都以 `ERESOLVE` 失败。该插件**并未被 `vite.config.ts` 引用**，是上游遗留：

```bash
cd frontEnd/pc && npm install --legacy-peer-deps
```

移动端工程无此问题，正常 `npm install`。

### 前端：BASE_API 必须保持绝对地址

`sys.config` 的 `BASE_API` 在运行时按 `location.origin` 拼接成绝对地址，
**不能改成相对路径** —— `frontEnd/mobile/src/views/chat/detail.vue:203` 会用正则
`BASE_API.match(/\/\/([^\/]+)/)[1]` 从中抠主机名拼 WebSocket 地址，相对路径会抛 TypeError。

### 部署：nginx 1.22/1.24 的 http2 写法

独立指令 `http2 on;` 是 nginx **1.25.1+** 才有。生产用的是 1.24，必须写在 listen 上：

```nginx
listen 443 ssl http2;     # ✅ nginx 1.22 / 1.24
# http2 on;               # ❌ 1.25.1+ 才支持
```

## 🚫 严禁行为

- ❌ 不查版本直接使用新 API
- ❌ 照抄网上 Spring Boot 3 / jjwt 0.11 的写法
- ❌ 编译或运行报错后才发现版本不兼容

## ✅ 正确做法

- ✅ 方案设计时主动说明 API 兼容性
- ✅ 拿不准 import 用 `javax` 还是 `jakarta` 时，**先看同目录既有文件怎么写的**
- ✅ 如必须使用新 API，提前告知用户并提供降级方案

## 渐进式增强策略

1. **基础功能保障**：最低版本下核心功能可用
2. **高版本专属功能**：需明确告知所需版本、说明降级策略、评估价值 vs 成本
3. **决策参考**：升级 Spring Boot 2.7 → 3.x 是**全仓库级** breaking change（`javax` → `jakarta` 全量替换 + WxJava/MyBatis-Plus 等依赖同步升级），不得在普通任务里顺手做，必须单独立项。
