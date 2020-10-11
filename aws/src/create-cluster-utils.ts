const fs = require('fs');

export class CreateClusterUtils {
    
    public static run(): void {
        var args: string[] = process.argv.slice(2);
        switch (args[0]) {
            case "--ecs-params":
                this.setEcsParams(args[1], args[2], args[3], args[4], args[5], args[6]);
                break;
            case "--github-params":
                this.setGithubParams(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8]);
                break;
            default:
                throw new Error("Invalid parameter: '" + args[0] + "'");
        }  
    }

    private static setEcsParams(srcFileName: string, tarFileName: string, roleName: string, subnet1: string, subnet2: string, sgId: string): void {
        let data: string = fs.readFileSync(srcFileName).toString();
        data = data.replace("#ROLE_NAME#", roleName);
        data = data.replace("#SUBNET_1#", subnet1);
        data = data.replace("#SUBNET_2#", subnet2);
        data = data.replace("#SG_ID#", sgId);
        fs.writeFileSync(tarFileName, data);
    }
   
    private static setGithubParams(
        srcFileName: string,
        tarFileName: string,
        region: string,
        ecrRepository: string,
        taskDefinition: string,
        containerName: string,
        serviceName: string,
        clusterName: string): void {
        let data: string = fs.readFileSync(srcFileName).toString();
        data = data.replace("#REGION#", region);
        data = data.replace("#ECR_REPOSITORY#", ecrRepository);
        data = data.replace("#TASK_DEFINITION#", taskDefinition);
        data = data.replace("#CONTAINER_NAME#", containerName);
        data = data.replace("#SERVICE_NAME#", serviceName);
        data = data.replace("#CLUSTER_NAME#", clusterName);
        fs.writeFileSync(tarFileName, data);
    }
}
CreateClusterUtils.run();