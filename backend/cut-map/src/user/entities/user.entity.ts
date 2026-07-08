import { BarbershopMember } from 'src/barbershop/entities/barbershop-member.entity';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ type: 'varchar', unique: true })
  email: string;

  @Column({ select: false })
  passwordHash: string;

  @Column({ type: 'timestamp', nullable: true, select: false })
  emailVerifiedAt: Date | null;

  @Column({ type: 'varchar', length: 6, nullable: true, select: false })
  emailVerificationCode: string | null;

  @Column({ type: 'timestamp', nullable: true, select: false })
  emailVerificationExpires: Date | null;

  @Column({ type: 'varchar', length: 6, nullable: true, select: false })
  resetPasswordCode: string | null;

  @Column({ type: 'timestamp', nullable: true, select: false })
  resetPasswordExpires: Date | null;

  //   @Column({ nullable: true })
  //   phone: string;

  @CreateDateColumn({ select: false })
  createdAt: Date;

  @UpdateDateColumn({ select: false })
  updatedAt: Date;

  @OneToMany(() => BarbershopMember, barbershopMember => barbershopMember.user)
  memberships: BarbershopMember[];
}
