import { OmitType, PartialType } from '@nestjs/mapped-types';
import { IsNotEmpty, IsString, ValidateIf } from 'class-validator';
import { IsStrongPassword } from 'src/auth/validators/strong-password.decorator';
import { CreateUserDto } from './create-user.dto';

export class UpdateUserDto extends PartialType(
  OmitType(CreateUserDto, ['password'] as const),
) {
  // Ausente (undefined) = sem troca de senha. Qualquer valor enviado, inclusive
  // null ou string vazia, precisa respeitar a política de senha forte (400).
  @ValidateIf((dto: UpdateUserDto) => dto.password !== undefined)
  @IsStrongPassword()
  password?: string;

  @ValidateIf((dto: UpdateUserDto) => dto.password !== undefined)
  @IsString()
  @IsNotEmpty({ message: 'Informe a senha atual para trocar a senha.' })
  currentPassword?: string;
}
