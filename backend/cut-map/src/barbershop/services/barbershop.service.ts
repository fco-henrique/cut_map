import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { BarbershopMember } from 'src/barbershop/entities/barbershop-member.entity';
import { UserService } from 'src/user/user.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Barbershop } from '../entities/barbershop.entity';
import { CreateBarbershopDto } from '../dto/create-barbershop.dto';
import { BarbershopRole } from '../enums/barbershop-role.enum';
import { UpdateBarbershopDto } from '../dto/update-barbershop.dto';
import { GetBarbershopsFilterDto } from '../dto/get-barbershop-filters.dto';

@Injectable()
export class BarbershopService {
  constructor(
    @InjectRepository(Barbershop)
    private readonly barbershopRepo: Repository<Barbershop>,
    @InjectRepository(BarbershopMember)
    private readonly barbershopMemberRepo: Repository<BarbershopMember>,
    private readonly dataSource: DataSource,
    private readonly userService: UserService,
  ) {}

  async create(createBarbershopDto: CreateBarbershopDto, ownerId: string) {
    const owner = await this.userService.findOne(ownerId);

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const barbershop = queryRunner.manager.create(
        Barbershop,
        createBarbershopDto,
      );
      const savedBarbershop = await queryRunner.manager.save(barbershop);

      const membership = queryRunner.manager.create(BarbershopMember, {
        user: owner,
        barbershop: savedBarbershop,
        role: BarbershopRole.OWNER,
      });

      await queryRunner.manager.save(membership);
      await queryRunner.commitTransaction();

      return {
        message: 'Barbearia criada com sucesso',
        barbershop: savedBarbershop,
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async findAllMe(ownerId: string) {
    const barbershops = await this.barbershopRepo
      .createQueryBuilder('barbershop')
      .innerJoinAndSelect(
        'barbershop.members',
        'member',
        'member.user = :userId',
        { userId: ownerId },
      )
      .getMany();

    return { message: 'Busca realizada com sucesso', barbershops };
  }

  async findAll(filters: GetBarbershopsFilterDto) {
    const { sortBy, lat, lng, limit = 10 } = filters;

    const query = this.barbershopRepo.createQueryBuilder('barbershop');

    if (sortBy === 'distance') {
      const distanceExpr = `(6371 * acos(
      cos(radians(:lat)) * cos(radians(barbershop.address.latitude)) *
      cos(radians(barbershop.address.longitude) - radians(:lng)) +
      sin(radians(:lat)) * sin(radians(barbershop.address.latitude))
    ))`;

      query
        .addSelect(distanceExpr, 'distance')
        .setParameters({ lat, lng })
        .where(`${distanceExpr} <= :maxDistance`, { maxDistance: 5 })
        .orderBy('distance', 'ASC');
    } else if (sortBy === 'rating') {
      query.orderBy('barbershop.averageRating', 'DESC');
    } else {
      query.orderBy('barbershop.createdAt', 'DESC');
    }

    query.take(limit);

    if (sortBy === 'distance') {
      const { entities, raw } = await query.getRawAndEntities();
      const barbershops = entities.map((entity, index) => ({
        ...entity,
        distanceInKm: parseFloat(
          Number((raw[index] as Record<string, number>).distance).toFixed(2),
        ),
      }));
      return { message: 'Busca realizada com sucesso', barbershops };
    }

    const barbershops = await query.getMany();
    return { message: 'Busca realizada com sucesso', barbershops };
  }

  async findOneMe(barbershopId: string, ownerId: string) {
    const barbershop = await this.barbershopRepo.findOne({
      where: {
        id: barbershopId,
        members: { user: { id: ownerId } },
      },
      relations: { members: { user: true } },
    });

    if (!barbershop) {
      throw new NotFoundException('Barbearia não encontrada para este usuário');
    }

    return { message: 'Barbearia encontrada com sucesso', barbershop };
  }

  async findOne(barbershopId: string) {
    const barbershop = await this.barbershopRepo.findOne({
      where: { id: barbershopId },
      relations: { members: { user: true } },
    });

    if (!barbershop) {
      throw new NotFoundException('Barbearia não encontrada');
    }

    return { message: 'Barbearia encontrada com sucesso', barbershop };
  }

  async update(barbershopId: string, updateBarbershopDto: UpdateBarbershopDto) {
    const barbershop = await this.barbershopRepo.findOneBy({
      id: barbershopId,
    });

    if (!barbershop) {
      throw new NotFoundException('Barbearia não encontrada');
    }

    const updated = this.barbershopRepo.merge(barbershop, updateBarbershopDto);
    await this.barbershopRepo.save(updated);

    return {
      message: 'Barbearia atualizada com sucesso',
      barbershop: updated,
    };
  }

  async remove(barbershopId: string) {
    const barbershop = await this.barbershopRepo.findOneBy({
      id: barbershopId,
    });

    if (!barbershop) {
      throw new NotFoundException('Barbearia não encontrada');
    }

    await this.barbershopRepo.remove(barbershop);

    return { message: 'Barbearia removida com sucesso' };
  }
}
