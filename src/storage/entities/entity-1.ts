import {Entity, Column, PrimaryGeneratedColumn} from "typeorm";

@Entity({ name: "Entity1s" })
export class Entity1 {

  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  payload: string;
}
