import { MessageType } from "../../storage/entities/message";
import { StaticPool } from  "node-worker-threads-pool";
const physicalCpuCount = require('physical-cpu-count');

export class MessagesProcessor {

    private _staticPool: StaticPool<string, MessageType>;

    constructor () {
        // Init the thread pool (each call to 'this._staticPool.exec()' will
        // execute method 'processSync()' in async manner (i.e. in pool's thread).
        this._staticPool = new StaticPool<string, MessageType>({
            size: physicalCpuCount || 1,
            task: MessagesProcessor.processSync
        });
    }

    public async processAsync(messagePayload: string): Promise<MessageType> {
        // Execute method 'processSync()' in async manner (i.e. in pool's thread).
        return this._staticPool.exec(messagePayload);
    }    
    
    private static processSync(messagePayload: string): MessageType {
        for (let i = 0 ; i < messagePayload.length / 2; i++) {
            if (messagePayload[i] !== messagePayload[messagePayload.length - 1 - i]) {
                return "NoPalindrome";
            }
        }
        return "Palindrome";
    }
}