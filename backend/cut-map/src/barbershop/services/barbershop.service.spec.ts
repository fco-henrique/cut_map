import { NotFoundException } from '@nestjs/common';
import { DataSource, In, Repository } from 'typeorm';
import { UserService } from 'src/user/user.service';
import { BarbershopMember } from '../entities/barbershop-member.entity';
import { Barbershop } from '../entities/barbershop.entity';
import { BarbershopRole } from '../enums/barbershop-role.enum';
import { BarbershopService } from './barbershop.service';

describe('BarbershopService', () => {
  const repo = {
    findOne: jest.fn(),
    findOneBy: jest.fn(),
    merge: jest.fn(),
    save: jest.fn(),
  };
  const memberRepo = { find: jest.fn() };
  const service = new BarbershopService(
    repo as unknown as Repository<Barbershop>,
    memberRepo as unknown as Repository<BarbershopMember>,
    {} as DataSource,
    {} as UserService,
  );
  const barbershop = {
    id: 'shop-id',
    name: 'Barbearia',
    address: { cidade: 'Recife' },
    averageRating: '4.50',
    totalReviews: 2,
    createdAt: new Date(),
    members: [
      {
        id: 'membership-id',
        role: BarbershopRole.OWNER,
        user: {
          id: 'owner-id',
          name: 'Titular',
          email: 'owner@example.com',
          passwordHash: 'test-hash',
          resetPasswordCode: 'test-code',
        },
      },
    ],
  };
  const expected = {
    id: barbershop.id,
    name: barbershop.name,
    address: barbershop.address,
    averageRating: barbershop.averageRating,
    totalReviews: barbershop.totalReviews,
    members: [
      {
        id: 'membership-id',
        role: BarbershopRole.OWNER,
        user: { id: 'owner-id', name: 'Titular' },
      },
    ],
  };

  beforeEach(() => jest.resetAllMocks());

  it.each(['owner-id', 'manager-id'])(
    'projeta a lista no detalhe para o administrador local %s',
    async userId => {
      repo.findOneBy.mockResolvedValue(barbershop);
      memberRepo.find.mockResolvedValue(barbershop.members);

      await expect(service.findOne('shop-id', userId)).resolves.toEqual({
        message: 'Barbearia encontrada com sucesso',
        barbershop: expected,
      });
      expect(repo.findOneBy).toHaveBeenCalledWith({ id: 'shop-id' });
      expect(memberRepo.find).toHaveBeenCalledWith({
        where: {
          barbershop: {
            id: 'shop-id',
            members: {
              user: { id: userId },
              role: In([BarbershopRole.OWNER, BarbershopRole.MANAGER]),
            },
          },
        },
        relations: { user: true },
        select: { id: true, role: true, user: { id: true, name: true } },
      });
    },
  );

  it.each(['employee-id', 'outsider-id'])(
    'mantém o detalhe acessível com lista vazia para %s',
    async userId => {
      repo.findOneBy.mockResolvedValue(barbershop);
      memberRepo.find.mockResolvedValue([]);

      await expect(service.findOne('shop-id', userId)).resolves.toEqual({
        message: 'Barbearia encontrada com sucesso',
        barbershop: { ...expected, members: [] },
      });
    },
  );

  it('projeta o usuário no detalhe contextual e consulta o vínculo local', async () => {
    repo.findOne.mockResolvedValue({
      ...barbershop,
      members: [
        ...barbershop.members,
        {
          id: 'employee-membership-id',
          role: BarbershopRole.EMPLOYEE,
          user: { id: 'employee-id', name: 'Funcionário' },
        },
      ],
    });

    await expect(service.findOneMe('shop-id', 'owner-id')).resolves.toEqual({
      message: 'Barbearia encontrada com sucesso',
      barbershop: expected,
    });
    expect(repo.findOne).toHaveBeenCalledWith({
      where: { id: 'shop-id', members: { user: { id: 'owner-id' } } },
      relations: { members: { user: true } },
      select: {
        members: { id: true, role: true, user: { id: true, name: true } },
      },
    });
  });

  it('retorna 404 para barbearia ausente ou sem vínculo com o solicitante', async () => {
    repo.findOneBy.mockResolvedValue(null);
    repo.findOne.mockResolvedValue(null);

    await expect(
      service.findOne('missing-shop', 'owner-id'),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(memberRepo.find).not.toHaveBeenCalled();
    await expect(
      service.findOneMe('shop-id', 'other-user'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('usa somente os dados da barbearia nas chamadas internas sem usuário', async () => {
    repo.findOneBy.mockResolvedValue(barbershop);

    await expect(service.findOne('shop-id')).resolves.toHaveProperty(
      'barbershop.members',
      [],
    );
    expect(memberRepo.find).not.toHaveBeenCalled();
  });

  it('projeta os dados da atualização mesmo com relações carregadas', async () => {
    repo.findOneBy.mockResolvedValue(barbershop);
    repo.merge.mockReturnValue({ ...barbershop, name: 'Novo nome' });

    await expect(
      service.update('shop-id', { name: 'Novo nome' }),
    ).resolves.toEqual({
      message: 'Barbearia atualizada com sucesso',
      barbershop: { ...expected, name: 'Novo nome' },
    });
  });
});
