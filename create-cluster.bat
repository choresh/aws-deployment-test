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
SET TEMP_FILE_NAME=%AWS_TEMP_FOLDER%temp.txt
SET GITHUB_WORKFLOWS_FOLDER=.github\workflows/
SET ROLE_POLICY_FILE=%AWS_DATA_FOLDER%task-execution-assume-role.json
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

SET MSG=* Clear all resources (if exists) - started (may take few minutes...)
ECHO [201;93m%MSG%[0m
ecs-cli compose --project-name %PROJECT_NAME% service down --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% > nul 2>&1
ecs-cli down --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% --force > nul 2>&1
aws ecr delete-repository --repository-name %REPOSITORY_NAME% --region %REGION% --force > nul 2>&1
SET MSG=* Clear all resources (if exists) - ended
ECHO [201;93m%MSG%[0m

REM ================= 1st part - start ==============================
REM In this part we create AWS repository (if not exists yet).

SET MSG=* Get Repository info - started
ECHO [201;93m%MSG%[0m
aws ecr describe-repositories --repository-names %REPOSITORY_NAME% --region %REGION% --query repositories[0].repositoryUri > %TEMP_FILE_NAME% 2> nul
SET MSG=* Get Repository info - ended
ECHO [201;93m%MSG%[0m

IF NOT %errorlevel% == 0 (
    SET MSG=* Create repository - started
    ECHO [201;93m%MSG%[0m
    aws ecr create-repository --repository-name %REPOSITORY_NAME% --region %REGION% --query repository.repositoryUri > %TEMP_FILE_NAME%
    SET MSG=* Create repository - ended
    ECHO [201;93m%MSG%[0m
)

SET MSG=* Fetch Repository info - started
ECHO [201;93m%MSG%[0m
SET /P FOUND_REPOSITORY_URI= < %TEMP_FILE_NAME%
SET MSG=* Found Repository Uri: %FOUND_REPOSITORY_URI%
ECHO [201;93m%MSG%[0m
SET MSG=* Fetch Repository info - ended
ECHO [201;93m%MSG%[0m

REM ================= 1st part - end ==============================


REM ================= 2nd part - start ==============================
REM In this part we build docker image, and push it to our reposetory.

SET MSG=* Authenticate Docker to an Amazon ECR reposetory - started
ECHO [201;93m%MSG%[0m
aws ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %FOUND_REPOSITORY_URI% > nul
IF NOT %errorlevel% == 0 (
  SET ERR_MSG=* Authenticate Docker to an Amazon ECR reposetory - failed, error code: %errorlevel%
  GOTO END
)
SET MSG=* Authenticate Docker to an Amazon ECR reposetory - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Build - started (may take few minutes...)
ECHO [201;93m%MSG%[0m
ECHO =====================================================================
docker build -t %FOUND_REPOSITORY_URI% .
ECHO =====================================================================
SET MSG=* Build - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Push - started (may take few minutes...)
ECHO [201;93m%MSG%[0m
ECHO =====================================================================
docker push %FOUND_REPOSITORY_URI%
ECHO =====================================================================
SET MSG=* Push - ended
ECHO [201;93m%MSG%[0m

REM ================= 2nd part - end ==============================


REM ================= 3rd part - start ==============================
REM * In this part we create an AWS cluster with a fargate task. 
REM * More info - see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-cli-tutorial-ec2.html,
REM   and its sub chapters:
REM     * 'Installing the Amazon ECS CLI'.
REM     * 'Configuring the Amazon ECS CLI'.
REM     * 'Tutorial: Creating a Cluster with a Fargate Task Using the Amazon ECS CLI'.

SET MSG=* Create role (if not exists) - started
ECHO [201;93m%MSG%[0m
aws iam --region %REGION% create-role --role-name %ROLE_NAME% --assume-role-policy-document file://%ROLE_POLICY_FILE% > nul 2>&1
IF NOT %errorlevel% == 0 (
    IF NOT %errorlevel% == 254 (
        SET ERR_MSG=* Create role - failed, error code: %errorlevel%
        GOTO END
    )
)
SET MSG=* Create role (if not exists) - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Attch role policy - started
ECHO [201;93m%MSG%[0m
aws iam --region %REGION% attach-role-policy --role-name %ROLE_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy > nul
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Attch role policy - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Attch role policy - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Create ECS CLI profile - started
ECHO [201;93m%MSG%[0m
ecs-cli configure profile --access-key %AWS_ACCESS_KEY_ID% --secret-key %AWS_SECRET_ACCESS_KEY% --profile-name %PROFILE_NAME% > nul
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create ECS CLI profile - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create ECS CLI profile - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Create cluster configuration - started
ECHO [201;93m%MSG%[0m
ecs-cli configure --cluster %CLUSTER_NAME% --default-launch-type FARGATE --config-name %APP_NAME% --region %REGION% > nul
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create cluster configuration - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create cluster configuration - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Create cluster - started (may take few minutes...)
ECHO [201;93m%MSG%[0m
ECHO =====================================================================
ecs-cli up --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% --force
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create cluster configuration - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create cluster - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Get VPC info - started
ECHO [201;93m%MSG%[0m
aws cloudformation list-stack-resources --stack-name amazon-ecs-cli-setup-aws-deployment-test --region %REGION% --query StackResourceSummaries[?(@.LogicalResourceId=='Vpc')].PhysicalResourceId > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get VPC info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get VPC info - ended
ECHO [201;93m%MSG%[0m

REM * Get value of 2nd line at file %TEMP_FILE_NAME%.
REM * Strip redundent parts at start/end of the found string.
SET MSG=* Fetch VPC info - started
ECHO [201;93m%MSG%[0m
SET FOUND_VPC_ID_LINE=
FOR /F "skip=1 delims=" %%i IN (%TEMP_FILE_NAME%) DO IF NOT DEFINED FOUND_VPC_ID_LINE SET FOUND_VPC_ID_LINE=%%i
SET FOUND_VPC_ID=%FOUND_VPC_ID_LINE:~5,21%
SET MSG=* Found VPC Id: %FOUND_VPC_ID%
ECHO [201;93m%MSG%[0m
SET MSG=* Fetch VPC info - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Get Subnets info - started
ECHO [201;93m%MSG%[0m
aws ec2 describe-subnets --filters "Name=vpc-id,Values=%FOUND_VPC_ID%" --region %REGION% --query Subnets[*].SubnetId > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get Subnets info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get Subnets info - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Fetch Subnets info - started
ECHO [201;93m%MSG%[0m

REM * Get value of **2ND** line at file %TEMP_FILE_NAME%.
REM * Strip redundent parts at start/end of the found string.
SET FOUND_SUBNET_1_LINE=
FOR /F "skip=1 delims=" %%i IN (%TEMP_FILE_NAME%) DO IF NOT DEFINED FOUND_SUBNET_1_LINE SET FOUND_SUBNET_1_LINE=%%i
SET FOUND_SUBNET_1_ID=%FOUND_SUBNET_1_LINE:~5,24%%
SET MSG=* Found Subnet 1 Id: %FOUND_SUBNET_1_ID%
ECHO [201;93m%MSG%[0m

REM * Get value of **3RD** line at file %TEMP_FILE_NAME%.
REM * Strip redundent parts at start/end of the found string.
SET FOUND_SUBNET_2_LINE=
FOR /F "skip=2 delims=" %%i IN (%TEMP_FILE_NAME%) DO IF NOT DEFINED FOUND_SUBNET_2_LINE SET FOUND_SUBNET_2_LINE=%%i
SET FOUND_SUBNET_2_ID=%FOUND_SUBNET_2_LINE:~5,24%%
SET MSG=* Found Subnet 2 Id: %FOUND_SUBNET_2_ID%
ECHO [201;93m%MSG%[0m

SET MSG=* Fetch Subnets info - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Get the default security group ID for the VPC - started
ECHO [201;93m%MSG%[0m
aws ec2 describe-security-groups --filters Name=vpc-id,Values=%FOUND_VPC_ID% --region %REGION% --query SecurityGroups[0].GroupId > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get the default security group ID for the VPC - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get the default security group ID for the VPC - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Fetch SG info - started
ECHO [201;93m%MSG%[0m
SET /P FOUND_SG_ID= < %TEMP_FILE_NAME%
SET MSG=* Found SG Id: %FOUND_SG_ID%
ECHO [201;93m%MSG%[0m
SET MSG=* Fetch SG info - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Add a security group rule to allow inbound access on port %PORT% - started
ECHO [201;93m%MSG%[0m
aws ec2 authorize-security-group-ingress --group-id %FOUND_SG_ID% --protocol tcp --port %PORT% --cidr 0.0.0.0/0 --region %REGION% > nul 2>&1
IF NOT %errorlevel% == 0 (
    IF NOT %errorlevel% == 254 (
        SET ERR_MSG=* Add a security group rule to allow inbound access on port %PORT% - failed, error code: %errorlevel%
        GOTO END
    )
)
SET MSG=* Add a security group rule to allow inbound access on port %PORT% - ended
ECHO [201;93m%MSG%[0m

REM SET MSG=* Set ECS params - started
REM CHO [201;93m%MSG%[0m
REM SETLOCAL EnableDelayedExpansion
REM FOR /f "Tokens=* Delims=" %%A IN (%ECS_PARAMS_TEMPLATE_FILE_NAME%) DO SET ECS_PARAMS_TEMPLATE=!ECS_PARAMS_TEMPLATE!%%A
REM SET MSG=*ECS_PARAMS_TEMPLATE: %ECS_PARAMS_TEMPLATE%
REM ECHO [201;93m%MSG%[0m
REM %ECS_PARAMS_TEMPLATE% > %ECS_PARAMS_FILE_NAME%
REM SET MSG=* Set ECS params - ended
REM ECHO [201;93m%MSG%[0m

SET MSG=* Set ECS params - started
ECHO [201;93m%MSG%[0m
CALL node %MY_UTILS_PATH% --ecs-params %ECS_PARAMS_TEMPLATE_FILE_NAME% %ECS_PARAMS_FILE_NAME% %ROLE_NAME% %FOUND_SUBNET_1_ID% %FOUND_SUBNET_2_ID% %FOUND_SG_ID%
SET MSG=* Set ECS params - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Deploy the compose file to the cluster - started (may take few minutes...)
ECHO [201;93m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --ecs-params %ECS_PARAMS_FILE_NAME% --project-name %PROJECT_NAME% service up --create-log-groups --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Deploy the compose file to the cluster - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Deploy the compose file to the cluster - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Display info about cluster's running containers - started
ECHO [201;93m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --project-name %PROJECT_NAME% service ps --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Display info about cluster's running containers - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Display info about cluster's running containers - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Scale the tasks on the cluster - started
ECHO [201;93m%MSG%[0m
ecs-cli compose --project-name %PROJECT_NAME% service scale 2 --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Scale the tasks on the cluster - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Scale the tasks on the cluster - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Display info about cluster's running containers, after scale - started
ECHO [201;93m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --project-name %PROJECT_NAME% service ps --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Display info about cluster's running containers, after scale - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Display info about cluster's running containers, after scale - ended
ECHO [201;93m%MSG%[0m

REM ================= 3rd part - end ==============================


REM ================= 4th part - start ==============================
REM * In this part we create a GitHub workflow, to soppurt CI/CD.
REM * With this workflow, an automatic build and push of docker image into the AWS reposetory will be executed on each GitHub push.
REM * More info - see https://medium.com/javascript-in-plain-english/deploy-your-node-app-to-aws-container-service-via-github-actions-build-a-pipeline-c114adeb8903,
REM   and its sub chapters:
REM     * 'Creating an IAM user for GitHub Actions'.
REM     * 'Setting up GitHub Actions'.

SET MSG=* Get Task Definition info - started
ECHO [201;93m%MSG%[0m
aws ecs describe-services --services %SERVICE_NAME% --region %REGION% --cluster %CLUSTER_NAME% --query services[0].taskDefinition > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get Task Definition info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get Task Definition info - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Fetch Task Definition info - started
ECHO [201;93m%MSG%[0m
SET /P FOUND_TASK_DEFINITION= < %TEMP_FILE_NAME%
SET MSG=* Found Task Definition: %FOUND_TASK_DEFINITION%
ECHO [201;93m%MSG%[0m
FOR /f "tokens=1,2 delims=/" %%a IN (%FOUND_TASK_DEFINITION%) DO (
	SET SHORT_TASK_DEFINITION=%%b
)
SET MSG=* Short Task Definition: %SHORT_TASK_DEFINITION%
ECHO [201;93m%MSG%[0m
SET MSG=* Fetch Task Definition info - ended
ECHO [201;93m%MSG%[0m

SET MSG=* Set GitHub params - started
ECHO [201;93m%MSG%[0m
CALL node %MY_UTILS_PATH% --github-params %GITHUB_PARAMS_TEMPLATE_FILE_NAME% %GITHUB_PARAMS_FILE_NAME% %REGION% %ECR_REPOSITORY% %SHORT_TASK_DEFINITION% %CONTAINER_NAME% %SERVICE_NAME% %CLUSTER_NAME%
SET MSG=* Set GitHub params - ended
ECHO [201;93m%MSG%[0m

REM ================= 4th part - end ==============================


REM ================= termination part - start ==============================

:END

IF DEFINED ERR_MSG (
    ECHO [201;93m%ERR_MSG%[0m
)

SET MSG=* The entire sequence has ended
ECHO [201;93m%MSG%[0m

PAUSE

@ECHO ON

REM ================= termination part - end ==============================