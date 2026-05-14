import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
} from '@nestjs/common';
import { BarbershopService } from './barbershop.service';
import { CreateBarbershopDto } from './dto/create-barbershop.dto';
import { UpdateBarbershopDto } from './dto/update-barbershop.dto';
import { CurrentUser } from 'src/auth/decorators/current-user.decorator';

@Controller('barbershop')
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

  @Get(':id')
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
  update(
    @Param('id') barberShopId: string,
    @CurrentUser('sub') userId: string,
    @Body() updateBarbershopDto: UpdateBarbershopDto,
  ) {
    return this.barbershopService.update(
      barberShopId,
      userId,
      updateBarbershopDto,
    );
  }

  @Delete(':id')
  remove(
    @Param('id') barberShopId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.barbershopService.remove(barberShopId, userId);
  }
}
