import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from 'src/user/entities/user.entity';
import { RefreshToken } from './entities/refresh-token.entity';
import { ConfigModule } from '@nestjs/config';
import jwtConfig from './config/jwt.config';
import { JwtModule } from '@nestjs/jwt';
import { Argon2Service } from './hashing/argon2.service';
import { HashingService } from './hashing/hashing.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { EmailModule } from 'src/email/email.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, RefreshToken]),
    ConfigModule.forFeature(jwtConfig),
    JwtModule.registerAsync(jwtConfig.asProvider()),
    EmailModule,
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    Argon2Service,
    JwtStrategy,
    {
      provide: HashingService,
      useClass: Argon2Service,
    },
  ],
  exports: [JwtModule, ConfigModule, HashingService],
})
export class AuthModule {}
