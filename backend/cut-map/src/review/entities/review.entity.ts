import { Barbershop } from 'src/barbershop/entities/barbershop.entity';
import { User } from 'src/user/entities/user.entity';
import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';

@Entity('reviews')
export class Review {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('int')
  score: number;

  @Column({ type: 'text', nullable: true })
  comment: string;

  @ManyToOne(() => Barbershop, barbershop => barbershop.reviews, {
    onDelete: 'CASCADE',
  })
  barbershop: Barbershop;

  @ManyToOne(() => User, { onDelete: 'SET NULL' })
  user: User;

  @CreateDateColumn()
  createdAt: Date;
}
