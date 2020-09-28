import {Entity, Column, PrimaryGeneratedColumn, CreateDateColumn} from "typeorm";

export type MessageType = "Palindrome" | "NoPalindrome";

@Entity({ name: "Messages" })
export class Message {

  @PrimaryGeneratedColumn()
  id: number;

  @CreateDateColumn()
  date: Date;

  @Column()
  payload: string;

  @Column({nullable: true})
  type: MessageType;  
}
