import {
  IsInt,
  Min,
  Max,
  IsString,
  IsOptional,
  MaxLength,
} from 'class-validator';

export class CreateReviewDto {
  @IsInt({ message: 'A nota deve ser um número inteiro.' })
  @Min(1, { message: 'A nota mínima é 1.' })
  @Max(5, { message: 'A nota máxima é 5.' })
  score: number;

  @IsString({ message: 'O comentário deve ser um texto.' })
  @IsOptional()
  @MaxLength(500, {
    message: 'O comentário não pode ter mais de 500 caracteres.',
  })
  comment?: string;
}
