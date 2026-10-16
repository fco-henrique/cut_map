import { PartialType } from '@nestjs/mapped-types';
import { IsNotEmpty, IsString, ValidateIf } from 'class-validator';
import { CreateUserDto } from './create-user.dto';

export class UpdateUserDto extends PartialType(CreateUserDto) {
  @ValidateIf((dto: UpdateUserDto) => !!dto.password)
  @IsString()
  @IsNotEmpty({ message: 'Informe a senha atual para trocar a senha.' })
  currentPassword?: string;
}
