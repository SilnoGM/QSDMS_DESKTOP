import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';

import { AppModule } from '../../app.module';
import { configureApp } from '../../bootstrap';

describe('AuthModule global guard integration', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    process.env.DATABASE_URL ??=
      'postgresql://qsdms_test:qsdms_test@localhost:5432/qsdms_test?schema=public';
    delete process.env.JWT_ACCESS_TOKEN_SECRET;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterEach(async () => {
    await app?.close();
  });

  it('/api/health 在全局 JwtAuthGuard 下仍 public', async () => {
    await request(app.getHttpServer()).get('/api/health').expect(200).expect({
      code: 'OK',
      message: 'service healthy',
      data: {
        service: 'qsdms-backend',
        database: 'postgresql',
      },
    });
  });
});
