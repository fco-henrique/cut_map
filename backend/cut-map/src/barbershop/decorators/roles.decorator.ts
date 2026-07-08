import { SetMetadata } from '@nestjs/common';
import { BarbershopRole } from '../enums/barbershop-role.enum';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: BarbershopRole[]) =>
  SetMetadata(ROLES_KEY, roles);
