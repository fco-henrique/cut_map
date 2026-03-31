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

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async create(createUserDto: CreateUserDto) {
    try {
      const user = this.userRepo.create({
        name: createUserDto.name,
        email: createUserDto.email,
        passwordHash: createUserDto.password,
      });

      await this.userRepo.save(user);

      return user;
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
      user.passwordHash = updateUserDto.password;
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
