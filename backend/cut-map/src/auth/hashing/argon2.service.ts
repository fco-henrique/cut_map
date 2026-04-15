import { Injectable } from '@nestjs/common';
import * as argon2 from 'argon2';
import { HashingService } from './hashing.service';

@Injectable()
export class Argon2Service extends HashingService {
  async hash(password: string): Promise<string> {
    return argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16,
      timeCost: 3,
      parallelism: 1,
    });
  }

  async compare(password: string, passwordHash: string): Promise<boolean> {
    return argon2.verify(passwordHash, password);
  }
}
