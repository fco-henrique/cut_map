import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import {
  BarbershopMember,
  BarbershopRole,
} from '../entities/barbershop-member.entity';
import { UserService } from 'src/user/user.service';
import { BarbershopService } from 'src/barbershop/barbershop.service';

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
    userId: string,
    userRole: BarbershopRole,
  ) {
    await Promise.all([
      this.userService.findOne(userId),
      this.barbershopService.findOne(barbershopId),
    ]);

    if (userRole === BarbershopRole.OWNER) {
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
      where: { barbershop: { id: barbershopId }, user: { id: userId } },
    });

    if (existingMembership) {
      throw new ConflictException('Este usuário já é membro desta barbearia.');
    }

    const newMembership = this.barbershopMemberRepo.create({
      user: { id: userId },
      barbershop: { id: barbershopId },
      role: userRole,
    });
    await this.barbershopMemberRepo.save(newMembership);

    return {
      message: 'Membro adicionado com sucesso',
      membership: newMembership,
    };
  }
  async removeMemberFromBarbershop() {}
  async changeMemberRole() {}
  async listBarbershopMembers() {}
}
