import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { In, Repository } from 'typeorm';
import { UserService } from 'src/user/user.service';
import { BarbershopMemberController } from '../controllers/barbershop-member.controller';
import { BarbershopMember } from '../entities/barbershop-member.entity';
import { BarbershopRole } from '../enums/barbershop-role.enum';
import { BarbershopRolesGuard } from '../guards/barbershop-roles.guard';
import { BarbershopMemberService } from './barbershop-member.service';
import { BarbershopService } from './barbershop.service';

describe('BarbershopMemberService', () => {
  const repo = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };
  const users = { findOne: jest.fn(), searchByName: jest.fn() };
  const shops = { findOne: jest.fn() };
  const service = new BarbershopMemberService(
    repo as unknown as Repository<BarbershopMember>,
    users as unknown as UserService,
    shops as unknown as BarbershopService,
  );
  const guard = new BarbershopRolesGuard(new Reflector(), service);
  const user = {
    id: 'member-id',
    name: 'Profissional',
    email: 'member@example.com',
    passwordHash: 'test-hash',
    emailVerificationCode: 'test-code',
  };
  const membership = {
    id: 'membership-id',
    role: BarbershopRole.EMPLOYEE,
    user,
  };
  const projectedMember = {
    id: membership.id,
    role: membership.role,
    user: { id: user.id, name: user.name },
  };

  beforeEach(() => jest.resetAllMocks());

  it('lista membros da loja autorizada somente com identidade pública', async () => {
    repo.findOne.mockResolvedValue(membership);
    repo.find.mockResolvedValue([membership]);

    await expect(
      service.listBarbershopMembers(user.id, 'shop-id'),
    ).resolves.toEqual({
      message: 'Membros encontrados com sucesso',
      members: [projectedMember],
    });
    expect(repo.findOne).toHaveBeenCalledWith({
      where: {
        barbershop: { id: 'shop-id' },
        user: { id: user.id },
        role: In([
          BarbershopRole.OWNER,
          BarbershopRole.MANAGER,
          BarbershopRole.EMPLOYEE,
        ]),
      },
    });
    expect(repo.find).toHaveBeenCalledWith({
      where: { barbershop: { id: 'shop-id' } },
      relations: { user: true },
      select: { user: { id: true, name: true } },
    });
  });

  it('rejeita a lista sem vínculo na loja solicitada', async () => {
    repo.findOne.mockResolvedValue(null);

    await expect(
      service.listBarbershopMembers(user.id, 'other-shop'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(repo.find).not.toHaveBeenCalled();
  });

  it('exclui membros atuais da busca contextual e projeta os candidatos', async () => {
    users.searchByName.mockResolvedValue([
      user,
      { ...user, id: 'candidate-id' },
    ]);
    repo.find.mockResolvedValue([membership]);

    await expect(
      service.searchUsersToAdd('shop-id', 'Pro', 10),
    ).resolves.toEqual([{ id: 'candidate-id', name: user.name }]);
    expect(repo.find).toHaveBeenCalledWith({
      where: { barbershop: { id: 'shop-id' } },
      relations: { user: true },
      select: { user: { id: true } },
    });
    expect(users.searchByName).toHaveBeenCalledWith('Pro', 10);
  });

  it.each([
    'searchUsersToAdd',
    'addMember',
    'changeRole',
    'removeMember',
  ] as const)(
    'exige papel de gestão na própria loja para %s',
    async handler => {
      const controller = BarbershopMemberController.prototype;
      const context = (barbershopId: string) =>
        ({
          getClass: () => BarbershopMemberController,
          getHandler: () => controller[handler],
          switchToHttp: () => ({
            getRequest: () => ({
              params: { barbershopId },
              user: { sub: 'manager-id' },
            }),
          }),
        }) as unknown as ExecutionContext;
      repo.findOne.mockResolvedValueOnce({ role: BarbershopRole.MANAGER });
      repo.findOne.mockResolvedValueOnce(null);

      await expect(guard.canActivate(context('managed-shop'))).resolves.toBe(
        true,
      );
      await expect(
        guard.canActivate(context('other-shop')),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(repo.findOne).toHaveBeenLastCalledWith({
        where: {
          barbershop: { id: 'other-shop' },
          user: { id: 'manager-id' },
          role: In([BarbershopRole.OWNER, BarbershopRole.MANAGER]),
        },
      });
    },
  );

  it('preserva a referência por ID e a projeção segura ao adicionar membro', async () => {
    repo.findOne.mockResolvedValue(null);
    repo.create.mockReturnValue({
      ...membership,
      user: { id: user.id, email: user.email },
      barbershop: { id: 'shop-id', members: [membership] },
    });

    await expect(
      service.addMemberToBarbershop('owner-id', 'shop-id', {
        userId: user.id,
        userRole: BarbershopRole.EMPLOYEE,
      }),
    ).resolves.toEqual({
      message: 'Membro adicionado com sucesso',
      membership: {
        id: membership.id,
        role: membership.role,
        user: { id: user.id },
        barbershop: { id: 'shop-id' },
      },
    });
  });

  it('projeta os dados da troca de papel mesmo com usuário carregado', async () => {
    repo.findOne.mockResolvedValueOnce({ role: BarbershopRole.OWNER });
    repo.findOne.mockResolvedValueOnce({ ...membership });

    await expect(
      service.changeMemberRole(
        'owner-id',
        'shop-id',
        user.id,
        BarbershopRole.MANAGER,
      ),
    ).resolves.toEqual({
      message: 'Cargo atualizado com sucesso',
      membership: { ...projectedMember, role: BarbershopRole.MANAGER },
    });
  });
});
