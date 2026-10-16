import { Test, TestingModule } from '@nestjs/testing';
import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';

import { UserService } from './user.service';
import { User } from './entities/user.entity';
import { HashingService } from 'src/auth/hashing/hashing.service';
import { EmailService } from 'src/email/email.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

describe('UserService', () => {
  let service: UserService;
  let userRepo: jest.Mocked<Repository<User>>;
  let hashingService: jest.Mocked<HashingService>;
  let emailService: jest.Mocked<EmailService>;

  const user: User = {
    id: 'user-id',
    name: 'Henrique',
    email: 'henrique@example.com',
    passwordHash: 'hashed-password',
    emailVerificationCode: 'ABC123',
    emailVerificationExpires: new Date('2030-01-01T00:00:00.000Z'),
  } as User;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserService,
        {
          provide: getRepositoryToken(User),
          useValue: {
            create: jest.fn(),
            save: jest.fn(),
            find: jest.fn(),
            findOne: jest.fn(),
            delete: jest.fn(),
          },
        },
        {
          provide: HashingService,
          useValue: {
            hash: jest.fn(),
            compare: jest.fn(),
          },
        },
        {
          provide: EmailService,
          useValue: {
            generateVerificationCode: jest.fn(),
            sendVerificationCode: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
    userRepo = module.get(getRepositoryToken(User));
    hashingService = module.get(HashingService);
    emailService = module.get(EmailService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    const createUserDto: CreateUserDto = {
      name: 'Henrique',
      email: 'henrique@example.com',
      password: 'password123',
    };

    it('deve criar um usuário, salvar e enviar o código de verificação', async () => {
      const passwordHash = 'hashed-password';
      const verificationCode = 'ABC123';

      hashingService.hash.mockResolvedValue(passwordHash);
      emailService.generateVerificationCode.mockReturnValue(verificationCode);
      userRepo.create.mockReturnValue(user);
      userRepo.save.mockResolvedValue(user);
      emailService.sendVerificationCode.mockResolvedValue(undefined);

      const result = await service.create(createUserDto);

      expect(hashingService.hash).toHaveBeenCalledWith(createUserDto.password);

      expect(emailService.generateVerificationCode).toHaveBeenCalled();

      expect(userRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          ...createUserDto,
          passwordHash,
          emailVerificationCode: verificationCode,
          emailVerificationExpires: expect.any(Date),
        }),
      );

      expect(userRepo.save).toHaveBeenCalledWith(user);

      expect(emailService.sendVerificationCode).toHaveBeenCalledWith(
        user.email,
        user.name,
        verificationCode,
      );

      expect(result).toEqual({
        message: 'Cadastro realizado. Verifique seu e-mail.',
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
        },
      });
    });

    it('deve criar o usuário mesmo quando o envio do e-mail falhar', async () => {
      const passwordHash = 'hashed-password';
      const verificationCode = 'ABC123';

      hashingService.hash.mockResolvedValue(passwordHash);
      emailService.generateVerificationCode.mockReturnValue(verificationCode);
      userRepo.create.mockReturnValue(user);
      userRepo.save.mockResolvedValue(user);
      emailService.sendVerificationCode.mockRejectedValue(
        new Error('Falha no envio'),
      );

      const result = await service.create(createUserDto);

      expect(userRepo.save).toHaveBeenCalledWith(user);
      expect(emailService.sendVerificationCode).toHaveBeenCalledWith(
        user.email,
        user.name,
        verificationCode,
      );

      expect(result).toEqual({
        message:
          'Cadastro realizado, mas houve instabilidade no envio do e-mail. Por favor, solicite um novo código na tela de login.',
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
        },
      });
    });

    it('deve lançar ConflictException quando o e-mail já estiver cadastrado', async () => {
      const error = Object.assign(
        new QueryFailedError(
          'INSERT INTO user',
          [],
          new Error('duplicate key'),
        ),
        {
          code: '23505',
          detail: 'Key (email)=(henrique@example.com) already exists.',
        },
      );

      hashingService.hash.mockResolvedValue('hashed-password');
      emailService.generateVerificationCode.mockReturnValue('ABC123');
      userRepo.create.mockReturnValue(user);
      userRepo.save.mockRejectedValue(error);

      await expect(service.create(createUserDto)).rejects.toThrow(
        new ConflictException('Email já está cadastrado.'),
      );

      expect(emailService.sendVerificationCode).not.toHaveBeenCalled();
    });

    it('deve lançar ConflictException quando ocorrer violação de unicidade que não seja de e-mail', async () => {
      const error = Object.assign(
        new QueryFailedError(
          'INSERT INTO user',
          [],
          new Error('duplicate key'),
        ),
        {
          code: '23505',
          detail: 'Key (username)=(henrique) already exists.',
        },
      );

      hashingService.hash.mockResolvedValue('hashed-password');
      emailService.generateVerificationCode.mockReturnValue('ABC123');
      userRepo.create.mockReturnValue(user);
      userRepo.save.mockRejectedValue(error);

      await expect(service.create(createUserDto)).rejects.toThrow(
        new ConflictException('Usuário já cadastrado.'),
      );
    });

    it('deve propagar erros que não sejam de violação de unicidade', async () => {
      const error = new Error('Erro inesperado');

      hashingService.hash.mockResolvedValue('hashed-password');
      emailService.generateVerificationCode.mockReturnValue('ABC123');
      userRepo.create.mockReturnValue(user);
      userRepo.save.mockRejectedValue(error);

      await expect(service.create(createUserDto)).rejects.toThrow(error);
    });
  });

  describe('findAll', () => {
    it('deve retornar todos os usuários', async () => {
      const users = [
        user,
        {
          ...user,
          id: 'user-id-2',
          name: 'João',
          email: 'joao@example.com',
        } as User,
      ];

      userRepo.find.mockResolvedValue(users);

      const result = await service.findAll();

      expect(userRepo.find).toHaveBeenCalledWith();
      expect(result).toEqual(users);
    });
  });

  describe('findOne', () => {
    it('deve retornar o usuário quando ele existir', async () => {
      userRepo.findOne.mockResolvedValue(user);

      const result = await service.findOne(user.id);

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { id: user.id },
      });
      expect(result).toBe(user);
    });

    it('deve lançar NotFoundException quando o usuário não existir', async () => {
      userRepo.findOne.mockResolvedValue(null);

      await expect(service.findOne('unknown-id')).rejects.toThrow(
        new NotFoundException('Usuário não encontrado ou inexistente!'),
      );

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'unknown-id' },
      });
    });
  });

  describe('searchByName', () => {
    it('deve buscar usuários pelo nome e respeitar o limite', async () => {
      const users = [
        { id: 'user-id', name: 'Henrique' },
        { id: 'user-id-2', name: 'Henrique Silva' },
      ];

      userRepo.find.mockResolvedValue(users as User[]);

      const result = await service.searchByName('Henrique', 10);

      expect(userRepo.find).toHaveBeenCalledWith({
        where: {
          name: expect.anything(),
        },
        select: ['id', 'name'],
        order: { name: 'ASC' },
        take: 10,
      });

      expect(result).toEqual(users);
    });
  });

  describe('update', () => {
    it('deve lançar ForbiddenException ao tentar alterar outro usuário', async () => {
      const updateUserDto: UpdateUserDto = {
        name: 'Novo nome',
      };

      await expect(
        service.update('user-id', updateUserDto, 'other-user-id'),
      ).rejects.toThrow(
        new ForbiddenException('Não é permitido alterar outro usuário'),
      );

      expect(userRepo.findOne).not.toHaveBeenCalled();
      expect(userRepo.save).not.toHaveBeenCalled();
    });

    it('deve lançar NotFoundException quando o usuário não existir', async () => {
      const updateUserDto: UpdateUserDto = {
        name: 'Novo nome',
      };

      userRepo.findOne.mockResolvedValue(null);

      await expect(
        service.update('user-id', updateUserDto, 'user-id'),
      ).rejects.toThrow(new NotFoundException('Usuário não encontrado'));

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'user-id' },
        select: ['id', 'name', 'email', 'passwordHash'],
      });
    });

    it('deve atualizar o nome do usuário', async () => {
      const updateUserDto: UpdateUserDto = {
        name: 'Novo nome',
      };

      const existingUser = { ...user };
      const savedUser = {
        ...existingUser,
        name: 'Novo nome',
      } as User;

      userRepo.findOne.mockResolvedValue(existingUser);
      userRepo.save.mockResolvedValue(savedUser);

      const result = await service.update(user.id, updateUserDto, user.id);

      expect(existingUser.name).toBe('Novo nome');
      expect(hashingService.hash).not.toHaveBeenCalled();
      expect(userRepo.save).toHaveBeenCalledWith(existingUser);

      expect(result).toEqual({
        id: savedUser.id,
        name: savedUser.name,
        email: savedUser.email,
      });
    });

    it('deve rejeitar a troca de senha quando a senha atual estiver incorreta', async () => {
      const existingUser = { ...user };
      userRepo.findOne.mockResolvedValue(existingUser);
      hashingService.compare.mockResolvedValue(false);

      await expect(
        service.update(
          user.id,
          { password: 'new-password', currentPassword: 'wrong-password' },
          user.id,
        ),
      ).rejects.toThrow(new ForbiddenException('Senha atual incorreta.'));

      expect(hashingService.compare).toHaveBeenCalledWith(
        'wrong-password',
        user.passwordHash,
      );
      expect(hashingService.hash).not.toHaveBeenCalled();
      expect(userRepo.save).not.toHaveBeenCalled();
      expect(existingUser.passwordHash).toBe(user.passwordHash);
    });

    it('deve rejeitar a troca de senha quando a senha atual não for informada', async () => {
      userRepo.findOne.mockResolvedValue({ ...user });
      hashingService.compare.mockResolvedValue(false);

      await expect(
        service.update(user.id, { password: 'new-password' }, user.id),
      ).rejects.toThrow(new ForbiddenException('Senha atual incorreta.'));

      expect(hashingService.compare).toHaveBeenCalledWith(
        '',
        user.passwordHash,
      );
      expect(hashingService.hash).not.toHaveBeenCalled();
      expect(userRepo.save).not.toHaveBeenCalled();
    });

    it('deve atualizar a senha usando o serviço de hashing', async () => {
      const updateUserDto: UpdateUserDto = {
        password: 'new-password',
        currentPassword: 'old-password',
      };

      const existingUser = { ...user };
      const savedUser = {
        ...existingUser,
        passwordHash: 'new-hashed-password',
      } as User;

      hashingService.compare.mockResolvedValue(true);
      hashingService.hash.mockResolvedValue('new-hashed-password');
      userRepo.findOne.mockResolvedValue(existingUser);
      userRepo.save.mockResolvedValue(savedUser);

      const result = await service.update(user.id, updateUserDto, user.id);

      expect(hashingService.compare).toHaveBeenCalledWith(
        'old-password',
        user.passwordHash,
      );
      expect(hashingService.hash).toHaveBeenCalledWith(updateUserDto.password);

      expect(existingUser.passwordHash).toBe('new-hashed-password');
      expect(existingUser.passwordChangedAt).toBeInstanceOf(Date);
      expect(userRepo.save).toHaveBeenCalledWith(existingUser);

      expect(result).toEqual({
        id: savedUser.id,
        name: savedUser.name,
        email: savedUser.email,
      });
    });

    it('deve atualizar nome e senha quando ambos forem informados', async () => {
      const updateUserDto: UpdateUserDto = {
        name: 'Novo nome',
        password: 'new-password',
        currentPassword: 'old-password',
      };

      const existingUser = { ...user };
      const savedUser = {
        ...existingUser,
        name: 'Novo nome',
        passwordHash: 'new-hashed-password',
      } as User;

      hashingService.compare.mockResolvedValue(true);
      hashingService.hash.mockResolvedValue('new-hashed-password');
      userRepo.findOne.mockResolvedValue(existingUser);
      userRepo.save.mockResolvedValue(savedUser);

      const result = await service.update(user.id, updateUserDto, user.id);

      expect(hashingService.hash).toHaveBeenCalledWith('new-password');
      expect(hashingService.compare).toHaveBeenCalledWith(
        'old-password',
        user.passwordHash,
      );
      expect(existingUser.name).toBe('Novo nome');
      expect(existingUser.passwordHash).toBe('new-hashed-password');
      expect(userRepo.save).toHaveBeenCalledWith(existingUser);

      expect(result).toEqual({
        id: savedUser.id,
        name: savedUser.name,
        email: savedUser.email,
      });
    });

    it('deve manter os dados quando nenhum campo atualizável for informado', async () => {
      const updateUserDto: UpdateUserDto = {};

      const existingUser = { ...user };
      const savedUser = { ...existingUser };

      userRepo.findOne.mockResolvedValue(existingUser);
      userRepo.save.mockResolvedValue(savedUser);

      const result = await service.update(user.id, updateUserDto, user.id);

      expect(hashingService.hash).not.toHaveBeenCalled();
      expect(userRepo.save).toHaveBeenCalledWith(existingUser);

      expect(result).toEqual({
        id: savedUser.id,
        name: savedUser.name,
        email: savedUser.email,
      });
    });
  });

  describe('remove', () => {
    it('deve lançar ForbiddenException ao tentar remover outro usuário', async () => {
      await expect(service.remove('user-id', 'other-user-id')).rejects.toThrow(
        new ForbiddenException('Não é permitido remover outro usuário'),
      );

      expect(userRepo.delete).not.toHaveBeenCalled();
    });

    it('deve remover o próprio usuário', async () => {
      const deleteResult = {
        affected: 1,
        raw: {},
      };

      userRepo.delete.mockResolvedValue(deleteResult);

      const result = await service.remove(user.id, user.id);

      expect(userRepo.delete).toHaveBeenCalledWith({
        id: user.id,
      });

      expect(result).toEqual(deleteResult);
    });

    it('deve lançar NotFoundException quando nenhum usuário for removido', async () => {
      userRepo.delete.mockResolvedValue({
        affected: 0,
        raw: {},
      });

      await expect(service.remove(user.id, user.id)).rejects.toThrow(
        new NotFoundException('Usuário não encontrado'),
      );

      expect(userRepo.delete).toHaveBeenCalledWith({
        id: user.id,
      });
    });
  });
});
