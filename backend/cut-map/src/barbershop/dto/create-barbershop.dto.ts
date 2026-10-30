import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { AddressDto } from './address.dto';
import { OpeningHourDto, OpeningHoursValidation } from './opening-hours.dto';

export class CreateBarbershopDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @Matches(/^\d{10,11}$/, {
    message: 'Telefone deve ter DDD e 10 ou 11 dígitos.',
  })
  phone: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => AddressDto)
  address?: AddressDto;

  @OpeningHoursValidation()
  openingHours: OpeningHourDto[];
}
