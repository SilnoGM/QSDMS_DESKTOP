# Apifox 自动化维护流程

本文档说明 QSDMS 后端接口完成后，如何把接口文档同步到 Apifox，并通过 Apifox 测试套件做自动化回归。

## 1. 基本原则

- 后端代码是接口契约的真相源。
- `DTO`、`class-validator` 和 `@nestjs/swagger` 装饰器必须完整维护。
- Apifox 负责沉淀接口文档、调试用例、场景用例、测试套件和测试报告。
- 不在仓库中提交 `APIFOX_ACCESS_TOKEN`。

## 2. 当前项目配置

- Apifox 项目 ID：`8525101`
- Swagger UI：`/api/docs`
- OpenAPI JSON：`/api/docs-json`
- 离线导出文件：`backend/.generated/openapi.json`

项目 ID 已保存在 `.apifox/settings.json`，仅用于识别项目，不包含敏感信息。

## 3. 本地环境变量

在本机或 CI 中设置以下环境变量：

```bash
export APIFOX_PROJECT_ID=8525101
export APIFOX_ACCESS_TOKEN="<your-apifox-access-token>"
export APIFOX_ENV_ID="<your-apifox-environment-id>"
export APIFOX_TEST_SUITE_ID="<your-apifox-test-suite-id>"
```

`APIFOX_ACCESS_TOKEN` 必须来自本地环境变量或 CI Secret，不得写入 `.env`、脚本、日志或提交记录。

## 4. 安装 Apifox CLI

Apifox CLI 是官方命令行工具，支持登录、项目资源维护、OpenAPI 导入和测试套件运行。请按官方文档安装，并确认本机能识别 `apifox` 命令：

```bash
apifox --version
```

如果未登录，也可以用访问令牌登录：

```bash
apifox login --with-token "$APIFOX_ACCESS_TOKEN"
```

## 5. 导出 OpenAPI

后端不需要启动 HTTP 服务即可导出 OpenAPI：

```bash
cd backend
pnpm openapi:export
```

输出文件：

```text
backend/.generated/openapi.json
```

该文件是生成产物，已被 `.gitignore` 忽略。

## 6. 同步到 Apifox

导出 OpenAPI 后，执行：

```bash
cd backend
pnpm apifox:import
```

该命令会读取：

- `APIFOX_PROJECT_ID`
- `APIFOX_ACCESS_TOKEN`
- `APIFOX_OPENAPI_FILE`

如果未设置 `APIFOX_ACCESS_TOKEN`，脚本会尝试使用当前 Apifox CLI 登录态。

## 7. 运行 Apifox 测试套件

先在 Apifox 中创建测试环境和测试套件，再配置：

```bash
export APIFOX_ENV_ID="<your-apifox-environment-id>"
export APIFOX_TEST_SUITE_ID="<your-apifox-test-suite-id>"
```

运行：

```bash
cd backend
pnpm apifox:test
```

测试报告由 Apifox CLI 输出，并可能生成 `apifox-reports/`，该目录已被 `.gitignore` 忽略。

## 8. 日常接口开发流程

1. 编写或修改后端接口、DTO 和 Swagger 装饰器。
2. 运行后端测试：

```bash
cd backend
pnpm test
pnpm test:e2e
pnpm build
```

3. 导出 OpenAPI：

```bash
pnpm openapi:export
```

4. 同步 Apifox：

```bash
pnpm apifox:import
```

5. 运行 Apifox 测试套件：

```bash
pnpm apifox:test
```

## 9. CI 建议

CI 中只保存 Secret，不提交真实值：

- `APIFOX_ACCESS_TOKEN`
- `APIFOX_ENV_ID`
- `APIFOX_TEST_SUITE_ID`

典型步骤：

```bash
cd backend
pnpm install --strict-peer-dependencies=false
pnpm test
pnpm test:e2e
pnpm build
pnpm openapi:export
pnpm apifox:import
pnpm apifox:test
```

## 10. 令牌安全

访问令牌拥有对应账号可访问团队和项目的权限。若令牌曾经出现在聊天、日志、截图或提交记录中，应立即在 Apifox 中废弃旧令牌，并重新生成新令牌。
