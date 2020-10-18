import {Entity, Column, PrimaryGeneratedColumn} from "typeorm";

@Entity({ name: "Messages" })
export class Message {

  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  payload: string;
}
