@ECHO OFF

REM =============================================================================================
REM * More about those Access Keys - see the following chapters in 'README.md' file of this package:
REM     * 'At AWS - create IAM user, and get correspond access keys'.
REM     * 'Configure our batch file'.
REM * IMPORTENT:
REM     * Never expose those Access Keys!!!
REM     * Use them only at private environment (e.g. your local machine)!!!
REM     * If they became public - be sure that some automatic scanners will detect them, and someone will try to use your credentials in order to consume AWS resources on you budget!!!
REM     * Such an exposure may happened by mistake, e.g. if you push this file to public GitHub, while those values defined in it!!!
SET AWS_ACCESS_KEY_ID=
SET AWS_SECRET_ACCESS_KEY=
REM =============================================================================================

SET APP_NAME=aws-deployment-test
SET REGION=us-east-2
SET PORT=8080

SET AWS_DATA_FOLDER=aws/data/
SET AWS_TEMP_FOLDER=aws/temp/
SET GITHUB_WORKFLOWS_FOLDER=.github\workflows/
SET ROLE_INFO_FILE_NAME=%AWS_TEMP_FOLDER%role-info.json
SET ROLE_POLICY_FILE=%AWS_DATA_FOLDER%task-execution-assume-role.json
SET VPC_INFO_FILE_NAME=%AWS_TEMP_FOLDER%vpc-info.txt
SET VPC_INFO_PROCESSED_FILE_NAME=%AWS_TEMP_FOLDER%vpc-info-processed.txt
SET SG_INFO_FILE_NAME=%AWS_TEMP_FOLDER%sg-info.json
SET SG_INFO_PROCESSED_FILE_NAME=%AWS_TEMP_FOLDER%sg-info-processed.txt
SET DELETED_REPOSITORY_INFO_FILE_NAME=%AWS_TEMP_FOLDER%deleted-repository-info.json
SET GET_ROLE_INFO_FILE_NAME=%AWS_TEMP_FOLDER%get-role-info.json
SET REPOSITORY_INFO_FILE_NAME=%AWS_TEMP_FOLDER%repository-info.json
SET REPOSITORY_INFO_PROCESSED_FILE_NAME=%AWS_TEMP_FOLDER%repository-info-processed.txt
SET CONTAINERS_INFO_FILE_NAME=%AWS_TEMP_FOLDER%containers-info.txt
SET CONTAINERS_INFO_PROCESSED_FILE_NAME=%AWS_TEMP_FOLDER%containers-info-processed.txt
SET ECS_PARAMS_TEMPLATE_FILE_NAME=%AWS_DATA_FOLDER%ecs-params-template.yml
SET ECS_PARAMS_FILE_NAME=%AWS_TEMP_FOLDER%ecs-params.yml
SET GITHUB_PARAMS_TEMPLATE_FILE_NAME=%GITHUB_WORKFLOWS_FOLDER%deploy-to-aws-template.yml
SET GITHUB_PARAMS_FILE_NAME=%GITHUB_WORKFLOWS_FOLDER%deploy-to-aws.yml
SET MY_UTILS_PATH="%~dp0build/aws/src/create-cluster-utils.js"

SET ROLE_NAME=%APP_NAME%
SET PROFILE_NAME=%APP_NAME%
SET STACK_NAME=%APP_NAME%
SET REPOSITORY_NAME=%APP_NAME%
SET CLUSTER_NAME=%APP_NAME%
SET ECR_REPOSITORY=%APP_NAME%
SET SERVICE_NAME=%APP_NAME%
SET CONTAINER_NAME=%APP_NAME%
SET PROJECT_NAME=%APP_NAME%
SET CLUSTER_CONFIG_NAME=%APP_NAME%

ECHO Clear all resources (if exists) - started
ecs-cli compose --project-name %PROJECT_NAME% service down --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ecs-cli down --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% --force
aws ecr delete-repository --repository-name %REPOSITORY_NAME% --region %REGION% --force > %DELETED_REPOSITORY_INFO_FILE_NAME%
ECHO Clear all resources (if exists) - ended

REM ================= 1st part - start ==============================
REM In this part we create AWS repository (if not exists yet).

ECHO Get Repository info - started
aws ecr describe-repositories --repository-names %REPOSITORY_NAME% --region %REGION% > %REPOSITORY_INFO_FILE_NAME%
ECHO Get Repository info - ended

IF NOT %errorlevel% == 0 (
    ECHO Create repository - started
    aws ecr create-repository --repository-name %REPOSITORY_NAME% --region %REGION% > %REPOSITORY_INFO_FILE_NAME%
    ECHO Create repository - ended 
)

ECHO Fetch Repository info - started
CALL node %MY_UTILS_PATH% --repository-info %REPOSITORY_INFO_FILE_NAME% %REPOSITORY_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims==" %%A in (%REPOSITORY_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
ECHO Fetch Repository info - ended



REM ================= 1st part - end ==============================


REM ================= 2nd part - start ==============================
REM In this part we then build docker image, and push it to our reposetory.

ECHO Authenticate Docker to an Amazon ECR reposetory - start
aws ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %FOUND_REPOSITORY_URI%
ECHO Authenticate Docker to an Amazon ECR reposetory - end

ECHO Build - started
docker build -t %FOUND_REPOSITORY_URI% .
ECHO Build - ended

ECHO Push - started
docker push %FOUND_REPOSITORY_URI%
ECHO Push - ended
PAUSE

REM ================= 2nd part - end ==============================


REM ================= 3rd part - start ==============================
REM * In this part we create an AWS cluster with a fargate task. 
REM * More info - see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-cli-tutorial-ec2.html,
REM   and its sub chapters:
REM     * 'Installing the Amazon ECS CLI'.
REM     * 'Configuring the Amazon ECS CLI'.
REM     * 'Tutorial: Creating a Cluster with a Fargate Task Using the Amazon ECS CLI'.

