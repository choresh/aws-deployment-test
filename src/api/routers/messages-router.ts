import { Express, Router, Request, Response } from "express";
import { MessagesController } from "../../bl/controllers/messages-controller";
import { Message } from "../../storage/entities/message";

export class MessagesRouter {

  public static run(app: Express, router: Router): void {
    var controller: MessagesController = new MessagesController();

    // Create a new message
    router.post("/", async (req: Request, res: Response) => {
      if (!req.body.payload) {
        res.status(400).send("Body property 'payload' is missing");
        return;
      }
      const message = new Message();
      message.payload = req.body.payload;
      var result = await controller.create(message);     
      res.status(201).json(result);
    });

    // Retrieve all messages
    router.get("/", async (req: Request, res: Response) => {
      var result = await controller.getAll();
      res.json(result);
    });

    // Retrieve a single message with id
    router.get("/:id", async (req: Request, res: Response) => {
      let messageId: number = parseInt(req.params.id);
      if (isNaN(messageId)) {
        res.status(400).send("URL token for message Id is not a number");
        return;
      }
      var result = await controller.get(messageId);
      if (!result) {
        res.status(404).send("Message with Id '" + messageId + "' not found");
      }
      res.json(result);
    });

    // Update a single message with id
    router.put("/:id", async (req: Request, res: Response) => {
      let messageId: number = parseInt(req.params.id);
      if (isNaN(messageId)) {
        res.status(400).send("URL token for message Id is not a number");
        return;
      }
      if (!req.body.payload) {
        res.status(400).send("Body property 'payload' is missing");
        return;
      }
      let message = new Message();
      message.payload = req.body.payload;
      var result = await controller.update(messageId, message);
      if (!result) {
        res.status(404).send("Message with Id '" + messageId + "' not found");
      }
      res.json(result);
    });

    // Delete a single message with id
    router.delete("/:id", async (req: Request, res: Response) => {
      let messageId: number = parseInt(req.params.id);
      if (isNaN(messageId)) {
        res.status(400).send("URL token for message Id is not a number");
        return;
      }
      var result = await controller.delete(messageId);
      if (!result) {
        res.status(404).send("Message with Id '" + messageId + "' not found");
      }
      res.json(result);
    });

    app.use("/api/messages", router);
  }
}
