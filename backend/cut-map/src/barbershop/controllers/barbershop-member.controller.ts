import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { BarbershopMemberService } from '../services/barbershop-member.service';
import { CurrentUser } from 'src/auth/decorators/current-user.decorator';
import { BarbershopRole } from '../enums/barbershop-role.enum';
import { Roles } from '../decorators/roles.decorator';
import { AddMemberDto } from '../dto/add-member.dto';

@Controller('barbershops/:barbershopId/members')
export class BarbershopMemberController {
  constructor(
    private readonly barbershopMemberService: BarbershopMemberService,
  ) {}

  @Post()
  @Roles(BarbershopRole.OWNER, BarbershopRole.MANAGER)
  addMember(
    @CurrentUser('sub') ownerId: string,
    @Param('barbershopId') barbershopId: string,
    @Body() dto: AddMemberDto,
  ) {
    return this.barbershopMemberService.addMemberToBarbershop(
      ownerId,
      barbershopId,
      dto,
    );
  }

  @Get()
  listMembers(
    @CurrentUser('sub') userId: string,
    @Param('barbershopId') barbershopId: string,
  ) {
    return this.barbershopMemberService.listBarbershopMembers(
      userId,
      barbershopId,
    );
  }
}
