import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsInt,
  IsOptional,
  Matches,
  Max,
  Min,
  Validate,
  ValidateNested,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import { Type } from 'class-transformer';

const timePattern = /^([01]\d|2[0-3]):[0-5]\d$/;

export class OpeningHourDto {
  @IsInt()
  @Min(1)
  @Max(7)
  dayOfWeek: number;

  @Matches(timePattern)
  opensAt: string;

  @Matches(timePattern)
  closesAt: string;

  @IsOptional()
  @Matches(timePattern)
  breakStartsAt?: string;

  @IsOptional()
  @Matches(timePattern)
  breakEndsAt?: string;
}

@ValidatorConstraint({ name: 'validOpeningHours', async: false })
export class ValidOpeningHours implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    if (!Array.isArray(value)) return false;
    const days = new Set<number>();

    for (const entry of value as OpeningHourDto[]) {
      if (
        !entry ||
        !Number.isInteger(entry.dayOfWeek) ||
        entry.dayOfWeek < 1 ||
        entry.dayOfWeek > 7 ||
        !timePattern.test(entry.opensAt) ||
        !timePattern.test(entry.closesAt) ||
        days.has(entry.dayOfWeek)
      )
        return false;

      days.add(entry.dayOfWeek);
      if (entry.opensAt >= entry.closesAt) return false;

      const hasBreakStart = entry.breakStartsAt != null;
      const hasBreakEnd = entry.breakEndsAt != null;
      if (hasBreakStart !== hasBreakEnd) return false;
      if (
        hasBreakStart &&
        (!timePattern.test(entry.breakStartsAt!) ||
          !timePattern.test(entry.breakEndsAt!) ||
          entry.opensAt >= entry.breakStartsAt! ||
          entry.breakStartsAt! >= entry.breakEndsAt! ||
          entry.breakEndsAt! >= entry.closesAt)
      )
        return false;
    }

    return true;
  }

  defaultMessage(): string {
    return 'Informe dias únicos, horários em HH:mm e uma pausa dentro do expediente.';
  }
}

export function OpeningHoursValidation(): PropertyDecorator {
  return (target, propertyKey) => {
    IsArray()(target, propertyKey);
    ArrayMinSize(1)(target, propertyKey);
    ArrayMaxSize(7)(target, propertyKey);
    ValidateNested({ each: true })(target, propertyKey);
    Type(() => OpeningHourDto)(target, propertyKey);
    Validate(ValidOpeningHours)(target, propertyKey);
  };
}
