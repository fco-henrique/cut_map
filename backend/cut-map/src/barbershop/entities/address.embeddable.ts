import { Column } from 'typeorm';

export class Address {
  @Column({ length: 8, nullable: true })
  cep: string;

  @Column({ nullable: true })
  rua: string;

  @Column({ nullable: true })
  numero: string;

  @Column({ nullable: true })
  bairro: string;

  @Column({ nullable: true })
  cidade: string;

  @Column({ length: 2, nullable: true })
  estado: string;

  @Column({ nullable: true })
  pais: string;

  @Column('decimal', { precision: 10, scale: 7, nullable: true })
  latitude: number;

  @Column('decimal', { precision: 10, scale: 7, nullable: true })
  longitude: number;
}
