import { Test, TestingModule } from '@nestjs/testing';

import { AppModule } from './app.module';
import {
  createOpenApiDocument,
  OPENAPI_DOC_PATH,
  OPENAPI_JSON_PATH,
} from './openapi';

describe('OpenAPI', () => {
  it('should create a stable OpenAPI document for Apifox import', async () => {
    process.env.DATABASE_URL ??=
      'postgresql://qsdms_test:qsdms_test@localhost:5432/qsdms_test?schema=public';

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    const app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    await app.init();

    const document = createOpenApiDocument(app);

    expect(OPENAPI_DOC_PATH).toBe('docs');
    expect(OPENAPI_JSON_PATH).toBe('docs-json');
    expect(document.info.title).toBe('QSDMS Backend API');
    expect(document.paths['/api/health']).toBeDefined();

    await app.close();
  });
});
