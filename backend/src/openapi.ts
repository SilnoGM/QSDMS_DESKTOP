import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, OpenAPIObject, SwaggerModule } from '@nestjs/swagger';

export const OPENAPI_DOC_PATH = 'docs';
export const OPENAPI_JSON_PATH = 'docs-json';

/// 创建 QSDMS 后端 OpenAPI 文档。
///
/// Apifox 导入、Swagger UI 和离线导出脚本都必须共用这里的配置，避免接口
/// 文档来源分裂。这里保留全局前缀 `/api`，确保导出的路径与真实服务一致。
export function createOpenApiDocument(app: INestApplication): OpenAPIObject {
  const openApiConfig = new DocumentBuilder()
    .setTitle('QSDMS Backend API')
    .setDescription('QSDMS 企业数据管理系统后端 API')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();

  return SwaggerModule.createDocument(app, openApiConfig, {
    ignoreGlobalPrefix: false,
  });
}

/// 挂载 Swagger UI 和 OpenAPI JSON 端点。
///
/// 传入 `useGlobalPrefix` 后，最终访问地址为 `/api/docs` 和 `/api/docs-json`。
export function setupOpenApi(app: INestApplication): void {
  SwaggerModule.setup(OPENAPI_DOC_PATH, app, () => createOpenApiDocument(app), {
    jsonDocumentUrl: OPENAPI_JSON_PATH,
    useGlobalPrefix: true,
  });
}
