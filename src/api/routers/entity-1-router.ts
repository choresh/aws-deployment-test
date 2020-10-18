import { Express, Router, Request, Response } from "express";
import { Entity1Controller } from "../../bl/controllers/entity-1-controller";
import { Entity1 } from "../../storage/entities/entity-1";

export class Entity1Router {

  public static run(app: Express, router: Router): void {
    var controller: Entity1Controller = new Entity1Controller();

    // Create a new entity1
    router.post("/", async (req: Request, res: Response) => {
      if (!req.body.payload) {
        res.status(400).send("Body property 'payload' is missing");
        return;
      }
      const entity1 = new Entity1();
      entity1.payload = req.body.payload;
      var result = await controller.create(entity1);     
      res.status(201).json(result);
    });

    // Retrieve all entity1
    router.get("/", async (req: Request, res: Response) => {
      var result = await controller.getAll();
      res.json(result);
    });

    // Retrieve a single entity1 with id
    router.get("/:id", async (req: Request, res: Response) => {
      let entity1Id: number = parseInt(req.params.id);
      if (isNaN(entity1Id)) {
        res.status(400).send("URL token for entity1 Id is not a number");
        return;
      }
      var result = await controller.get(entity1Id);
      if (!result) {
        res.status(404).send("Entity1 with Id '" + entity1Id + "' not found");
      }
      res.json(result);
    });

    // Update a single entity1 with id
    router.put("/:id", async (req: Request, res: Response) => {
      let entity1Id: number = parseInt(req.params.id);
      if (isNaN(entity1Id)) {
        res.status(400).send("URL token for entity1 Id is not a number");
        return;
      }
      if (!req.body.payload) {
        res.status(400).send("Body property 'payload' is missing");
        return;
      }
      let entity1 = new Entity1();
      entity1.payload = req.body.payload;
      var result = await controller.update(entity1Id, entity1);
      if (!result) {
        res.status(404).send("Entity1 with Id '" + entity1Id + "' not found");
      }
      res.json(result);
    });

    // Delete a single entity1 with id
    router.delete("/:id", async (req: Request, res: Response) => {
      let entity1Id: number = parseInt(req.params.id);
      if (isNaN(entity1Id)) {
        res.status(400).send("URL token for entity1 Id is not a number");
        return;
      }
      var result = await controller.delete(entity1Id);
      if (!result) {
        res.status(404).send("Entity1 with Id '" + entity1Id + "' not found");
      }
      res.json(result);
    });

    app.use("/api/entity1s", router);
  }
}
