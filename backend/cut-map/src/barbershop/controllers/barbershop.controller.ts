import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { BarbershopRolesGuard } from '../guards/barbershop-roles.guard';
import { CurrentUser } from 'src/auth/decorators/current-user.decorator';
import { CreateBarbershopDto } from '../dto/create-barbershop.dto';
import { BarbershopService } from '../services/barbershop.service';
import { BarbershopRole } from '../enums/barbershop-role.enum';
import { Roles } from '../decorators/roles.decorator';
import { UpdateBarbershopDto } from '../dto/update-barbershop.dto';

@Controller('barbershops')
@UseGuards(BarbershopRolesGuard)
export class BarbershopController {
  constructor(private readonly barbershopService: BarbershopService) {}

  @Post()
  create(
    @Body() createBarbershopDto: CreateBarbershopDto,
    @CurrentUser('sub') ownerId: string,
  ) {
    return this.barbershopService.create(createBarbershopDto, ownerId);
  }

  @Get('/me')
  findAllMe(@CurrentUser('sub') ownerId: string) {
    return this.barbershopService.findAllMe(ownerId);
  }

  @Get()
  findAll() {
    return this.barbershopService.findAll();
  }

  @Get('/me/:id')
  findOneMe(
    @Param('id') barberShopId: string,
    @CurrentUser('sub') ownerId: string,
  ) {
    return this.barbershopService.findOneMe(barberShopId, ownerId);
  }

  @Get(':id')
  findOne(@Param('id') barberShopId: string) {
    return this.barbershopService.findOne(barberShopId);
  }

  @Patch(':id')
  @Roles(BarbershopRole.OWNER, BarbershopRole.MANAGER)
  update(
    @Param('id') barbershopId: string,
    @CurrentUser('sub') userId: string,
    @Body() updateBarbershopDto: UpdateBarbershopDto,
  ) {
    return this.barbershopService.update(barbershopId, updateBarbershopDto);
  }

  @Delete(':id')
  @Roles(BarbershopRole.OWNER)
  remove(@Param('id') barbershopId: string) {
    return this.barbershopService.remove(barbershopId);
  }
}
