import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  //   OneToMany,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  email: string;

  @Column({ select: false })
  passwordHash: string;

  @Column({ type: 'timestamp', nullable: true })
  emailVerifiedAt: Date | null;

  //   @Column({ nullable: true })
  //   phone: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relacionamento para definir onde ele trabalha ou é dono
  // Você precisará criar a entidade 'UserBarbershop' para gerenciar os cargos
  //   @OneToMany(() => UserBarbershop, (userBarbershop) => userBarbershop.user)
  //   memberships: UserBarbershop[];
}
