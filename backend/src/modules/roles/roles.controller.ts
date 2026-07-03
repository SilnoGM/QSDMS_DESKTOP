import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import type { ApiResponse } from '../../common/interfaces/api-response.interface';
import { ApiPermission } from '../auth/decorators/api-permission.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserPayload } from '../auth/models/current-user.model';
import { AssignRolePermissionsDto } from './dto/assign-role-permissions.dto';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { RoleResponse, RolesService } from './roles.service';

@ApiTags('roles')
@Controller('roles')
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Get()
  @ApiPermission('api:roles:list')
  async list(): Promise<ApiResponse<RoleResponse[]>> {
    return {
      code: 'ROLES_LIST_SUCCESS',
      message: 'roles loaded',
      data: await this.rolesService.list(),
    };
  }

  @Post()
  @ApiPermission('api:roles:create')
  async create(
    @Body() dto: CreateRoleDto,
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<RoleResponse>> {
    return {
      code: 'ROLE_CREATE_SUCCESS',
      message: 'role created',
      data: await this.rolesService.create(dto, currentUser),
    };
  }

  @Patch(':id')
  @ApiPermission('api:roles:update')
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateRoleDto,
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<RoleResponse>> {
    return {
      code: 'ROLE_UPDATE_SUCCESS',
      message: 'role updated',
      data: await this.rolesService.update(id, dto, currentUser),
    };
  }

  @Put(':id/permissions')
  @ApiPermission('api:roles:assign-permissions')
  async assignPermissions(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: AssignRolePermissionsDto,
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<RoleResponse>> {
    return {
      code: 'ROLE_ASSIGN_PERMISSIONS_SUCCESS',
      message: 'role permissions assigned',
      data: await this.rolesService.assignPermissions(id, dto, currentUser),
    };
  }
}
