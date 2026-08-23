import {
  IsOptional,
  IsString,
  IsIn,
  IsNumber,
  ValidateIf,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';

export class GetBarbershopsFilterDto {
  @IsOptional()
  @IsString()
  @IsIn(['rating', 'distance', 'recent'])
  sortBy?: 'rating' | 'distance' | 'recent';

  @ValidateIf((dto: GetBarbershopsFilterDto) => dto.sortBy === 'distance')
  @Type(() => Number)
  @IsNumber(
    {},
    { message: 'lat é obrigatório e deve ser numérico quando sortBy=distance' },
  )
  @Min(-90)
  @Max(90)
  lat?: number;

  @ValidateIf((dto: GetBarbershopsFilterDto) => dto.sortBy === 'distance')
  @Type(() => Number)
  @IsNumber(
    {},
    { message: 'lng é obrigatório e deve ser numérico quando sortBy=distance' },
  )
  @Min(-180)
  @Max(180)
  lng?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(50)
  limit?: number = 10;
}
