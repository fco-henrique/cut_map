import { BarbershopMember } from 'src/barbershop/entities/barbershop-member.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Address } from './address.embeddable';
import { Review } from 'src/review/entities/review.entity';

@Entity('barbershops')
export class Barbershop {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column(() => Address)
  address: Address;

  @OneToMany(() => BarbershopMember, member => member.barbershop)
  members: BarbershopMember[];

  @Column('decimal', { precision: 3, scale: 2, default: 0 })
  averageRating: number;

  @Column({ default: 0 })
  totalReviews: number;

  @OneToMany(() => Review, review => review.barbershop)
  reviews: Review[];

  @CreateDateColumn({ select: false })
  createdAt: Date;

  @UpdateDateColumn({ select: false })
  updatedAt: Date;
}
