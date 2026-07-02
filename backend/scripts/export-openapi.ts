import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { createOpenApiDocument } from '../src/openapi';

const DEFAULT_DATABASE_URL =
  'postgresql://qsdms:qsdms@localhost:5432/qsdms_desktop?schema=public';
const DEFAULT_OUTPUT = '.generated/openapi.json';

async function main(): Promise<void> {
  // Prisma 7 初始化需要 DATABASE_URL；离线导出不会主动连接数据库。
  process.env.DATABASE_URL ??= DEFAULT_DATABASE_URL;

  const outputPath = resolve(
    process.cwd(),
    process.env.OPENAPI_OUTPUT ??
      process.env.APIFOX_OPENAPI_FILE ??
      DEFAULT_OUTPUT,
  );

  const app = await NestFactory.create(AppModule, { logger: false });
  app.setGlobalPrefix('api');
  await app.init();

  const document = createOpenApiDocument(app);

  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, `${JSON.stringify(document, null, 2)}\n`);
  await app.close();

  console.log(`OpenAPI exported to ${outputPath}`);
}

void main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
