import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Review } from './entities/review.entity';
import { Repository } from 'typeorm';
import { Barbershop } from 'src/barbershop/entities/barbershop.entity';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepo: Repository<Review>,
    @InjectRepository(Barbershop)
    private readonly barbershopRepo: Repository<Barbershop>,
  ) {}

  async createReview(
    userId: string,
    barbershopId: string,
    dto: CreateReviewDto,
  ) {
    const barbershop = await this.barbershopRepo.findOne({
      where: { id: barbershopId },
    });

    if (!barbershop) {
      throw new NotFoundException('Barbearia não encontrada.');
    }

    const review = this.reviewRepo.create({
      ...dto,
      user: { id: userId },
      barbershop: { id: barbershopId },
    });
    await this.reviewRepo.save(review);

    await this.updateBarbershopMetrics(barbershopId);

    return {
      message: 'Avaliação criada com sucesso.',
      review,
    };
  }

  async findAllByBarbershop(
    barbershopId: string,
    page: number = 1,
    limit: number = 10,
  ) {
    const [reviews, total] = await this.reviewRepo.findAndCount({
      where: { barbershop: { id: barbershopId } },
      relations: ['user'],
      select: {
        user: { id: true, name: true },
      },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return {
      data: reviews,
      meta: {
        total,
        page,
        lastPage: Math.ceil(total / limit),
      },
    };
  }

  private async updateBarbershopMetrics(barbershopId: string) {
    const metrics = await this.reviewRepo
      .createQueryBuilder('review')
      .select('AVG(review.score)', 'avg')
      .addSelect('COUNT(review.id)', 'count')
      .where('review.barbershopId = :barbershopId', { barbershopId })
      .getRawOne<{ avg: string | null; count: string | null }>();

    await this.barbershopRepo.update(barbershopId, {
      averageRating: metrics?.avg
        ? parseFloat(Number(metrics.avg).toFixed(2))
        : 0,
      totalReviews: metrics?.count ? parseInt(metrics.count, 10) : 0,
    });
  }
}
