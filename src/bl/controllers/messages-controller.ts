import { FindManyOptions, Repository } from "typeorm";
import { Message } from "../../storage/entities/message";
import { Db } from "../../storage/infra/db";

export class MessagesController {
  private _repository: Repository<Message>;
 
  public constructor() {
    this._repository = Db.getConnection().getRepository(Message);
  }

  public async create(message: Message): Promise<Message> {
    return await this._repository.save(message);
  }

  public async update(id: number, message: Message): Promise<Message> {    
    let entityToUpdate: Message = await this._repository.findOne(id);
    if (!entityToUpdate) {
      return;
    }
    entityToUpdate.payload = message.payload;
    return await this._repository.save(entityToUpdate);
  }

  public async getAll(): Promise<Message[]> {
    return await this._repository.find();             
  }

  public async get(id: number): Promise<Message> {
    return await this._repository.findOne(id);           
  }  

  public async delete(id: number): Promise<Message> {
    let entityToRemove: Message = await this._repository.findOne(id); 
    if (!entityToRemove) {
      return;
    }
    return await this._repository.remove(entityToRemove);
  }
}
