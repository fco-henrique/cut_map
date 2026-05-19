import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import {
  BarbershopMember,
  BarbershopRole,
} from './entities/barbershop-member.entity';

@Injectable()
export class BarbershopMemberService {
  constructor(
    @InjectRepository(BarbershopMember)
    private readonly barbershopMemberRepo: Repository<BarbershopMember>,
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

  async addMemberToBarbershop() {}
  async removeMemberFromBarbershop() {}
  async changeMemberRole() {}
  async listBarbershopMembers() {}
}
