@ECHO OFF

REM ================= Section #1 - Secret Keys - start ==============================
REM * In this section we store credintials required for the AWS/ECS CLI's.
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
REM
REM ================= Section #1 - Secret Keys - end ==============================


REM ================= Section #2 - Settings - start ==============================
REM In this section we define all required settings varaibles.

REM Define per-app values.
SET APP_NAME=aws-deployment-test
SET REGION=us-east-2
SET PORT=8080

REM Define constants (names for folders and files).
SET DATA_FOLDER=data
SET TEMP_FOLDER=temp
SET AWS_FOLDER=aws
SET AWS_DATA_FOLDER=%AWS_FOLDER%/%DATA_FOLDER%
SET AWS_TEMP_FOLDER=%AWS_FOLDER%/%TEMP_FOLDER%
SET TEMP_FILE_NAME=%AWS_TEMP_FOLDER%/temp.txt
SET GITHUB_WORKFLOWS_FOLDER=.github/workflows
SET ROLE_POLICY_FILE=%AWS_DATA_FOLDER%/task-execution-assume-role.json
SET ECS_PARAMS_TEMPLATE_FILE_NAME=%AWS_DATA_FOLDER%/ecs-params-template.yml
SET ECS_PARAMS_FILE_NAME=%AWS_TEMP_FOLDER%/ecs-params.yml
SET GITHUB_PARAMS_TEMPLATE_FILE_NAME=%GITHUB_WORKFLOWS_FOLDER%/deploy-to-aws-template.yml
SET GITHUB_PARAMS_FILE_NAME=%GITHUB_WORKFLOWS_FOLDER%/deploy-to-aws.yml

REM Define values derived from 'APP_NAME'.
SET ROLE_NAME=%APP_NAME% 
SET PROFILE_NAME=%APP_NAME%
SET REPOSITORY_NAME=%APP_NAME%
SET CLUSTER_NAME=%APP_NAME%
SET ECR_REPOSITORY=%APP_NAME%
SET SERVICE_NAME=%APP_NAME%
SET CONTAINER_NAME=%APP_NAME%
SET PROJECT_NAME=%APP_NAME%
SET CLUSTER_CONFIG_NAME=%APP_NAME%

REM Define print colors.
SET HEADER_COLOR=95
SET OKBLUE_COLOR=94
SET OKCYAN_COLOR=36
SET OKGREEN_COLOR=92
SET WARNING_COLOR=93
SET FAIL_COLOR=91
SET ENDC_COLOR=0
SET BOLD_COLOR=1
SET UNDERLINE_COLOR=4

REM Create the 'temp' folder (if not exists).
CD %AWS_FOLDER%
MD %TEMP_FOLDER% 2> NUL
CD ..

REM ================= Section #2 - Settings - end ==============================

REM ================= Section #3 - Resources Clearing - start ==============================
REM In this section we clear the most importent AWS resources (if exists).

SET MSG=* Clear all resources (if exists) - started (may take few minutes...)
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ecs-cli compose --project-name %PROJECT_NAME% service down --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% > NUL 2>&1
ecs-cli down --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% --force > NUL 2>&1
aws ecr delete-repository --repository-name %REPOSITORY_NAME% --region %REGION% --force > NUL 2>&1
SET MSG=* Clear all resources (if exists) - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM ================= Section #3 - Resources Clearing - end ==============================


REM ================= Section #4 - AWS Repository Creation - start ==============================
REM In this section we create AWS repository (if not exists yet).

SET MSG=* Get Repository info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws ecr describe-repositories --repository-names %REPOSITORY_NAME% --region %REGION% --query repositories[0].repositoryUri > %TEMP_FILE_NAME% 2> NUL
SET MSG=* Get Repository info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

IF %errorlevel% == 0 (
    GOTO REPOSITORY_EXISTS
)

SET MSG=* Create repository - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws ecr create-repository --repository-name %REPOSITORY_NAME% --region %REGION% --query repository.repositoryUri > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create repository - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create repository - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

:REPOSITORY_EXISTS