ECHO Create role (if not exists) - sarted
aws iam --region %REGION% create-role --role-name %ROLE_NAME% --assume-role-policy-document file://%ROLE_POLICY_FILE% > %ROLE_INFO_FILE_NAME%
ECHO Create role (if not exists) - ended

ECHO Attch role policy - started
aws iam --region %REGION% attach-role-policy --role-name %ROLE_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
ECHO Attch role policy - ended

ECHO Create ECS CLI profile - started
ecs-cli configure profile --access-key %AWS_ACCESS_KEY_ID% --secret-key %AWS_SECRET_ACCESS_KEY% --profile-name %PROFILE_NAME%
ECHO Create ECS CLI profile - ended

ECHO Create cluster configuration - started
ecs-cli configure --cluster %APP_NAME% --default-launch-type FARGATE --config-name %APP_NAME% --region %REGION%
ECHO Create cluster configuration - ended

ECHO Create cluster - started
ecs-cli up --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% > %VPC_INFO_FILE_NAME% --force
ECHO Create cluster - ended

ECHO Fetch VPC info - started
CALL node %MY_UTILS_PATH% --vpc-info %VPC_INFO_FILE_NAME% %VPC_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims==" %%A in (%VPC_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
IF DEFINED FOUND_ERROR_MSG (
    ECHO Fetch VPC info - failed, reason: %FOUND_ERROR_MSG%
    GOTO END
)
ECHO Fetch VPC info - ended

ECHO Retrieve the default security group ID for the VPC - started
aws ec2 describe-security-groups --filters Name=vpc-id,Values=%FOUND_VPC_ID% --region %REGION% > %SG_INFO_FILE_NAME%
ECHO Retrieve the default security group ID for the VPC - ended

ECHO Fetch SG info - started
CALL node %MY_UTILS_PATH% --sg-info %SG_INFO_FILE_NAME% %SG_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims==" %%A in (%SG_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
ECHO Fetch SG info - ended

ECHO Add a security group rule to allow inbound access on port %PORT% - started
aws ec2 authorize-security-group-ingress --group-id %FOUND_SG_ID% --protocol tcp --port %PORT% --cidr 0.0.0.0/0 --region %REGION%
ECHO Add a security group rule to allow inbound access on port %PORT% - ended

ECHO Set ESC params - started
CALL node %MY_UTILS_PATH% --ecs-params %ECS_PARAMS_TEMPLATE_FILE_NAME% %ECS_PARAMS_FILE_NAME% %ROLE_NAME% %FOUND_SUBNET_1% %FOUND_SUBNET_2% %FOUND_SG_ID%
ECHO Set ESC params - ended

ECHO Deploy the compose file to the cluster - started
ecs-cli compose --ecs-params %ECS_PARAMS_FILE_NAME% --project-name %PROJECT_NAME% service up --create-log-groups --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO Deploy the compose file to the cluster - ended

ECHO View the running containers on a cluster - started
ecs-cli compose --project-name %PROJECT_NAME% service ps --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% > %CONTAINERS_INFO_FILE_NAME%
ECHO View the running containers on a cluster - ended

ECHO Fetch Containers info - started
CALL node %MY_UTILS_PATH% --containers-info %CONTAINERS_INFO_FILE_NAME% %CONTAINERS_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims==" %%A in (%CONTAINERS_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
ECHO Fetch Containers info - ended

REM ECHO View the container logs - started
REM ecs-cli logs --task-id %FOUND_TASK_IDS% --follow --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
REM ECHO View the container logs - end

ECHO Scale the tasks on the cluster - started
ecs-cli compose --project-name %PROJECT_NAME% service scale 2 --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO Scale the tasks on the cluster - ended

ECHO View the running containers on a cluster (after scale) - started
ecs-cli compose --project-name %PROJECT_NAME% service ps --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% > %CONTAINERS_INFO_FILE_NAME%
ECHO View the running containers on a cluster (after scale) - end

ECHO Fetch Containers info (after scale) - started
CALL node %MY_UTILS_PATH% --containers-info %CONTAINERS_INFO_FILE_NAME% %CONTAINERS_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims==" %%A in (%CONTAINERS_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_2_%%A=%%B
)
ECHO Fetch Containers info (after scale) - ended

REM FOR %%A in (%FOUND_2_TASK_IDS%) do (
REM    ECHO CURR_FOUND_TASK_ID '%%A'
REM    ECHO View container logs - started
REM    ecs-cli logs --task-id %CURR_FOUND_TASK_ID% --follow --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
REM    ECHO View container logs - end
REM )

REM ================= 3rd part - end ==============================


REM ================= 4th part - start ==============================
REM * In this part we create a GitHub workflow, to soppurt CI/CD.
REM * With this workflow, an automatic build and push of docker image into the AWS reposetory will be executed on each GitHub push.
REM * More info - see https://medium.com/javascript-in-plain-english/deploy-your-node-app-to-aws-container-service-via-github-actions-build-a-pipeline-c114adeb8903,
REM   and its sub chapters:
REM     * 'Creating an IAM user for GitHub Actions'.
REM     * 'Setting up GitHub Actions'.

ECHO Set GitHub params - started
CALL node %MY_UTILS_PATH% --github-params %GITHUB_PARAMS_TEMPLATE_FILE_NAME% %GITHUB_PARAMS_FILE_NAME% %REGION% %ECR_REPOSITORY% %FOUND_TASK_DEFINITION% %CONTAINER_NAME% %SERVICE_NAME% %CLUSTER_NAME%
ECHO Set GitHub params - ended

REM ================= 4th part - end ==============================

:END
PAUSE
@ECHO ON