import { Test, TestingModule } from '@nestjs/testing';

import { UserController } from './user.controller';
import { UserService } from './user.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AuthenticatedUser } from 'src/auth/interfaces/jwt-payload.interface';

describe('UserController', () => {
  let controller: UserController;
  let userService: {
    create: jest.Mock;
    update: jest.Mock;
    remove: jest.Mock;
  };

  beforeEach(async () => {
    userService = {
      create: jest.fn(),
      update: jest.fn(),
      remove: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UserController],
      providers: [
        {
          provide: UserService,
          useValue: userService,
        },
      ],
    }).compile();

    controller = module.get<UserController>(UserController);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getMe', () => {
    it('deve retornar o usuário autenticado', () => {
      const authenticatedUser: AuthenticatedUser = {
        sub: 'user-id',
        email: 'henrique@example.com',
        name: 'Henrique',
      };

      const result = controller.getMe(authenticatedUser);

      expect(result).toEqual(authenticatedUser);
    });
  });

  describe('create', () => {
    it('deve chamar o UserService.create com os dados do usuário', async () => {
      const createUserDto: CreateUserDto = {
        name: 'Henrique',
        email: 'henrique@example.com',
        password: 'password123',
      };

      const expectedResult = {
        message: 'Cadastro realizado. Verifique seu e-mail.',
        user: {
          id: 'user-id',
          name: 'Henrique',
          email: 'henrique@example.com',
        },
      };

      userService.create.mockResolvedValue(expectedResult);

      const result = await controller.create(createUserDto);

      expect(userService.create).toHaveBeenCalledTimes(1);
      expect(userService.create).toHaveBeenCalledWith(createUserDto);
      expect(result).toEqual(expectedResult);
    });

    it('deve propagar o erro retornado pelo UserService.create', async () => {
      const createUserDto: CreateUserDto = {
        name: 'Henrique',
        email: 'henrique@example.com',
        password: 'password123',
      };

      const error = new Error('Erro ao cadastrar usuário');

      userService.create.mockRejectedValue(error);

      await expect(controller.create(createUserDto)).rejects.toThrow(error);

      expect(userService.create).toHaveBeenCalledWith(createUserDto);
    });
  });

  describe('update', () => {
    it('deve chamar o UserService.update com id, dados e usuário autenticado', async () => {
      const id = 'user-id';

      const updateUserDto: UpdateUserDto = {
        name: 'Novo nome',
      };

      const currentUserId = 'user-id';

      const expectedResult = {
        id: 'user-id',
        name: 'Novo nome',
        email: 'henrique@example.com',
      };

      userService.update.mockResolvedValue(expectedResult);

      const result = await controller.update(id, updateUserDto, currentUserId);

      expect(userService.update).toHaveBeenCalledTimes(1);
      expect(userService.update).toHaveBeenCalledWith(
        id,
        updateUserDto,
        currentUserId,
      );

      expect(result).toEqual(expectedResult);
    });

    it('deve propagar o erro retornado pelo UserService.update', async () => {
      const id = 'user-id';

      const updateUserDto: UpdateUserDto = {
        name: 'Novo nome',
      };

      const currentUserId = 'other-user-id';

      const error = new Error('Não é permitido alterar outro usuário');

      userService.update.mockRejectedValue(error);

      await expect(
        controller.update(id, updateUserDto, currentUserId),
      ).rejects.toThrow(error);

      expect(userService.update).toHaveBeenCalledWith(
        id,
        updateUserDto,
        currentUserId,
      );
    });
  });

  describe('remove', () => {
    it('deve chamar o UserService.remove com id e usuário autenticado', async () => {
      const id = 'user-id';
      const currentUserId = 'user-id';

      const expectedResult = {
        affected: 1,
      };

      userService.remove.mockResolvedValue(expectedResult);

      const result = await controller.remove(id, currentUserId);

      expect(userService.remove).toHaveBeenCalledTimes(1);
      expect(userService.remove).toHaveBeenCalledWith(id, currentUserId);

      expect(result).toEqual(expectedResult);
    });

    it('deve propagar o erro retornado pelo UserService.remove', async () => {
      const id = 'user-id';
      const currentUserId = 'other-user-id';

      const error = new Error('Não é permitido remover outro usuário');

      userService.remove.mockRejectedValue(error);

      await expect(controller.remove(id, currentUserId)).rejects.toThrow(error);

      expect(userService.remove).toHaveBeenCalledWith(id, currentUserId);
    });
  });
});
