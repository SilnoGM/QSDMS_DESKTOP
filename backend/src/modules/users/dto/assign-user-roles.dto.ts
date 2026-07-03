import { Type } from 'class-transformer';
import { ArrayUnique, IsArray, IsInt } from 'class-validator';

export class AssignUserRolesDto {
  @IsArray()
  @ArrayUnique()
  @IsInt({ each: true })
  @Type(() => Number)
  roleIds!: number[];
}
