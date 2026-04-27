import { Injectable } from '@nestjs/common';
import { randomInt } from 'crypto';
import * as nodemailer from 'nodemailer';
import { getVerificationEmailTemplate } from './templates/verification.template';

@Injectable()
export class EmailService {
  private transporter = nodemailer.createTransport({
    host: process.env.MAIL_HOST,
    port: Number(process.env.MAIL_PORT),
    auth: {
      user: process.env.MAIL_USER,
      pass: process.env.MAIL_PASS,
    },
  });

  async sendVerificationCode(
    to: string,
    name: string,
    code: string,
  ): Promise<void> {
    await this.transporter.sendMail({
      from: `"Cut Map" <${process.env.MAIL_USER}>`,
      to,
      subject: 'Confirme seu e-mail — Cut Map',
      html: getVerificationEmailTemplate(name, code),
    });
  }

  public generateVerificationCode(): string {
    const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      const randomIndex = randomInt(0, chars.length);
      code += chars[randomIndex];
    }
    return code;
  }
}
