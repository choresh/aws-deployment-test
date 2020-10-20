import { Entity1 } from "../src/storage/entities/entity-1";
const superagent = require("superagent");
var expect = require("chai").expect;

const CONNECTION_RETRY_COUNT: number = 10;
const CONNECTION_RETRY_TIMEOUT_MS: number = 10000;

// Env variable 'SERVICE_HOST' defined in 'docker-compose.test.yml', the 'localhost' will
// be selected if run performed without the 'docker-compose.test.yml' (e.g. while
// developer runs the service and test locally, out of docker macine).
let serviceHost: string = process.env.SERVICE_HOST || "localhost";

describe("REST API Tests", () => {
  
  // Clear the DB - before each run of this tests collection
  before(async () => {
   
    console.log("Configured service host:", serviceHost);

    for (var i = 1; ; i++) {
      try {
        console.log("Connect to app's REST API started, attempt " + i + "/" + CONNECTION_RETRY_COUNT);
        const getRes: Response = await superagent.getAll("http://" + serviceHost + ":8080");
        console.log("Connect to app's REST API ended");
        break;
      } catch (err) {
        if (i === CONNECTION_RETRY_COUNT) {
          console.log("Connect to app's REST API failed, error:", err);
          throw err;
        }
        await new Promise((resolve, reject) => {
          setTimeout(() => {
            resolve();
          }, CONNECTION_RETRY_TIMEOUT_MS);
        }); 
      }
    }
  });

  it("Retrieve all entity1s", async () => {
    const res: Response = await superagent.getAll("http://" + serviceHost + ":8080");
    let result: Entity1[] = <Entity1[]><any>res.body;  
    console.log("Retrieve all entity1s result:", result);
  });
});