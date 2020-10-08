@ECHO OFF

REM 1st part of the comands based on: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-cli-tutorial-ec2.html.
REM 2nd part of the comands (from 'Get Repository info - started') based on: https://medium.com/javascript-in-plain-english/deploy-your-node-app-to-aws-container-service-via-github-actions-build-a-pipeline-c114adeb8903.
REM More info - see the 'README.md' file of this package.

SET AWS_ACCESS_KEY_ID=
SET AWS_SECRET_ACCESS_KEY=
SET CLUSTER_SUFFIX=100
SET REGION=us-east-2

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
SET REPOSITORY_INFO_FILE_NAME=%AWS_TEMP_FOLDER%repository-info.json
SET REPOSITORY_INFO_PROCESSED_FILE_NAME=%AWS_TEMP_FOLDER%repository-info-processed.txt
SET CONTAINERS_INFO_FILE_NAME=%AWS_TEMP_FOLDER%containers-info.txt
SET CONTAINERS_INFO_PROCESSED_FILE_NAME=%AWS_TEMP_FOLDER%containers-info-processed.txt
SET ECS_PARAMS_TEMPLATE_FILE_NAME=%AWS_DATA_FOLDER%ecs-params-template.yml
SET ECS_PARAMS_FILE_NAME=%AWS_TEMP_FOLDER%ecs-params.yml
SET GITHUB_PARAMS_TEMPLATE_FILE_NAME=%GITHUB_WORKFLOWS_FOLDER%deploy-to-aws-template.yml
SET GITHUB_PARAMS_FILE_NAME=%GITHUB_WORKFLOWS_FOLDER%deploy-to-aws.yml
SET MY_UTILS_PATH="%~dp0build/aws/src/create-cluster-utils.js"
SET ROLE_NAME=ecsTaskExecutionRole-%CLUSTER_SUFFIX%
SET PROFILE_NAME=profile-%CLUSTER_SUFFIX%
SET CLUSTER_NAME=cluster-%CLUSTER_SUFFIX%
SET STACK_NAME=amazon-ecs-cli-setup-%CLUSTER_SUFFIX%
SET REPOSITORY_NAME=%CLUSTER_NAME%

ECHO Clear all resources - started
ecs-cli compose --project-name %CLUSTER_NAME% service down --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
ecs-cli down --force --cluster-config %CLUSTER_NAME% s
ECHO Clear all resources - ended

ECHO Create role - sarted
aws iam --region %REGION% create-role --role-name %ROLE_NAME% --assume-role-policy-document file://%ROLE_POLICY_FILE% > %ROLE_INFO_FILE_NAME%
ECHO Create role - ended

ECHO Attch role policy - started
aws iam --region %REGION% attach-role-policy --role-name %ROLE_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
ECHO Attch role policy - ended

ECHO Create ECS CLI profile - started
ecs-cli configure profile --access-key %AWS_ACCESS_KEY_ID% --secret-key %AWS_SECRET_ACCESS_KEY% --profile-name %PROFILE_NAME%
ECHO Create ECS CLI profile - ended

ECHO Create cluster configuration - started
ecs-cli configure --cluster %CLUSTER_NAME% --default-launch-type FARGATE --config-name %CLUSTER_NAME% --region %REGION%
ECHO Create cluster configuration - ended

ECHO Create cluster - started
ecs-cli up --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME% > %VPC_INFO_FILE_NAME% --force
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

ECHO Add a security group rule to allow inbound access on port 80 - started
aws ec2 authorize-security-group-ingress --group-id %FOUND_SG_ID% --protocol tcp --port 80 --cidr 0.0.0.0/0 --region %REGION%
ECHO Add a security group rule to allow inbound access on port 80 - ended

ECHO Set ESC params - started
CALL node %MY_UTILS_PATH% --ecs-params %ECS_PARAMS_TEMPLATE_FILE_NAME% %ECS_PARAMS_FILE_NAME% %ROLE_NAME% %FOUND_SUBNET_1% %FOUND_SUBNET_2% %FOUND_SG_ID%
ECHO Set ESC params - ended

