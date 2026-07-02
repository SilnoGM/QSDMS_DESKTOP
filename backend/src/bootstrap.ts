import { INestApplication, ValidationPipe } from '@nestjs/common';

import { setupOpenApi } from './openapi';

/// 统一配置 Nest 应用实例。
///
/// `main.ts` 和 e2e 测试共用该函数，确保全局前缀、参数校验和 OpenAPI 文档
/// 在运行时与测试环境保持一致。
export function configureApp(app: INestApplication): void {
  app.setGlobalPrefix('api');

  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );

  setupOpenApi(app);
}
