import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { BarbershopMember } from '../entities/barbershop-member.entity';
import { UserService } from 'src/user/user.service';
import { BarbershopRole } from '../enums/barbershop-role.enum';
import { BarbershopService } from './barbershop.service';
import { AddMemberDto } from '../dto/add-member.dto';

@Injectable()
export class BarbershopMemberService {
  constructor(
    @InjectRepository(BarbershopMember)
    private readonly barbershopMemberRepo: Repository<BarbershopMember>,
    private readonly userService: UserService,
    private readonly barbershopService: BarbershopService,
  ) {}

  async checkIfUserHasRole(
    barbershopId: string,
    userId: string,
    requiredRoles: BarbershopRole[],
  ): Promise<boolean> {
    const membership = await this.barbershopMemberRepo.findOne({
      where: {
        barbershop: { id: barbershopId },
        user: { id: userId },
        role: In(requiredRoles),
      },
    });

    return !!membership;
  }

  async addMemberToBarbershop(
    ownerId: string,
    barbershopId: string,
    dto: AddMemberDto,
  ) {
    await Promise.all([
      this.userService.findOne(dto.userId),
      this.barbershopService.findOne(barbershopId),
    ]);

    if (dto.userRole === BarbershopRole.OWNER) {
      const isOwner = await this.checkIfUserHasRole(barbershopId, ownerId, [
        BarbershopRole.OWNER,
      ]);
      if (!isOwner) {
        throw new UnauthorizedException(
          'Apenas o dono pode atribuir o papel de OWNER.',
        );
      }
    }

    const existingMembership = await this.barbershopMemberRepo.findOne({
      where: { barbershop: { id: barbershopId }, user: { id: dto.userId } },
    });

    if (existingMembership) {
      throw new ConflictException('Este usuário já é membro desta barbearia.');
    }

    const newMembership = this.barbershopMemberRepo.create({
      user: { id: dto.userId },
      barbershop: { id: barbershopId },
      role: dto.userRole,
    });
    await this.barbershopMemberRepo.save(newMembership);

    return {
      message: 'Membro adicionado com sucesso',
      membership: newMembership,
    };
  }

  async removeMemberFromBarbershop() {}
  async changeMemberRole() {}
  async listBarbershopMembers(userId: string, barbershopId: string) {
    const isMember = await this.checkIfUserHasRole(barbershopId, userId, [
      BarbershopRole.OWNER,
      BarbershopRole.MANAGER,
      BarbershopRole.EMPLOYEE,
    ]);

    if (!isMember) {
      throw new UnauthorizedException('Você não é membro desta barbearia.');
    }

    const members = await this.barbershopMemberRepo.find({
      where: { barbershop: { id: barbershopId } },
      relations: { user: true },
    });
    return { message: 'Membros encontrados com sucesso', members };
  }
}
