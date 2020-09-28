import { Express, Router, Request, Response } from "express";
import { FindManyOptions } from "typeorm";
import { MessagesController } from "../../bl/controllers/messages-controller";
import { Message, MessageType } from "../../storage/entities/message";
import ParsedQs from "qs";

export class MessagesRouter {

  public static run(app: Express, router: Router): void {
    var controller: MessagesController = new MessagesController();

    // Create a new message
    router.post("/", async (req: Request, res: Response) => {
      if (req.body.type) {
        res.status(400).send("Body property 'type' is not allowed");
        return;
      }
      if (!req.body.payload) {
        res.status(400).send("Body property 'payload' is missing");
        return;
      }
      const message = new Message();
      message.payload = req.body.payload;
      var result = await controller.create(message);     
      res.status(201).json(result);
    });

    // * Retrieve all messages (with/without query).
    // * Currenty, the supported query syntax is very basic (only '?sort=date:desc' or '?sort=date:asc').
    router.get("/", async (req: Request, res: Response) => {
      let options: FindManyOptions<Message>;
      try {
        options = this.getOptions(req.query);
      } catch (err) {
        res.status(400).send(err.message);
        return;
      }
      var result = await controller.getAll(options);
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
      if (req.body.type) {
        res.status(400).send("Body property 'type' is not allowed");
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

  // * Convert query from REST API terms ('ParsedQs') to DB terms ('FindManyOptions').
  // * Currenty, the supported query syntax is very basic (only '?sort=date:desc' / '?sort=date:asc'
  //   and/or '?type=Palindrome' / '?type=NoPalindrome').
  private static getOptions(
    query: ParsedQs.ParsedQs
  ): FindManyOptions<Message> {
    let options: FindManyOptions<Message>;
    if (Object.keys(query).length !== 0) {
      options = {};
      if (query.sort) {
        var parmTokens: string[] = (<string>query.sort).split(":");
        if (parmTokens[0] !== "date") {
          throw new Error("Value for 'sort' can only be 'date'");
        }
        var order: "ASC" | "DESC";
        switch (parmTokens[1]) {
          case "asc":
            order = "ASC";
            break;
          case "desc":
            order = "DESC";
            break;
          default:
            throw new Error("Value for 'sort' should ended with ':asc' or ':desc'");
        }
        options.order = {
            date: order
        };
      }
      if (query.type) {
        let type: MessageType;
        switch (query.type) {
          case "NoPalindrome":
            type = "NoPalindrome";
            break;
          case "Palindrome":
            type = "Palindrome";
            break;
          default:
            throw new Error("Value for 'type' can only be 'Palindrome' or 'NoPalindrome'");
        }
        options.where = {
            type: type
        }
      }
      if (Object.keys(options).length === 0) {
        throw new Error("Only 'sort' and/or 'type' parameters are allowed"); 
      }
    }
    return options;
  }
}