SET MSG=* Fetch Repository info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET /P FOUND_REPOSITORY_URI= < %TEMP_FILE_NAME%
SET MSG=* Found Repository Uri: %FOUND_REPOSITORY_URI%
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET MSG=* Fetch Repository info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM ================= Section #4 - AWS Repository Creation - end ==============================


REM ================= Section #5 - Docker Image Creation - start ==============================
REM In this section we build docker image, and push it to our reposetory.

SET MSG=* Authenticate Docker to an Amazon ECR reposetory - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %FOUND_REPOSITORY_URI% > NUL
IF NOT %errorlevel% == 0 (
  SET ERR_MSG=* Authenticate Docker to an Amazon ECR reposetory - failed, error code: %errorlevel%
  GOTO END
)
SET MSG=* Authenticate Docker to an Amazon ECR reposetory - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Build - started (may take few minutes...)
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ECHO =====================================================================
docker build -t %FOUND_REPOSITORY_URI% .
ECHO =====================================================================
SET MSG=* Build - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Push - started (may take few minutes...)
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ECHO =====================================================================
docker push %FOUND_REPOSITORY_URI%
ECHO =====================================================================
SET MSG=* Push - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM ================= Section #5 - Docker Image Creation - end ==============================

REM ================= Section #6 - AWS Clustr Creation - start ==============================
REM * In this section we create an AWS cluster with a fargate task. 
REM * More info - see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-cli-tutorial-ec2.html,
REM   and its sub chapters:
REM     * 'Installing the Amazon ECS CLI'.
REM     * 'Configuring the Amazon ECS CLI'.
REM     * 'Tutorial: Creating a Cluster with a Fargate Task Using the Amazon ECS CLI'.

