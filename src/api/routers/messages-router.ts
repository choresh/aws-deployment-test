import { Express, Router, Request, Response } from "express";

export class MessagesRouter {

  public static run(app: Express, router: Router): void {
 
    router.get("/", async (req: Request, res: Response) => {
       
      res.status(201).json({"msg" : "SUCCESS!"});
    });
  }  
}
