# <App Name>

## General

* General explanation about the app:
    * TODO

* The exposed WEB API:
    * TODO
    * TODO 

* Architecture:
    * TODO

## Running the application in **local machine**

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

### Install, build and run the multi-parts local applications (Postgres + <App Name>):
* Go to root folder of the app (the folder where file 'package.json' located), and execute the following commands sequence:
~~~
npm install
npm run build
npm run start
~~~

## Running the application in **docker machine**

### Prerequisite installations:
* Install Docker engine (e.g. 'Docker Desktop for Windows' - https://hub.docker.com/editions/community/docker-ce-desktop-windows).

### Install, build and run the multi-container Docker applications (Postgres + <App Name>):
* Go to root folder of the app (the folder where file 'docker-compose.yml' located), and execute the following command:
~~~
docker-compose up --build
~~~
* See the appendix below for some more useful Docker commands.

## Running the application in **cloud**

### Prerequisite installations:
* Creating a cluster with a Fargate task using the Amazon ECS CLI:
    * Go to root folder of the app (the folder where file 'docker-compose.yml' located), open file 'create-cluster.bat', and set values of 'AWS_ACCESS_KEY_ID' and 'AWS_SECRET_ACCESS_KEY' variables (to get the required keys - folow pargraphs 'Create an IAM user' and 'Create a key pair', here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html).
    * Go to root folder of the app (the folder where file 'docker-compose.yml' located), and execute the following batch file:
        ~~~
        create-cluster.bat
        ~~~
    * More details about the sequence which performed in this batch file - see page https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI.html, and its sub chapters:
        * Installing the Amazon ECS CLI
        * Configuring the Amazon ECS CLI
        * Tutorial: Creating a Cluster with a Fargate Task Using the Amazon ECS CLI 
* Deploy your Node app to AWS Container Service via GitHub actions & build a pipeline:
    * Open this page: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI.html.
    * Folow the relevant chapters (but pay attention to comments below, regarding **'ecs-task-definition.json'** and **'Create new workflow'**):
        * TODO
        * TODO
    * While file **'ecs-task-definition.json'** is required - you can get a ready one: 'aws\data\ecs-task-definition.json'.
    * At section **'Create new workflow'** - use our costumized version of the 'Deploy to Amazon ECS' workflow, located here: **'.github/workflows/docker-compose.yml'** (**instead** using the generic 'Deploy to Amazon ECS' workflow).

### Install, build and run the multi-container Docker applications (Postgres + <App Name>):
* Open the GitHub reposetory page, then go to 'Actions' -> 'Workflows' -> 'Deploy to Amazon ECS', select (click) it, then click bottun 'Run workflow' which located at right side of the page.
* TODO 

## Testing the application
* This should done while the application is running (in **docker machine**, in **local machine** or in cloud (see explanation about those 3 options above)).
* Go to root folder of the app (the folder where file 'package.json' located), and execute the following commands sequence (install/build commands - only if not executed yet, they require because they install and build also the testing code):
~~~
npm install
npm run build
npm run test
~~~
* Note: current testing code clears the DB at each run of the tests.

## Appendix

### Other useful Docker commands

#### Build the <App Name> docker image:
~~~
docker build -t <App Name> .
~~~
#### Run the <App Name> docker container:
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