import { Transform } from 'class-transformer';
import { IsEmail } from 'class-validator';

export class ResendCodeDto {
  @IsEmail()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toLowerCase() : value,
  )
  email: string;
}
