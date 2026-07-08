import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Request } from 'express';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { BarbershopMemberService } from '../../barbershop/services/barbershop-member.service';
import { BarbershopRole } from '../enums/barbershop-role.enum';

interface RequestWithUser extends Request {
  user?: {
    sub: string;
  };
}

@Injectable()
export class BarbershopRolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private membersService: BarbershopMemberService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<BarbershopRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles) {
      return true;
    }

    const request = context.switchToHttp().getRequest<RequestWithUser>();

    const user = request.user;

    const barbershopId = request.params.id as string;

    if (!user || !barbershopId) {
      throw new ForbiddenException('Acesso negado.');
    }

    const hasPermission = await this.membersService.checkIfUserHasRole(
      barbershopId,
      user.sub,
      requiredRoles,
    );

    if (!hasPermission) {
      throw new ForbiddenException(
        'Você não tem permissão para realizar esta ação nesta barbearia.',
      );
    }

    return true;
  }
}