ECHO Deploy the compose file to the cluster - started
ecs-cli compose --ecs-params %ECS_PARAMS_FILE_NAME% --project-name %CLUSTER_NAME% service up --create-log-groups --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
ECHO Deploy the compose file to the cluster - ended

ECHO View the running containers on a cluster - started
ecs-cli compose --project-name  %CLUSTER_NAME% service ps --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME% > %CONTAINERS_INFO_FILE_NAME%
ECHO View the running containers on a cluster - ended

ECHO Fetch Containers info - started
CALL node %MY_UTILS_PATH% --containers-info %CONTAINERS_INFO_FILE_NAME% %CONTAINERS_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims==" %%A in (%CONTAINERS_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
ECHO Fetch Containers info - ended

REM ECHO View the container logs - started
REM ecs-cli logs --task-id %FOUND_TASK_IDS% --follow --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
REM ECHO View the container logs - end

ECHO Scale the tasks on the cluster - started
ecs-cli compose --project-name %CLUSTER_NAME% service scale 2 --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
ECHO Scale the tasks on the cluster - ended

ECHO View the running containers on a cluster (after scale) - started
ecs-cli compose --project-name  %CLUSTER_NAME% service ps --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME% > %CONTAINERS_INFO_FILE_NAME%
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
REM    ecs-cli logs --task-id %CURR_FOUND_TASK_ID% --follow --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
REM    ECHO View container logs - end
REM )

ECHO Get Repository info - started
aws ecr describe-repositories --repository-names %REPOSITORY_NAME% --region %REGION% > %REPOSITORY_INFO_FILE_NAME%
ECHO Get Repository info - ended

ECHO Fetch Repository info - started
CALL node %MY_UTILS_PATH% --repository-info %REPOSITORY_INFO_FILE_NAME% %REPOSITORY_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims==" %%A in (%REPOSITORY_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
ECHO Fetch Repository info - ended

IF NOT DEFINED FOUND_REPOSITORY_URI (
    ECHO Create repository - started
    aws ecr create-repository --repository-name %REPOSITORY_NAME% --region %REGION% > %REPOSITORY_INFO_FILE_NAME%
    ECHO Create repository - ended
)

ECHO Fetch Repository info (2nd time) - started
CALL node %MY_UTILS_PATH% --repository-info %REPOSITORY_INFO_FILE_NAME% %REPOSITORY_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims==" %%A in (%REPOSITORY_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
ECHO Fetch Repository info (2nd time) - ended

REM ECHO get Task Definition - started
REM aws ecs describe-task-definition --task-definition %CLUSTER_NAME% --query taskDefinition --region %REGION%
REM ECHO get Task Definition - ended

ECHO Set GitHub params - started
SET ECR_REPOSITORY=%CLUSTER_NAME%
SET SERVICE_NAME=%CLUSTER_NAME%
SET CONTAINER_NAME=web
CALL node %MY_UTILS_PATH% --github-params %GITHUB_PARAMS_TEMPLATE_FILE_NAME% %GITHUB_PARAMS_FILE_NAME% %REGION% %ECR_REPOSITORY% %FOUND_TASK_DEFINITION% %CONTAINER_NAME% %SERVICE_NAME% %CLUSTER_NAME%
ECHO Set GitHub params - ended

REM ECHO Clear all resources - started
REM ecs-cli compose --project-name %CLUSTER_NAME% service down --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
REM ecs-cli down --force --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
REM ??? aws iam --region %REGION% delete-role --role-name %ROLE_NAME%
REM ??? aws ecr delete-repository --repository-name %REPOSITORY_NAME% --region %REGION% > %DELETED_REPOSITORY_INFO_FILE_NAME%
REM ECHO Clear all resources - ended

:END
PAUSE
@ECHO ON