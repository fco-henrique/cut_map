import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Barbershop } from './entities/barbershop.entity';
import { User } from 'src/user/entities/user.entity';
import { BarbershopMember } from 'src/barbershop/entities/barbershop-member.entity';
import { UserModule } from 'src/user/user.module';
import { BarbershopController } from './controllers/barbershop.controller';
import { BarbershopMemberController } from './controllers/barbershop-member.controller';
import { BarbershopService } from './services/barbershop.service';
import { BarbershopMemberService } from './services/barbershop-member.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Barbershop, User, BarbershopMember]),
    UserModule,
  ],
  controllers: [BarbershopController, BarbershopMemberController],
  providers: [BarbershopService, BarbershopMemberService],
  exports: [BarbershopService, BarbershopMemberService],
})
export class BarbershopModule {}
