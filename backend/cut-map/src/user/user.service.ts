import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { HashingService } from 'src/auth/hashing/hashing.service';
import { EmailService } from 'src/email/email.service';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly hashingService: HashingService,
    private readonly emailService: EmailService,
  ) {}

  async create(createUserDto: CreateUserDto) {
    try {
      const passwordHash = await this.hashingService.hash(
        createUserDto.password,
      );

      const code = this.emailService.generateVerificationCode();

      const user = this.userRepo.create({
        ...createUserDto,
        passwordHash,
        emailVerificationCode: code,
        emailVerificationExpires: new Date(Date.now() + 15 * 60 * 1000),
      });

      await this.userRepo.save(user);

      try {
        await this.emailService.sendVerificationCode(
          user.email,
          user.name,
          code,
        );
      } catch (emailError) {
        console.error('Erro ao enviar e-mail de boas-vindas:', emailError);
        return {
          message:
            'Cadastro realizado, mas houve instabilidade no envio do e-mail. Por favor, solicite um novo código na tela de login.',
          user,
        };
      }

      return { message: 'Cadastro realizado. Verifique seu e-mail.', user };
    } catch (error) {
      if (
        error instanceof QueryFailedError &&
        (error as QueryFailedError & { code: string }).code === '23505'
      ) {
        const detail = (error as QueryFailedError & { detail: string }).detail;

        if (detail.includes('email')) {
          throw new ConflictException('Email já está cadastrado.');
        }

        throw new ConflictException('Usuário já cadastrado.');
      }

      throw error;
    }
  }

  async findAll() {
    const users = await this.userRepo.find();
    return users;
  }

  async findOne(id: string) {
    const user = await this.userRepo.findOne({ where: { id } });

    if (!user)
      throw new NotFoundException('Usuário não encontrado ou inexistente!');

    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    const user = await this.userRepo.findOne({
      where: { id },
    });

    if (!user) throw new NotFoundException('Usuário não encontrado');

    if (updateUserDto.name) {
      user.name = updateUserDto.name;
    }

    if (updateUserDto.password) {
      user.passwordHash = await this.hashingService.hash(
        updateUserDto.password,
      );
    }

    return this.userRepo.save(user);
  }

  async remove(id: string) {
    const result = await this.userRepo.delete({ id });

    if (result.affected === 0)
      throw new NotFoundException('Usuário não encontrado');

    return result;
  }
}
