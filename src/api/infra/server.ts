import express, { Express } from "express";
import Router from "express-promise-router";
import { json } from "body-parser";
import console from "console";
import { Entity1Router } from "../routers/entity-1-router";

const PORT = 8080;

export class Server {
  private static _app: Express = express();
  private static _router = Router();

  public static async run(): Promise<void> {

    // Parse requests of content-type - application/json
    this._app.use(json());
  
    // Enable easy conversion from 'Promise' to express midleware
    this._app.use(this._router);

    // Attach routers (currently - only one)
    Entity1Router.run(this._app, this._router);
    
    // Start listen for requests
    return new Promise((resolve, reject) => {
      this._app.listen(PORT, () => {
        console.log(`Server is running on port ${PORT}.`);
        resolve();
      });
    });
  }
}
