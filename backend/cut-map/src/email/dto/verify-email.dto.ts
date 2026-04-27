import { Transform } from 'class-transformer';
import { IsEmail, IsString, Length } from 'class-validator';

export class VerifyEmailDto {
  @IsEmail()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase() : value,
  )
  email: string;

  @IsString()
  @Length(6, 6)
  code: string;
}
