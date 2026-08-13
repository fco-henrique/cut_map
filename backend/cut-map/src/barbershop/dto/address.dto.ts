import { IsString, IsOptional, IsNumber, MaxLength } from 'class-validator';

export class AddressDto {
  @IsString()
  @IsOptional()
  @MaxLength(8)
  cep?: string;

  @IsString()
  @IsOptional()
  rua?: string;

  @IsString()
  @IsOptional()
  numero?: string;

  @IsString()
  @IsOptional()
  bairro?: string;

  @IsString()
  @IsOptional()
  cidade?: string;

  @IsString()
  @IsOptional()
  @MaxLength(2)
  estado?: string;

  @IsString()
  @IsOptional()
  pais?: string;

  @IsNumber()
  @IsOptional()
  latitude?: number;

  @IsNumber()
  @IsOptional()
  longitude?: number;
}
