import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import type { ApiResponse } from '../../common/interfaces/api-response.interface';
import { ApiPermission } from '../auth/decorators/api-permission.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthMenu } from '../auth/models/auth-session.model';
import type { CurrentUserPayload } from '../auth/models/current-user.model';
import { MenusService } from './menus.service';

@ApiTags('menus')
@Controller('menus')
export class MenusController {
  constructor(private readonly menusService: MenusService) {}

  @Get('me')
  @ApiPermission('api:menus:me')
  async me(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<AuthMenu[]>> {
    return {
      code: 'MENUS_ME_SUCCESS',
      message: 'menus loaded',
      data: await this.menusService.getMyMenus(currentUser),
    };
  }
}
