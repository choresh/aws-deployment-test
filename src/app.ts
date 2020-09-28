import { Server } from "./api/infra/server";
import { Db } from "./storage/infra/db";

class App {
  public static run(): void {
    Db.run()
      .then(() => {
        return Server.run();
      })
      .catch((err) => {
        console.error(err);
      });
  }
}
App.run();
