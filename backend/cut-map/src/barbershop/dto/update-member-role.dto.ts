import { IsEnum } from 'class-validator';
import { BarbershopRole } from '../enums/barbershop-role.enum';

export class UpdateMemberRoleDto {
  @IsEnum(BarbershopRole)
  role: BarbershopRole;
}
