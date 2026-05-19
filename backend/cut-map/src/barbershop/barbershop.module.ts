import { Module } from '@nestjs/common';
import { BarbershopService } from './barbershop.service';
import { BarbershopController } from './barbershop.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Barbershop } from './entities/barbershop.entity';
import { User } from 'src/user/entities/user.entity';
import { BarbershopMember } from 'src/barbershop-member/entities/barbershop-member.entity';
import { UserModule } from 'src/user/user.module';
import { BarbershopMemberModule } from 'src/barbershop-member/barbershop-member.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Barbershop, User, BarbershopMember]),
    UserModule,
    BarbershopMemberModule,
  ],
  controllers: [BarbershopController],
  providers: [BarbershopService],
  exports: [BarbershopService],
})
export class BarbershopModule {}
