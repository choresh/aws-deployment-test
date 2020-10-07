const fs = require('fs');

interface FindResult {
    val: string;
    endIndex: number;
}

export class CreateClusterUtils {
    
    public static run(): void {
        var args: string[] = process.argv.slice(2);
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
            case "--containers-info":
                this.extractContainersInfo(args[1], args[2]);
                break;
            case "--repository-info":
                this.extractRepositoryInfo(args[1], args[2]);
                break;
            case "--github-params":
                this.setGithubParams(args);
                break;
            default:
                throw new Error("Invalid parameter: '" + args[0] + "'");
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

    private static extractRepositoryInfo(srcFileName: string, tarFileName: string): void {
        let srcData: string = fs.readFileSync(srcFileName).toString();
        let repositoryUriResult: FindResult = this.findVal(srcData, "\"repositoryUri\": \"", "\"");
        let tarData: string = "REPOSITORY_URI:" + repositoryUriResult.val;
        fs.writeFileSync(tarFileName, tarData);
    } 

    private static extractContainersInfo(srcFileName: string, tarFileName: string): void {
        let srcData: string = fs.readFileSync(srcFileName).toString().trim();
        console.log("===================================================");
        console.log(srcData);
        console.log("===================================================");
        let lines: string[] = srcData.split("\n");
        let taskIds: string[] = [];
        for (let i = 1; i< lines.length; i++) {
            let currLine: string = lines[i];
            taskIds.push(this.findVal(currLine, "", "/").val);
        };
        let tarData: string = "";
        taskIds.forEach((currTaskId: string) => {
            if (tarData) {
                tarData += " ";
            } 
            tarData += currTaskId;
        });
        tarData = "TASK_IDS:" + tarData;
        fs.writeFileSync(tarFileName, tarData);
    } 

    private static setEcsParams(srcFileName: string, tarFileName: string, roleName: string, subnet1: string, subnet2: string, sgId: string): void {
        let data: string = fs.readFileSync(srcFileName).toString();
        data = data.replace("#ROLE_NAME#", roleName);
        data = data.replace("#SUBNET_1#", subnet1);
        data = data.replace("#SUBNET_2#", subnet2);
        data = data.replace("#SG_ID#", sgId);
        fs.writeFileSync(tarFileName, data);
    } 

    // #REGION#
    // #ECR_REPOSITORY#
    // #TASK_DEFINITION#
    // #CONTAINER_NAME#
    // #SERVICE_NAME#
    // #CLUSTER_NAME#
    private static setGithubParams(args: string[]): void {
        let data: string = fs.readFileSync(args[1]).toString();
        data = data.replace("#REGION#", args[3]);
        data = data.replace("#ECR_REPOSITORY#", args[4]);
        data = data.replace("#TASK_DEFINITION#", args[5]);
        data = data.replace("#CONTAINER_NAME#", args[6]);
        data = data.replace("#SERVICE_NAME#", args[7]);
        data = data.replace("#CLUSTER_NAME#", args[8]);
        fs.writeFileSync(args[2], data);
    } 
    
    private static findVal(data: string, key: string, endMarker: string, startIndex?: number): FindResult {
        let start: number = key ? data.indexOf(key, startIndex) : 0;
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