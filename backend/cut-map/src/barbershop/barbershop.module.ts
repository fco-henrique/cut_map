import { Module } from '@nestjs/common';
import { BarbershopService } from './barbershop.service';
import { BarbershopController } from './barbershop.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Barbershop } from './entities/barbershop.entity';
import { User } from 'src/user/entities/user.entity';
import { BarbershopMember } from 'src/barbershop-member/entities/barbershop-member.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Barbershop, User, BarbershopMember])],
  controllers: [BarbershopController],
  providers: [BarbershopService],
  exports: [BarbershopService],
})
export class BarbershopModule {}
