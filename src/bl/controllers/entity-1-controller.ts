import { Repository } from "typeorm";
import { Entity1 } from "../../storage/entities/entity-1";
import { Db } from "../../storage/infra/db";

export class Entity1Controller {
  private _repository: Repository<Entity1>;
 
  public constructor() {
    this._repository = Db.getConnection().getRepository(Entity1);
  }

  public async create(entity1: Entity1): Promise<Entity1> {
    return await this._repository.save(entity1);
  }

  public async update(id: number, entity1: Entity1): Promise<Entity1> {    
    let entityToUpdate: Entity1 = await this._repository.findOne(id);
    if (!entityToUpdate) {
      return;
    }
    entityToUpdate.payload = entity1.payload;
    return await this._repository.save(entityToUpdate);
  }

  public async getAll(): Promise<Entity1[]> {
    return await this._repository.find();             
  }

  public async get(id: number): Promise<Entity1> {
    return await this._repository.findOne(id);           
  }  

  public async delete(id: number): Promise<Entity1> {
    let entityToRemove: Entity1 = await this._repository.findOne(id); 
    if (!entityToRemove) {
      return;
    }
    return await this._repository.remove(entityToRemove);
  }
}
