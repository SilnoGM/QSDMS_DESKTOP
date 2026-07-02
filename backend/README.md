# QSDMS Backend

`backend/` 是 QSDMS 后端工作目录，技术栈为 `NestJS + PostgreSQL + Prisma`。

## 技术栈

- `NestJS`
- `TypeScript`
- `PostgreSQL`
- `Prisma`
- `@prisma/adapter-pg`
- `@nestjs/config`
- `@nestjs/swagger`
- `class-validator`
- `Jest`
- `Supertest`

## 目录结构

```text
src/
  bootstrap.ts
  app.controller.ts
  app.module.ts
  app.service.ts
  common/
    interfaces/
  database/
    prisma.module.ts
    prisma.service.ts
prisma/
  schema.prisma
```

- `bootstrap.ts`：统一配置全局前缀、参数校验和 OpenAPI。
- `common/`：跨模块共享类型和基础能力。
- `database/`：Prisma 注入入口和数据库访问基础设施。
- `prisma/`：数据库 schema 和迁移来源。

## 环境变量

复制 `.env.example` 为 `.env` 后再按本地环境修改。

```bash
DATABASE_URL=postgresql://qsdms:qsdms@localhost:5432/qsdms_desktop?schema=public
PORT=3000
NODE_ENV=development
```

不要提交真实 `.env`。

## 常用命令

```bash
pnpm install
pnpm prisma:generate
pnpm test
pnpm test:e2e
pnpm build
pnpm start:dev
```

## API

- 健康检查：`GET /api/health`
- OpenAPI 文档：`/api/docs`

## 约束

- 公共 API、DTO、数据库 schema 修改前需要先确认。
- 所有核心业务数据以后端和 PostgreSQL 为准。
- Prisma 客户端统一通过 `PrismaModule` 注入，不在业务模块中手动创建。
- 不在日志中输出密码、Token、数据库连接串或用户隐私数据。
