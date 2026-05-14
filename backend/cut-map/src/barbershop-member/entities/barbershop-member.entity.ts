import { Barbershop } from 'src/barbershop/entities/barbershop.entity';
import { User } from 'src/user/entities/user.entity';
import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

export enum BarbershopRole {
  OWNER = 'OWNER',
  EMPLOYEE = 'EMPLOYEE',
  MANAGER = 'MANAGER',
}

@Entity('barbershop_member')
export class BarbershopMember {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Barbershop, barbershop => barbershop.members, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'barbershop_id' })
  barbershop: Barbershop;

  @ManyToOne(() => User, user => user.memberships, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id' })
  user: User;

  @Column({
    type: 'enum',
    enum: BarbershopRole,
    default: BarbershopRole.EMPLOYEE,
  })
  role: BarbershopRole;
}
