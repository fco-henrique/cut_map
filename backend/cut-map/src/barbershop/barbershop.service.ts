import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { CreateBarbershopDto } from './dto/create-barbershop.dto';
import { UpdateBarbershopDto } from './dto/update-barbershop.dto';
import { User } from 'src/user/entities/user.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Barbershop } from './entities/barbershop.entity';
import { In, Repository } from 'typeorm';
import {
  BarbershopMember,
  BarbershopRole,
} from 'src/barbershop-member/entities/barbershop-member.entity';

@Injectable()
export class BarbershopService {
  constructor(
    @InjectRepository(Barbershop)
    private barbershopRepo: Repository<Barbershop>,
    @InjectRepository(BarbershopMember)
    private barbershopMemberRepo: Repository<BarbershopMember>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async create(createBarbershopDto: CreateBarbershopDto, ownerId: string) {
    const owner = await this.userRepo.findOneBy({
      id: ownerId,
    });

    if (!owner) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    const barbershop = await this.barbershopRepo.save({
      ...createBarbershopDto,
    });

    const mermbership = this.barbershopMemberRepo.create({
      user: owner,
      barbershop: barbershop,
      role: BarbershopRole.OWNER,
    });

    await this.barbershopMemberRepo.save(mermbership);

    return { message: 'Barbearia criada com sucesso', barbershop };
  }

  async findAllMe(ownerId: string) {
    const barbershops = await this.barbershopRepo.find({
      where: { members: { user: { id: ownerId } } },
    });

    if (!barbershops) {
      throw new NotFoundException(
        'Barbearias não encontradas para este usuário',
      );
    }

    return { message: 'Barbearias encontradas com sucesso', barbershops };
  }

  async findAll() {
    const barbershops = await this.barbershopRepo.find();

    if (!barbershops) {
      throw new NotFoundException('Barbearias não encontradas');
    }

    return { message: 'Barbearias encontradas com sucesso', barbershops };
  }

  async findOneMe(barberShopId: string, ownerId: string) {
    const barbershop = await this.barbershopRepo.findOne({
      where: {
        id: barberShopId,
        members: {
          user: { id: ownerId },
        },
      },
    });

    if (!barbershop) {
      throw new NotFoundException('Barbearia não encontrada para este usuário');
    }

    return { message: 'Barbearia encontrada com sucesso', barbershop };
  }

  async findOne(barberShopId: string) {
    const barbershop = await this.barbershopRepo.findOne({
      where: {
        id: barberShopId,
      },
    });

    if (!barbershop) {
      throw new NotFoundException('Barbearia não encontrada');
    }

    return { message: 'Barbearia encontrada com sucesso', barbershop };
  }

  async update(
    barberShopId: string,
    userId: string,
    updateBarbershopDto: UpdateBarbershopDto,
  ) {
    const membership = await this.barbershopMemberRepo.findOne({
      where: {
        barbershop: { id: barberShopId },
        user: { id: userId },
        role: In([BarbershopRole.OWNER, BarbershopRole.MANAGER]),
      },
      relations: ['barbershop'],
    });

    if (!membership) {
      throw new UnauthorizedException(
        'Barbearia não encontrada ou você não tem permissão para editá-la',
      );
    }

    Object.assign(membership.barbershop, updateBarbershopDto);

    await this.barbershopRepo.save(membership.barbershop);

    return {
      message: 'Barbearia atualizada com sucesso',
      barbershop: membership.barbershop,
    };
  }

  async remove(barberShopId: string, userId: string) {
    const membership = await this.barbershopMemberRepo.findOne({
      where: {
        barbershop: { id: barberShopId },
        user: { id: userId },
        role: In([BarbershopRole.OWNER, BarbershopRole.MANAGER]),
      },
      relations: ['barbershop'],
    });

    if (!membership) {
      throw new UnauthorizedException(
        'Barbearia não encontrada ou você não tem permissão para removê-la',
      );
    }

    const result = await this.barbershopRepo.delete({ id: barberShopId });

    return {
      message: 'Barbearia removida com sucesso',
      result,
    };
  }
}
