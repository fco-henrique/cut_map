import { Module } from '@nestjs/common';
import { ReviewController } from './review.controller';
import { ReviewService } from './review.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Barbershop } from 'src/barbershop/entities/barbershop.entity';
import { Review } from './entities/review.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Review, Barbershop])],
  controllers: [ReviewController],
  providers: [ReviewService],
})
export class ReviewModule {}
