import { Type } from 'class-transformer';
import { IsInt, IsString, Max, Min, MinLength } from 'class-validator';

export class SearchUserDto {
  @IsString()
  @MinLength(2, { message: 'Digite ao menos 2 caracteres para buscar.' })
  name: string;

  @IsInt()
  @Min(1)
  @Max(20)
  @Type(() => Number)
  limit: number = 10;
}
