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

  async removeMemberFromBarbershop(
    adminId: string,
    barbershopId: string,
    userId: string,
  ) {
    await this.barbershopService.findOne(barbershopId);

    const adminMembership = await this.getMembership(barbershopId, adminId);
    if (!adminMembership) {
      throw new UnauthorizedException(
        'Você não tem vínculo com esta barbearia.',
      );
    }

    const targetMembership = await this.getMembership(barbershopId, userId);
    if (!targetMembership) {
      throw new ConflictException('Este usuário não é membro desta barbearia.');
    }

    if (targetMembership.role === BarbershopRole.OWNER) {
      throw new ConflictException(
        'Não é possível remover o dono da barbearia.',
      );
    }

    if (
      targetMembership.role === BarbershopRole.MANAGER &&
      adminMembership.role !== BarbershopRole.OWNER
    ) {
      throw new UnauthorizedException('Apenas o dono pode remover gerentes.');
    }

    await this.barbershopMemberRepo.remove(targetMembership);
    return { message: 'Membro removido com sucesso' };
  }

  async leaveBarbershop(userId: string, barbershopId: string) {
    const membership = await this.getMembership(barbershopId, userId);

    if (!membership) {
      throw new ConflictException('Você não é membro desta barbearia.');
    }

    if (membership.role === BarbershopRole.OWNER) {
      throw new ConflictException(
        'Você é o dono desta barbearia. Transfira a propriedade para outro membro antes de sair.',
      );
    }

    await this.barbershopMemberRepo.remove(membership);
    return { message: 'Você saiu da barbearia com sucesso' };
  }

  private async getMembership(barbershopId: string, userId: string) {
    return this.barbershopMemberRepo.findOne({
      where: { barbershop: { id: barbershopId }, user: { id: userId } },
    });
  }

  async changeMemberRole(
    adminId: string,
    barbershopId: string,
    userId: string,
    newRole: BarbershopRole,
  ) {
    await this.barbershopService.findOne(barbershopId);

    const adminMembership = await this.getMembership(barbershopId, adminId);
    if (!adminMembership) {
      throw new UnauthorizedException(
        'Você não tem vínculo com esta barbearia.',
      );
    }

    const targetMembership = await this.getMembership(barbershopId, userId);
    if (!targetMembership) {
      throw new ConflictException('Este usuário não é membro desta barbearia.');
    }

    if (targetMembership.role === BarbershopRole.OWNER) {
      throw new ConflictException(
        'Não é possível alterar o cargo do dono. Use a transferência de propriedade.',
      );
    }

    if (targetMembership.role === newRole) {
      throw new ConflictException(
        `Este usuário já possui o cargo de ${newRole}.`,
      );
    }

    if (newRole === BarbershopRole.OWNER) {
      throw new ConflictException(
        'Para transferir a propriedade, use a rota de transferência de dono.',
      );
    }

    if (
      targetMembership.role === BarbershopRole.MANAGER &&
      adminMembership.role !== BarbershopRole.OWNER
    ) {
      throw new UnauthorizedException(
        'Apenas o dono pode alterar o cargo de um gerente.',
      );
    }

    if (
      newRole === BarbershopRole.MANAGER &&
      adminMembership.role !== BarbershopRole.OWNER
    ) {
      throw new UnauthorizedException(
        'Apenas o dono pode promover alguém a gerente.',
      );
    }

    targetMembership.role = newRole;
    await this.barbershopMemberRepo.save(targetMembership);

    return {
      message: 'Cargo atualizado com sucesso',
      membership: targetMembership,
    };
  }

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
