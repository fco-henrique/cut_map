import { Controller, Post } from '@nestjs/common';
import { BarbershopMemberService } from '../services/barbershop-member.service';
import { CurrentUser } from 'src/auth/decorators/current-user.decorator';
import { BarbershopRole } from '../enums/barbershop-role.enum';
import { Roles } from '../decorators/roles.decorator';

@Controller('barbershop-member')
export class BarbershopMemberController {
  constructor(
    private readonly barbershopMemberService: BarbershopMemberService,
  ) {}

  @Post('add-member')
  @Roles(BarbershopRole.OWNER, BarbershopRole.MANAGER)
  addMember(
    @CurrentUser('sub') ownerId: string,
    barbershopId: string,
    userId: string,
    userRole: BarbershopRole,
  ) {
    return this.barbershopMemberService.addMemberToBarbershop(
      ownerId,
      barbershopId,
      userId,
      userRole,
    );
  }
}
