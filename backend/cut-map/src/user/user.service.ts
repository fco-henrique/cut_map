import { ConflictException, Injectable } from '@nestjs/common';
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

  findOne(id: number) {
    return `This action returns a #${id} user`;
  }

  update(id: number, updateUserDto: UpdateUserDto) {
    return `This action updates a #${id} user`;
  }

  remove(id: number) {
    return `This action removes a #${id} user`;
  }
}
