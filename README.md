# \<App Name\>

## General

* General explanation about the app:
    * TODO

* The exposed WEB API:
    * TODO
    * TODO 

* Architecture:
    * TODO

## Run the application in **local machine**

### Prerequisite installations:
* Install NodeJs - https://nodejs.org/en/download.
* Install Postgres - https://www.postgresql.org.

### Create the 'Postgres' database:
* Open the 'pgAdmin' app (part of the 'Postgres' installation).
* Go to: Databases -> right click -> Create -> DataBase, and create new data base with:
    ~~~
    * name: <App Name>.
    * port: 5432.
    * username: postgres.
    * password: postgres.
    ~~~

### Install, build and run the application:
* Go to root folder of the app (the folder where file 'package.json' located), and execute the following commands sequence:
    ~~~
    npm install
    npm run build
    npm run start
    ~~~

## Run the application in **docker machine**

### Prerequisite installations:
* Install Docker engine (e.g. 'Docker Desktop for Windows' - https://hub.docker.com/editions/community/docker-ce-desktop-windows).

### Install, build and run the application:
* Go to root folder of the app (the folder where file 'docker-compose.yml' located), and execute the following command:
    ~~~
    docker-compose up --build
    ~~~
* See the appendix below for some more useful Docker commands.

## Run the application in **cloud**

### Prerequisite installations/configurations:
* At AWS - create IAM user, and get correspond acess keys (this is a **user for operations of ECS/AWS CLI's in our batch file**):
    * More info in this issue - see pargraphs 'Create an IAM user' and 'Create a key pair', here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html.
    * Create new policy, in **one** of the folowing wayes:
        * Via AWS console (at IAM section) - by UI editor:
            ~~~
            Service                     | Action
            --------------------------------------------------------
            EC2                         | ec2:DescribeSubnets
            EC2                         | ec2:DescribeVpcs
            IAM                         | iam:CreateServiceLinkedRole
            IAM                         | iam:AttachRolePolicy
            CloudFormation              | cloudformation:*
            Elastic Container Service   | ecs:*
            CloudWatch                  | Logsogs:*
            Cloud Map                   | servicediscovery:*
            ELB v2                      | elasticloadbalancing:*
            ~~~
        * Via AWS console (at IAM section) - by JSON:
            ~~~
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "VisualEditor0",
                        "Effect": "Allow",
                        "Action": [
                            "servicediscovery:*",
                            "iam:CreateServiceLinkedRole",
                            "ec2:DescribeVpcs",
                            "logs:*",
                            "ecs:*",
                            "cloudformation:*",
                            "iam:AttachRolePolicy",
                            "elasticloadbalancing:*",
                            "ec2:DescribeSubnets"
                        ],
                        "Resource": "*"
                    }
                ]
            }
            ~~~
        * Via AWS CLI:
            * At AWS console - create user for AWS CLI, and save its credintials (if not done yet).
            * Install AWS CLI (if not done yet).
            * Set credintials in the AWS CLI (if not done yet).
            * Import the policy JSON to AWS:
                * TODO
    * Create IAM user, and attch to it the created policy,in **one** of the folowing wayes:
        * Via AWS console (at IAM section):
            * TODO
        * Via AWS CLI:
            * TODO   
    * Create Access Keys, and save/copy the 2 values, ,in **one** of the folowing wayes:
        * Via AWS console (at IAM section):
            * TODO
        * Via AWS CLI:
            * TODO    
* Configure our batch file:
    * Go to root folder of the app (the folder where file 'docker-compose.yml' located), open file 'create-cluster.bat', and set the Access Keys values (see previos paragraph) in the 'AWS_ACCESS_KEY_ID' and 'AWS_SECRET_ACCESS_KEY' variables.
* Execute our batch file:
    * Go to root folder of the app (the folder where file 'docker-compose.yml' located), and execute the following batch file:
        ~~~
        create-cluster.bat
        ~~~
    * Those are the main actions which performed by our batch file:
        * Creating AWS reposetory.
        * Build docker image, and push it into our repository.
        * Creating an AWS cluster with a fargate task.
        * Creating a GitHub workflow, to soppurt CI/CD.
    * More details about the sequence which performed in this batch file - see comments within it.
*  Configure GitHub (in order to execute the workflow which generated by our batch file):
    * With this workflow, an automatic build and push of docker image into the AWS reposetory will be executed on each GitHub push.
    * Open this page: https://medium.com/javascript-in-plain-english/deploy-your-node-app-to-aws-container-service-via-github-actions-build-a-pipeline-c114adeb8903.
    * Perform the operations which listed at the following chapters (only!):
        * 'Creating an IAM user for GitHub Actions'.
        * 'Setting up GitHub Actions'.
            * Abort this chapter while you arrive to **'Create new workflow'** section (we already have costomise version of it, located here: **'.github/workflows/deploy-to-aws.yml'**).
        * 'Testing the outcome'.
    * Open the GitHub reposetory page, then go to 'Actions' -> 'Workflows' -> 'Deploy to Amazon ECS', and test the workflow manually:
        * Select (click) it, then click bottun 'Run workflow' which located at right side of the page.
        * Validate that entire workflow works fine.
   
### Install, build and run the application:
* TODO 

## Testing the application
* This should done while the application already runs (in **docker machine**, in **local machine** or in **cloud** (see explanation about those 3 options above)).
* Go to root folder of the app (the folder where file 'package.json' located), and execute the following commands sequence (install/build commands - only if not executed yet, they require because they install and build also the testing code):
    ~~~
    npm install
    npm run build
    npm run test
    ~~~
* Note: current testing code clears the DB at each run of the tests.

## Appendix - other useful Docker commands

#### Build the docker image:
~~~
docker build -t <App Name> .
~~~
#### Run the docker container:
~~~
docker run -it -p 8080:8080 -P <App Name>
~~~
#### Stop all running docker containers:
~~~
docker stop $(docker ps -q)
~~~
#### Remove all docker containers:
~~~
docker rm $(docker ps -a -q)
~~~