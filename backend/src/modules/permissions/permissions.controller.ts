import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import type { ApiResponse } from '../../common/interfaces/api-response.interface';
import { ApiPermission } from '../auth/decorators/api-permission.decorator';
import {
  PermissionResponse,
  PermissionTreeNode,
  PermissionsService,
} from './permissions.service';

@ApiTags('permissions')
@Controller('permissions')
export class PermissionsController {
  constructor(private readonly permissionsService: PermissionsService) {}

  @Get()
  @ApiPermission('api:permissions:list')
  async list(): Promise<ApiResponse<PermissionResponse[]>> {
    return {
      code: 'PERMISSIONS_LIST_SUCCESS',
      message: 'permissions loaded',
      data: await this.permissionsService.list(),
    };
  }

  @Get('tree')
  @ApiPermission('api:permissions:list')
  async tree(): Promise<ApiResponse<PermissionTreeNode[]>> {
    return {
      code: 'PERMISSIONS_TREE_SUCCESS',
      message: 'permission tree loaded',
      data: await this.permissionsService.tree(),
    };
  }
}
