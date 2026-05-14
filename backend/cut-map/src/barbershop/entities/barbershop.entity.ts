import { BarbershopMember } from 'src/barbershop-member/entities/barbershop-member.entity';
import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';

@Entity('barbershops')
export class Barbershop {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column()
  address: string;

  @OneToMany(() => BarbershopMember, member => member.barbershop)
  members: BarbershopMember[];
}
