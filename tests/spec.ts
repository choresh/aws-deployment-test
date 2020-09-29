const superagent = require("superagent");
var expect = require("chai").expect;

const CONNECTION_RETRY_COUNT: number = 10;
const CONNECTION_RETRY_TIMEOUT_MS: number = 2000;

// Env variable 'SERVICE_HOST' defined in 'docker-compose.test.yml', the 'localhost' will
// be selected if run performed without the 'docker compose' command (e.g. while
// developer runs the service locally, out of docker macine).
const host: string = process.env.SERVICE_HOST || "localhost"; 
const baseUrl: string = "http://" + host + ":8085";

async function waitforService(): Promise<void> {
  console.log("Tests started, service base URL: '" + baseUrl + "'");    
  return new Promise(async (resolve, reject)  => {
    // * Do some attempts to connect to the service (in some cases need to
    //   wait until the service (actually - postgress DB) is up, e.g. if entire creation
    //   of the services done via 'docker-compose.yml').
    // * TODO: this is temp solution, a better one will be to solve the synchronization
    //   issue at the deployment mechanizem (i.e. at 'dockerfile' and/or 'docker-compose.yml'
    //   files).
    for (var i = 1; ; i++) {
      try {
        console.log("Connect to service started, attempt " + i + "/" + CONNECTION_RETRY_COUNT);
        const res: Response = await superagent.get(baseUrl);
        console.log("Connect to service ended");
        resolve();
        return;
      } catch (err) {
        console.log("MESSAGE:", err.message)
        var isConnectionFailure: boolean = err.message && ((<string>err.message).startsWith("connect ECONNREFUSED"));
        if ((i === CONNECTION_RETRY_COUNT) || !isConnectionFailure) {
          console.log("Connect to service failed, error:", err);
          reject("Connect to service failed, reason: " + err.message);
          return;
        }
        await new Promise((resolve, reject) => {
          setTimeout(() => {
            resolve();
          }, CONNECTION_RETRY_TIMEOUT_MS);
        });  
      }             
    }   
  });
}

describe("REST API Tests", () => {  
   
  before(async () => {
    await waitforService();
  });

  it("Test", async () => {
    const res: Response = await superagent.get(baseUrl);
    console.log(res.body);
  });
});
