import { Injectable } from '@nestjs/common';

export interface SentEmail {
  to: string;
  name: string;
  code: string;
  type: 'verification' | 'reset';
  sentAt: Date;
}

@Injectable()
export class FakeEmailAdapter {
  private emails: SentEmail[] = [];

  sendVerificationCode(to: string, name: string, code: string): Promise<void> {
    this.emails.push({
      to,
      name,
      code,
      type: 'verification',
      sentAt: new Date(),
    });
    return Promise.resolve();
  }

  sendPasswordResetCode(to: string, name: string, code: string): Promise<void> {
    this.emails.push({
      to,
      name,
      code,
      type: 'reset',
      sentAt: new Date(),
    });
    return Promise.resolve();
  }

  generateVerificationCode(): string {
    const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let code: string;
    do {
      code = '';
      for (let i = 0; i < 6; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
      }
    } while (!/[A-Z]/.test(code) || !/[a-z]/.test(code) || !/[0-9]/.test(code));

    return code;
  }

  getLatestVerificationCode(email: string): string | undefined {
    const match = this.emails
      .filter(
        e =>
          e.to.toLowerCase() === email.toLowerCase() &&
          e.type === 'verification',
      )
      .pop();
    return match?.code;
  }

  getLatestResetCode(email: string): string | undefined {
    const match = this.emails
      .filter(
        e => e.to.toLowerCase() === email.toLowerCase() && e.type === 'reset',
      )
      .pop();
    return match?.code;
  }

  getAllEmails(): ReadonlyArray<SentEmail> {
    return [...this.emails];
  }

  clear(): void {
    this.emails = [];
  }
}
