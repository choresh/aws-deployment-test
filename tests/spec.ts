import { Entity1 } from "../src/storage/entities/entity-1";
const superagent = require("superagent");
var expect = require("chai").expect;

describe("REST API Tests", () => {
  
  // Clear the DB - before each run of this tests collection
  before(async () => {
    const getRes: Response = await superagent.get("http://localhost:8080/api/entity1s");
    let getResult: Entity1[] = <Entity1[]><any>getRes.body;
    let deletePromises = getResult.map((currEntity1: Entity1) => {
        return superagent.delete("http://localhost:8080/api/entity1s/" + currEntity1.id);
    });
    await Promise.all(deletePromises);
  });

  let payloads: string[] = ["AAAAA", "BBBBB", "CCCCC", "DDDDD"];

  it("Create entity1s", async () => {
    for (var i = 0; i < payloads.length; i++) {
        const currRes: Response = await superagent.post("http://localhost:8080/api/entity1s")
                                                  .send({payload: payloads[i]});
        let currResult: Entity1 = <Entity1><any>currRes.body;
        expect(currResult).to.include({payload: payloads[i]});
    }   
  });

  it("Retrieve all entity1s", async () => {
    const res: Response = await superagent.get("http://localhost:8080/api/entity1s");
    let result: Entity1[] = <Entity1[]><any>res.body;  
    expect(result.length).to.equal(payloads.length);  
    let resultPayloads = result.map((currEntity1: Entity1) => {
        return currEntity1.payload;
    }); 
    console.log("Retrieve all entity1s result payloads:", resultPayloads);
    expect(resultPayloads).to.have.all.members(payloads); 
  });
});