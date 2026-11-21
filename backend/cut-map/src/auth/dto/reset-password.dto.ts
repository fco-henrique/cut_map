import { IsStrongPassword } from '../validators/strong-password.decorator';

export class ResetPasswordDto {
  @IsStrongPassword()
  newPassword: string;
}
