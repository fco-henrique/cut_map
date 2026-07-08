import { IsEnum, IsString } from 'class-validator';
import { BarbershopRole } from '../enums/barbershop-role.enum';

export class AddMemberDto {
  @IsString()
  userId: string;

  @IsEnum(BarbershopRole)
  userRole: BarbershopRole;
}
