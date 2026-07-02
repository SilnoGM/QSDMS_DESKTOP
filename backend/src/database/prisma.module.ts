import { Global, Module } from '@nestjs/common';

import { PrismaService } from './prisma.service';

/// Prisma 全局模块。
///
/// 数据库访问能力统一从这里导出，业务模块不直接创建 PrismaClient，避免连接
/// 生命周期和事务边界分散在各处。
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
