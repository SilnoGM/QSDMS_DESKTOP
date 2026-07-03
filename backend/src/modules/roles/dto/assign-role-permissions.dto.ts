import { Type } from 'class-transformer';
import { ArrayUnique, IsArray, IsInt } from 'class-validator';

export class AssignRolePermissionsDto {
  @IsArray()
  @ArrayUnique()
  @IsInt({ each: true })
  @Type(() => Number)
  permissionIds!: number[];
}
