@ECHO OFF
SET AWS_ACCESS_KEY_ID=AKIAQHLCXMFBJFE35D5W
SET AWS_SECRET_ACCESS_KEY=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
SET CLUSTER_SUFFIX=10
SET REGION=us-west-2
SET ROLE_INFO_FILE_NAME=role-info.json
SET ROLE_POLICY_FILE=task-execution-assume-role.json
SET VPC_INFO_FILE_NAME=vpc-info.txt
SET VPC_INFO_PROCESSED_FILE_NAME=vpc-info-processed.txt
SET SG_INFO_FILE_NAME=sg-info.json
SET SG_INFO_PROCESSED_FILE_NAME=sg-info-processed.txt
SET ESC_PARAMS_TEMPLATE_FILE_NAME=ecs-params-template.yml
SET ESC_PARAMS_FILE_NAME=ecs-params.yml
SET MY_UTILS_PATH="%~dp0build/aws/create-cluster-utils.js"

SET ROLE_NAME=ecsTaskExecutionRole-%CLUSTER_SUFFIX%
SET PROFILE_NAME=profile-%CLUSTER_SUFFIX%
SET CLUSTER_NAME=cluster-%CLUSTER_SUFFIX%

ecs-cli down --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
aws iam --region %REGION% detach-role-policy --role-name %ROLE_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam --region %REGION% delete-role --role-name %ROLE_NAME%

ECHO Create role - sarted
aws iam --region %REGION% create-role --role-name %ROLE_NAME% --assume-role-policy-document file://%ROLE_POLICY_FILE% > %ROLE_INFO_FILE_NAME%
ECHO Create role - ended

ECHO Attch role policy - started
aws iam --region %REGION% attach-role-policy --role-name %ROLE_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
ECHO Attch role policy - ended

ECHO Create cluster configuration
ecs-cli configure --cluster %CLUSTER_NAME% --default-launch-type FARGATE --config-name %CLUSTER_NAME% --region %REGION%

ECHO Create ECS CLI profile - started
ecs-cli configure profile --access-key %AWS_ACCESS_KEY_ID% --secret-key %AWS_SECRET_ACCESS_KEY% --profile-name %PROFILE_NAME%
ECHO Create ECS CLI profile - ended

ECHO Create cluster - started
ecs-cli up --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME% > %VPC_INFO_FILE_NAME%
ECHO Create cluster - ended

ECHO Fetch VPC info - started
CALL node %MY_UTILS_PATH% --vpc-info %VPC_INFO_FILE_NAME% %VPC_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims=:" %%A in (%VPC_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
ECHO Fetch VPC info - ended

ECHO Retrieve the default security group ID for the VPC - started
aws ec2 describe-security-groups --filters Name=vpc-id,Values=%FOUND_VPC_ID% --region %REGION% > %SG_INFO_FILE_NAME%
ECHO Retrieve the default security group ID for the VPC - ended

ECHO Fetch SG info - started
CALL node %MY_UTILS_PATH% --sg-info %SG_INFO_FILE_NAME% %SG_INFO_PROCESSED_FILE_NAME%
FOR /f "tokens=1,2 delims=:" %%A in (%SG_INFO_PROCESSED_FILE_NAME%) do (
    SET FOUND_%%A=%%B
)
ECHO Fetch SG info - ended

ECHO Add a security group rule to allow inbound access on port 80 - started
aws ec2 authorize-security-group-ingress --group-id %FOUND_SG_ID% --protocol tcp --port 80 --cidr 0.0.0.0/0 --region %REGION%
ECHO Add a security group rule to allow inbound access on port 80 - ended

ECHO Set ESC params - started
CALL node %MY_UTILS_PATH% --ecs-params %ESC_PARAMS_TEMPLATE_FILE_NAME% %ESC_PARAMS_FILE_NAME% %ROLE_NAME% %FOUND_SUBNET_1% %FOUND_SUBNET_2% %FOUND_SG_ID%
ECHO Set ESC params - ended

ECHO Deploy the compose file to the cluster - started
ecs-cli compose --project-name %CLUSTER_NAME% service up --create-log-groups --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
ECHO Deploy the compose file to the cluster - ended

ECHO View the running containers on a cluster - start
ecs-cli compose --project-name  %CLUSTER_NAME% service ps --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
ECHO View the running containers on a cluster - end

ECHO Clear all resources - started
ecs-cli down --cluster-config %CLUSTER_NAME% --ecs-profile %PROFILE_NAME%
aws iam --region %REGION% detach-role-policy --role-name %ROLE_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam --region %REGION% delete-role --role-name %ROLE_NAME%
ECHO Clear all resources - ended

@ECHO ON

PAUSE