SET MSG=* Create role (if not exists) - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws iam --region %REGION% create-role --role-name %ROLE_NAME% --assume-role-policy-document file://%ROLE_POLICY_FILE% > NUL 2>&1
IF NOT %errorlevel% == 0 (
    IF NOT %errorlevel% == 254 (
        SET ERR_MSG=* Create role - failed, error code: %errorlevel%
        GOTO END
    )
)
SET MSG=* Create role (if not exists) - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Attch role policy - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws iam --region %REGION% attach-role-policy --role-name %ROLE_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy > NUL
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Attch role policy - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Attch role policy - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Create ECS CLI profile - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ecs-cli configure profile --access-key %AWS_ACCESS_KEY_ID% --secret-key %AWS_SECRET_ACCESS_KEY% --profile-name %PROFILE_NAME% > NUL
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create ECS CLI profile - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create ECS CLI profile - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Create cluster configuration - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ecs-cli configure --cluster %CLUSTER_NAME% --default-launch-type FARGATE --config-name %APP_NAME% --region %REGION% > NUL
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create cluster configuration - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create cluster configuration - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Create cluster - started (may take few minutes...)
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ECHO =====================================================================
ecs-cli up --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME% --force
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create cluster - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create cluster - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Get VPC info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws cloudformation list-stack-resources --stack-name amazon-ecs-cli-setup-aws-deployment-test --region %REGION% --query StackResourceSummaries[?(@.LogicalResourceId=='Vpc')].PhysicalResourceId > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get VPC info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get VPC info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM * Get value of 2nd line at file %TEMP_FILE_NAME%.
REM * Strip redundent parts at start/end of the found string.
SET MSG=* Fetch VPC info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET FOUND_VPC_ID_LINE=
FOR /F "skip=1 delims=" %%i IN (%TEMP_FILE_NAME%) DO IF NOT DEFINED FOUND_VPC_ID_LINE SET FOUND_VPC_ID_LINE=%%i
SET FOUND_VPC_ID=%FOUND_VPC_ID_LINE:~5,21%
SET MSG=* Found VPC Id: %FOUND_VPC_ID%
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET MSG=* Fetch VPC info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Get Subnets info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws ec2 describe-subnets --filters "Name=vpc-id,Values=%FOUND_VPC_ID%" --region %REGION% --query Subnets[*].SubnetId > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get Subnets info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get Subnets info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Fetch Subnets info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM * Get value of **2ND** line at file %TEMP_FILE_NAME%.
REM * Strip redundent parts at start/end of the found string.
SET FOUND_SUBNET_1_LINE=
FOR /F "skip=1 delims=" %%i IN (%TEMP_FILE_NAME%) DO IF NOT DEFINED FOUND_SUBNET_1_LINE SET FOUND_SUBNET_1_LINE=%%i
SET FOUND_SUBNET_1=%FOUND_SUBNET_1_LINE:~5,24%%
SET MSG=* Found Subnet 1: %FOUND_SUBNET_1%
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM * Get value of **3RD** line at file %TEMP_FILE_NAME%.
REM * Strip redundent parts at start/end of the found string.
SET FOUND_SUBNET_2_LINE=
FOR /F "skip=2 delims=" %%i IN (%TEMP_FILE_NAME%) DO IF NOT DEFINED FOUND_SUBNET_2_LINE SET FOUND_SUBNET_2_LINE=%%i
SET FOUND_SUBNET_2=%FOUND_SUBNET_2_LINE:~5,24%%
SET MSG=* Found Subnet 2: %FOUND_SUBNET_2%
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Fetch Subnets info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Get the default security group ID for the VPC - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws ec2 describe-security-groups --filters Name=vpc-id,Values=%FOUND_VPC_ID% --region %REGION% --query SecurityGroups[0].GroupId > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get the default security group ID for the VPC - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get the default security group ID for the VPC - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Fetch SG info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET /P FOUND_SG_ID= < %TEMP_FILE_NAME%
SET MSG=* Found SG Id: %FOUND_SG_ID%
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET MSG=* Fetch SG info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Add a security group rule to allow inbound access on port %PORT% - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws ec2 authorize-security-group-ingress --group-id %FOUND_SG_ID% --protocol tcp --port %PORT% --cidr 0.0.0.0/0 --region %REGION% > NUL 2>&1
IF NOT %errorlevel% == 0 (
    IF NOT %errorlevel% == 254 (
        SET ERR_MSG=* Add a security group rule to allow inbound access on port %PORT% - failed, error code: %errorlevel%
        GOTO END
    )
)
SET MSG=* Add a security group rule to allow inbound access on port %PORT% - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM SET MSG=* Set ECS params - started
REM CHO [201;%OKGREEN_COLOR%m%MSG%[0m
REM SETLOCAL EnableDelayedExpansion
REM FOR /f "Tokens=* Delims=" %%A IN (%ECS_PARAMS_TEMPLATE_FILE_NAME%) DO SET ECS_PARAMS_TEMPLATE=!ECS_PARAMS_TEMPLATE!%%A
REM SET MSG=*ECS_PARAMS_TEMPLATE: %ECS_PARAMS_TEMPLATE%
REM ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
REM %ECS_PARAMS_TEMPLATE% > %ECS_PARAMS_FILE_NAME%
REM SET MSG=* Set ECS params - ended
REM ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Set ECS params - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
POWERSHELL -Command "(gc %ECS_PARAMS_TEMPLATE_FILE_NAME%) -replace '#ROLE_NAME#', '%ROLE_NAME%' | Out-File -encoding ASCII %ECS_PARAMS_FILE_NAME%"
POWERSHELL -Command "(gc %ECS_PARAMS_FILE_NAME%) -replace '#SUBNET_1#', '%FOUND_SUBNET_1%'  | Out-File -encoding ASCII %ECS_PARAMS_FILE_NAME%"
POWERSHELL -Command "(gc %ECS_PARAMS_FILE_NAME%) -replace '#SUBNET_2#', '%FOUND_SUBNET_2%'  | Out-File -encoding ASCII %ECS_PARAMS_FILE_NAME%"
POWERSHELL -Command "(gc %ECS_PARAMS_FILE_NAME%) -replace '#SG_ID#', '%FOUND_SG_ID%' | Out-File -encoding ASCII %ECS_PARAMS_FILE_NAME%"
SET MSG=* Set ECS params - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Deploy the compose file to the cluster - started (may take few minutes...)
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --ecs-params %ECS_PARAMS_FILE_NAME% --project-name %PROJECT_NAME% service up --create-log-groups --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Deploy the compose file to the cluster - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Deploy the compose file to the cluster - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Display info about cluster's running containers - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --project-name %PROJECT_NAME% service ps --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Display info about cluster's running containers - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Display info about cluster's running containers - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Scale the tasks on the cluster - started (may take few minutes...)
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --project-name %PROJECT_NAME% service scale 2 --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Scale the tasks on the cluster - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Scale the tasks on the cluster - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Display info about cluster's running containers, after scale - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --project-name %PROJECT_NAME% service ps --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Display info about cluster's running containers, after scale - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Display info about cluster's running containers, after scale - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM ================= Section #6 - AWS Clustr Creation - end ==============================


REM ================= Section #7 - GitHub Workflow Creation - start ==============================
REM * In this section we create a GitHub workflow, to soppurt CI/CD.
REM * With this workflow, an automatic build and push of docker image into the AWS reposetory will be executed on each GitHub push.
REM * More info - see https://medium.com/javascript-in-plain-english/deploy-your-node-app-to-aws-container-service-via-github-actions-build-a-pipeline-c114adeb8903,
REM   and its sub chapters:
REM     * 'Creating an IAM user for GitHub Actions'.
REM     * 'Setting up GitHub Actions'.

SET MSG=* Get Task Definition info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
aws ecs describe-services --services %SERVICE_NAME% --region %REGION% --cluster %CLUSTER_NAME% --query services[0].taskDefinition > %TEMP_FILE_NAME%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get Task Definition info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get Task Definition info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Fetch Task Definition info - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET /P FOUND_TASK_DEFINITION= < %TEMP_FILE_NAME%
FOR /f "tokens=1,2 delims=/" %%a IN (%FOUND_TASK_DEFINITION%) DO (
	SET TASK_DEFINITION=%%b
)
SET MSG=* Found Task Definition: %TASK_DEFINITION%
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET MSG=* Fetch Task Definition info - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

SET MSG=* Set GitHub params - started
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
POWERSHELL -Command "(gc %GITHUB_PARAMS_TEMPLATE_FILE_NAME%) -replace '#REGION#', '%REGION%' | Out-File -encoding ASCII %GITHUB_PARAMS_FILE_NAME%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_FILE_NAME%) -replace '#ECR_REPOSITORY#', '%ECR_REPOSITORY%' | Out-File -encoding ASCII %GITHUB_PARAMS_FILE_NAME%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_FILE_NAME%) -replace '#TASK_DEFINITION#', '%TASK_DEFINITION%' | Out-File -encoding ASCII %GITHUB_PARAMS_FILE_NAME%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_FILE_NAME%) -replace '#CONTAINER_NAME#', '%CONTAINER_NAME%' | Out-File -encoding ASCII %GITHUB_PARAMS_FILE_NAME%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_FILE_NAME%) -replace '#SERVICE_NAME#', '%SERVICE_NAME%' | Out-File -encoding ASCII %GITHUB_PARAMS_FILE_NAME%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_FILE_NAME%) -replace '#CLUSTER_NAME#', '%CLUSTER_NAME%' | Out-File -encoding ASCII %GITHUB_PARAMS_FILE_NAME%"
SET MSG=* Set GitHub params - ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

REM ================= Section #7 - GitHub Workflow Creation - end ==============================


REM ================= Section #8 - Termination - start ==============================

SET MSG=* To newly view available services, and thire URLs - run the folowing command (within the project root folder):
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m
SET MSG=    ecs-cli compose --project-name %PROJECT_NAME% service ps --cluster-config %CLUSTER_CONFIG_NAME% --ecs-profile %PROFILE_NAME%
ECHO [201;%WARNING_COLOR%m%MSG%[0m

:END

REM Delete the 'temp' folder.
CD %AWS_FOLDER%
RMDIR /S /Q %TEMP_FOLDER%
CD ..

IF DEFINED ERR_MSG (
    ECHO [201;%FAIL_COLOR%m%ERR_MSG%[0m
)

SET MSG=* The entire sequence has ended
ECHO [201;%OKGREEN_COLOR%m%MSG%[0m

PAUSE
@ECHO ON

REM ================= Section #8 - Termination - end ==============================
