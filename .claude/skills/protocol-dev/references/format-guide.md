# 回复格式规范

## 禁止使用 Markdown 表格

由于对话框不支持表格渲染，所有需要对比或列举的信息，请使用以下替代格式：

- **列表形式**：用无序列表或有序列表展示
- **分组描述**：用加粗标题 + 缩进描述的方式
- **对比格式**：使用 `A vs B` 或分段描述的方式

## 功能对比示例（禁止用表格）

**方案 A**
- 特性 1：✅ 支持
- 特性 2：⚠️ 需额外工作

**方案 B**
- 特性 1：❌ 不支持
- 特性 2：✅ 支持

## 文件修改清单格式

需要修改的文件：

- `{{路径/文件}}`：{{修改说明}}
- `{{路径/文件}}`：{{修改说明}}

## 方案输出规范

在提出技术方案时，文件清单必须遵循以下格式：

### 新增文件

标注完整路径（从项目根目录开始）和说明：

- `{{路径/文件}}`：{{说明}}

### 修改文件

同样标注完整路径：

- `{{路径/文件}}`：{{说明}}

### 构建系统登记

本项目**绝大多数新文件无需手工登记**：

- **Java 类**（`src/main/java/cn/iyque/**`）：Maven 自动编译整个源码树，无需登记。
  但注意包扫描边界——组件必须落在 `cn.iyque` 包下才会被 Spring 扫到；
  MyBatis Mapper 接口必须在 `cn.iyque.mapper`（`IyQueApplication` 上的 `@MapperScan` 指定）。
- **Vue 组件 / 页面**：Vite 自动解析，无需登记。但**新增路由页面要登记到路由表**：
  - PC：`frontEnd/pc/src/router/routes.js`
  - 移动端：`frontEnd/mobile/src/router/routes.js`（注意 `meta.noAuth` 决定是否走企微授权）
- **移动端 `src/components/` 下的组件**：`main.ts` 用 `import.meta.glob` 全局自动注册，**不要**再手动 import。

**需要手工同步的例外**（新增时必须在方案里点明）：

- 新增 **MyBatis XML**：必须放在 `src/main/resources/mapper/`，
  否则 `mybatis-plus.mapper-locations: classpath*:mapper/**/*.xml` 扫不到。
- 新增 **JPA 实体**：确认在 `cn.iyque.entity` 下；本项目 `ddl-auto: none`，
  **实体加字段不会自动建列**，必须同时提供 `ALTER TABLE` 迁移语句。
- 新增 **依赖**：改 `pom.xml` / `package.json` 后要说明是否需要重新构建镜像或重装依赖。

### 执行后提醒

创建新文件后，按上面「例外」清单逐项确认，并提醒用户：

1. 新增 JPA 实体字段 / 新表 → **必须给出 `ALTER TABLE` 语句**，禁止重导 `scrm_push.zip`
2. 新增依赖 → 后端需 `mvn clean package` 重打 jar；前端需重新 `npm install`
3. 新增路由页面 → 确认已登记进对应 `routes.js`
