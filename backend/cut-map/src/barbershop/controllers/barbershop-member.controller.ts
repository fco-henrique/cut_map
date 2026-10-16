import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { BarbershopMemberService } from '../services/barbershop-member.service';
import { CurrentUser } from 'src/auth/decorators/current-user.decorator';
import { BarbershopRole } from '../enums/barbershop-role.enum';
import { Roles } from '../decorators/roles.decorator';
import { BarbershopRolesGuard } from '../guards/barbershop-roles.guard';
import { AddMemberDto } from '../dto/add-member.dto';
import { UpdateMemberRoleDto } from '../dto/update-member-role.dto';
import { SearchUserDto } from 'src/user/dto/search-user.dto';

@Controller('barbershops/:barbershopId/members')
@UseGuards(BarbershopRolesGuard)
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

  @Get('search')
  @Roles(BarbershopRole.OWNER, BarbershopRole.MANAGER)
  searchUsersToAdd(
    @Param('barbershopId') barbershopId: string,
    @Query() query: SearchUserDto,
  ) {
    return this.barbershopMemberService.searchUsersToAdd(
      barbershopId,
      query.name,
      query.limit,
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

  @Delete(':userId')
  @Roles(BarbershopRole.OWNER, BarbershopRole.MANAGER)
  removeMember(
    @CurrentUser('sub') adminId: string,
    @Param('barbershopId') barbershopId: string,
    @Param('userId') userId: string,
  ) {
    return this.barbershopMemberService.removeMemberFromBarbershop(
      adminId,
      barbershopId,
      userId,
    );
  }

  @Patch(':userId/role')
  @Roles(BarbershopRole.OWNER, BarbershopRole.MANAGER)
  changeRole(
    @CurrentUser('sub') adminId: string,
    @Param('id') barbershopId: string,
    @Param('userId') userId: string,
    @Body() dto: UpdateMemberRoleDto,
  ) {
    return this.barbershopMemberService.changeMemberRole(
      adminId,
      barbershopId,
      userId,
      dto.role,
    );
  }
}
