import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
} from '@nestjs/common';
import { ReviewService } from './review.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { CurrentUser } from 'src/auth/decorators/current-user.decorator';

@Controller('barbershops/:barbershopId/review')
export class ReviewController {
  constructor(private readonly reviewsService: ReviewService) {}

  @Post()
  create(
    @Param('barbershopId') barbershopId: string,
    @Body() createReviewDto: CreateReviewDto,
    @CurrentUser('sub') userId: string,
  ) {
    return this.reviewsService.createReview(
      userId,
      barbershopId,
      createReviewDto,
    );
  }

  @Get()
  findAll(
    @Param('barbershopId') barbershopId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    return this.reviewsService.findAllByBarbershop(barbershopId, page, limit);
  }
}
