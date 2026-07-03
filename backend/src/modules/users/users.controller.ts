import { Body, Controller, Get, Param, Patch, Post, Put } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import type { ApiResponse } from '../../common/interfaces/api-response.interface';
import { ApiPermission } from '../auth/decorators/api-permission.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserPayload } from '../auth/models/current-user.model';
import { AssignUserRolesDto } from './dto/assign-user-roles.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { ResetUserPasswordDto } from './dto/reset-user-password.dto';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import {
  ResetPasswordResponse,
  UserResponse,
  UsersService,
} from './users.service';

@ApiTags('users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiPermission('api:users:list')
  async list(): Promise<ApiResponse<UserResponse[]>> {
    return {
      code: 'USERS_LIST_SUCCESS',
      message: 'users loaded',
      data: await this.usersService.list(),
    };
  }

  @Post()
  @ApiPermission('api:users:create')
  async create(
    @Body() dto: CreateUserDto,
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<UserResponse>> {
    return {
      code: 'USER_CREATE_SUCCESS',
      message: 'user created',
      data: await this.usersService.create(dto, currentUser),
    };
  }

  @Get(':id')
  @ApiPermission('api:users:detail')
  async detail(@Param('id') id: string): Promise<ApiResponse<UserResponse>> {
    return {
      code: 'USER_DETAIL_SUCCESS',
      message: 'user loaded',
      data: await this.usersService.detail(id),
    };
  }

  @Patch(':id')
  @ApiPermission('api:users:update')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateUserDto,
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<UserResponse>> {
    return {
      code: 'USER_UPDATE_SUCCESS',
      message: 'user updated',
      data: await this.usersService.update(id, dto, currentUser),
    };
  }

  @Patch(':id/status')
  @ApiPermission('api:users:update-status')
  async updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateUserStatusDto,
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<UserResponse>> {
    return {
      code: 'USER_STATUS_UPDATE_SUCCESS',
      message: 'user status updated',
      data: await this.usersService.updateStatus(id, dto, currentUser),
    };
  }

  @Post(':id/reset-password')
  @ApiPermission('api:users:reset-password')
  async resetPassword(
    @Param('id') id: string,
    @Body() dto: ResetUserPasswordDto,
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<ResetPasswordResponse>> {
    return {
      code: 'USER_RESET_PASSWORD_SUCCESS',
      message: 'password reset',
      data: await this.usersService.resetPassword(id, dto, currentUser),
    };
  }

  @Put(':id/roles')
  @ApiPermission('api:users:assign-roles')
  async assignRoles(
    @Param('id') id: string,
    @Body() dto: AssignUserRolesDto,
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<UserResponse>> {
    return {
      code: 'USER_ASSIGN_ROLES_SUCCESS',
      message: 'user roles assigned',
      data: await this.usersService.assignRoles(id, dto, currentUser),
    };
  }
}
