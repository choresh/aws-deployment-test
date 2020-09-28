const superagent = require("superagent");
var expect = require("chai").expect;


describe("REST API Tests", () => {  
 
  it("Test", async () => {
    const res: Response = await superagent.get("http://localhost:8080");
    console.log(res.body);
  });
});
