import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BarbershopMember } from './entities/barbershop-member.entity';
import { BarbershopMemberService } from './barbershop-member.service';
import { BarbershopMemberController } from './barbershop-member.controller';

@Module({
  imports: [TypeOrmModule.forFeature([BarbershopMember])],
  controllers: [BarbershopMemberController],
  providers: [BarbershopMemberService],
  exports: [BarbershopMemberService],
})
export class BarbershopMemberModule {}
