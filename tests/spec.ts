import { Message } from "../src/storage/entities/message";
const superagent = require("superagent");
var expect = require("chai").expect;

describe("REST API Tests", () => {
  
  // Clear the DB - before each run of this tests collection
  before(async () => {
    const getRes: Response = await superagent.get("http://localhost:8080/api/messages");
    let getResult: Message[] = <Message[]><any>getRes.body;
    let deletePromises = getResult.map((currMessage: Message) => {
        return superagent.delete("http://localhost:8080/api/messages/" + currMessage.id);
    });
    await Promise.all(deletePromises);
  });

  let payloads: string[] = ["123456", "12321", "abcdef", "abcba"];

  it("Create messages", async () => {
    for (var i = 0; i < payloads.length; i++) {
        const currRes: Response = await superagent.post("http://localhost:8080/api/messages")
                                                  .send({payload: payloads[i]});
        let currResult: Message = <Message><any>currRes.body;
        expect(currResult).to.include({payload: payloads[i]});
    }   
  });

  it("Retrieve all messages", async () => {
    const res: Response = await superagent.get("http://localhost:8080/api/messages");
    let result: Message[] = <Message[]><any>res.body;  
    expect(result.length).to.equal(payloads.length);  
    let resultPayloads = result.map((currMessage: Message) => {
        return currMessage.payload;
    }); 
    console.log("Retrieve all messages result payloads:", resultPayloads);
    expect(resultPayloads).to.have.all.members(payloads); 
  });
});