import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateBarbershopDto } from './create-barbershop.dto';

const validBody = {
  name: 'Barbearia Central',
  phone: '11999998888',
  address: {
    rua: 'Rua Central',
    numero: '10',
    bairro: 'Centro',
    latitude: -23.55,
    longitude: -46.63,
  },
  openingHours: [
    {
      dayOfWeek: 1,
      opensAt: '09:00',
      closesAt: '18:00',
      breakStartsAt: '12:00',
      breakEndsAt: '13:00',
    },
  ],
};

describe('CreateBarbershopDto', () => {
  it('accepts a valid schedule with a lunch break', async () => {
    const dto = plainToInstance(CreateBarbershopDto, validBody);
    expect(await validate(dto)).toHaveLength(0);
  });

  it('rejects duplicate weekdays', async () => {
    const dto = plainToInstance(CreateBarbershopDto, {
      ...validBody,
      openingHours: [validBody.openingHours[0], validBody.openingHours[0]],
    });
    expect(
      (await validate(dto)).some(error => error.property === 'openingHours'),
    ).toBe(true);
  });

  it('rejects a lunch break outside opening hours', async () => {
    const dto = plainToInstance(CreateBarbershopDto, {
      ...validBody,
      openingHours: [
        {
          dayOfWeek: 1,
          opensAt: '09:00',
          closesAt: '18:00',
          breakStartsAt: '18:00',
          breakEndsAt: '19:00',
        },
      ],
    });
    expect(
      (await validate(dto)).some(error => error.property === 'openingHours'),
    ).toBe(true);
  });

  it('requires a phone with DDD', async () => {
    const dto = plainToInstance(CreateBarbershopDto, {
      ...validBody,
      phone: '9999',
    });
    expect(
      (await validate(dto)).some(error => error.property === 'phone'),
    ).toBe(true);
  });
});
