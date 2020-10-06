const fs = require('fs');

interface FindResult {
    val: string;
    endIndex: number;
}

export class CreateClusterUtils {
    
    public static run(): void {
        var args = process.argv.slice(2);
        switch (args[0]) {
            case "--vpc-info":
                this.extractVpcInfo(args[1], args[2]);
                break;
            case "--sg-info":
                this.extractSgInfo(args[1], args[2]);
                break;
            case "--ecs-params":
                this.setEcsParams(args[1], args[2], args[3], args[4], args[5], args[6]);
                break;
            default:
                throw new Error("Invalid parameter(s)");
        }  
    }

    private static extractVpcInfo(srcFileName: string, tarFileName: string): void {
        let srcData: string = fs.readFileSync(srcFileName).toString();        
        let errorResult: FindResult = this.findVal(srcData, "\"Failure event\" reason=\"", ".");
        let tarData: string = "";
        if (errorResult.val) {
            tarData += "ERROR_MSG:" + errorResult.val;
        } else {
            let vpcIdResult: FindResult = this.findVal(srcData, "VPC created: ", "\n");
            let subnetResult1: FindResult = this.findVal(srcData, "Subnet created: ", "\n", vpcIdResult.endIndex);
            let subnetResult2: FindResult = this.findVal(srcData, "Subnet created: ", "\n", subnetResult1.endIndex);
            tarData += "VPC_ID:" + vpcIdResult.val + "\n";
            tarData += "SUBNET_1:" + subnetResult1.val + "\n";
            tarData += "SUBNET_2:" + subnetResult2.val;
        }
        fs.writeFileSync(tarFileName, tarData);
    } 

    private static extractSgInfo(srcFileName: string, tarFileName: string): void {
        let srcData: string = fs.readFileSync(srcFileName).toString();
        let sgIdResult: FindResult = this.findVal(srcData, "\"GroupId\": \"", "\"");
        let tarData: string = "SG_ID:" + sgIdResult.val;
        fs.writeFileSync(tarFileName, tarData);
    } 

    private static setEcsParams(srcFileName: string, tarFileName: string, roleName: string, subnet1: string, subnet2: string, sgId: string): void {
        let data: string = fs.readFileSync(srcFileName).toString();
        data = data.replace("ROLE_NAME", roleName);
        data = data.replace("SUBNET_1", subnet1);
        data = data.replace("SUBNET_2", subnet2);
        data = data.replace("SG_ID", sgId);
        fs.writeFileSync(tarFileName, data);
    } 
    
    private static findVal(data: string, key: string, endMarker: string, startIndex?: number): FindResult {
        let start: number = data.indexOf(key, startIndex);
        let end: number = -1;
        let val: string;
        if (start !== -1) {
            end = data.indexOf(endMarker, start + key.length);
            if (end !== -1) {
                val = data.substr(start + key.length, end - start - key.length);
            }
        }
        return {
            val: val,
            endIndex: end
        };
    } 
}
CreateClusterUtils.run();