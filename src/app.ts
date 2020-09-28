import { Server } from "./api/infra/server";

class App {
  public static run(): void {
    Server.run()
      .then(() => {
        console.log("Server is up.")
      })
      .catch((err) => {
        console.error(err);
      });
  }
}
App.run();
