import { SetMetadata } from '@nestjs/common';
import { BarbershopRole } from '../../barbershop/entities/barbershop-member.entity';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: BarbershopRole[]) =>
  SetMetadata(ROLES_KEY, roles);
