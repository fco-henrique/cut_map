import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BarbershopMember } from './entities/barbershop-member.entity';

@Module({
  imports: [TypeOrmModule.forFeature([BarbershopMember])],
  controllers: [],
  providers: [],
})
export class BarbershopMemberModule {}
