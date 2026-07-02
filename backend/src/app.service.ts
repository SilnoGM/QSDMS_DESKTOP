import { Injectable } from '@nestjs/common';

import { ApiResponse } from './common/interfaces/api-response.interface';

type HealthData = {
  service: string;
  database: string;
};

@Injectable()
export class AppService {
  /// 返回服务健康检查元数据。
  ///
  /// 这里不主动探测数据库连接，避免基础健康检查依赖外部 PostgreSQL 是否启动；
  /// 后续可以增加 `/api/health/deep` 做数据库、Redis 等深度探测。
  getHealth(): ApiResponse<HealthData> {
    return {
      code: 'OK',
      message: 'service healthy',
      data: {
        service: 'qsdms-backend',
        database: 'postgresql',
      },
    };
  }
}
