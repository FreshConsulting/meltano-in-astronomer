# Example Astronomer Project to Run Meltano Pipelines
An Astronomer.io project that runs Apache Airflow to orchestrate a Meltano pipeline

### What is Meltano?
Meltano is an open-source tool for running data pipelines. Built of off the [Singer](https://www.singer.io/#what-it-is) standard, it uses Extractors (Taps), Loaders (Targets), and Transformers (Utilities) to move and transform data through EL, ETL, and ELT pipelines.

Full documentation for Meltano is availible [here](https://docs.meltano.com/getting-started/)

### What is Airflow?
Apache Airflow is an open-source tool for orchestrating, scheduling, and monitoring different workflows. It uses Directed Acyclic Graphs (DAGs) to execute data workflows and has an extensive UI for monitoring.

Full documentation for Airflow is availible [here](https://airflow.apache.org/docs/apache-airflow/stable/index.html)

### What is Astronomer?
Astronomer.io (Astro) is a cloud and command line platform that assists with running, deploying and managing Airflow instances. It helps you easily configure and run Airflow projects locally, while also giving a custom platform to host them in production.

Full documentation for Astronomer is availible [here](https://www.astronomer.io/docs/astro)

## Project Overview
The purpose of this project is to give an example of how one can run Meltano pipelines using Astronomer and Apache Airflow. Its functionality is to simply move data from the test.csv file into a json file using Meltano while utilizing Airflow's BashOperator to trigger the Meltano pipeline and Astronomer to run and deploy Airflow. 

At a high level this Astronomer Project contains a Meltano project and an Apache Airflow instance that orchestrates and runs that project. This is illustrated in the following diagram: 
![alt text](<example-meltano diagram.drawio.png>)

### Use Cases
This method is intended for use with smaller scale collections of Meltano Projects. The main alternative to it is to use Kubernetes which is documented by Meltano in [this blog post](https://meltano.com/blog/deploying-meltano-for-meltano/). For further details on deploying Meltano pipelines to production, you can see Meltano's guide [here](https://docs.meltano.com/guide/production/).

## Project Contents
This project contains the following files and folders:
- **dags**: Contains the DAG files that trigger the Meltano pipelines and hold the schedule configurations
- **meltano**: Contains the Meltano Project
- **packages.txt**: OS-level packages needed for the project
- **requirements.txt**: Python packages needed for the project
- **meltano_requirements.txt**: Python packages needed to run the Meltano projects
- **airflow_settings.yaml**: Specifies Airflow Connections, Variables, and Pools

## How to Run The Project Locally
1. Ensure that Docker is currently running on your local machine
2. Clone the project and navigate to the root project folder in the cli
3. Start Astro on your local machine by running `astro dev start` (it may take several minutes to start up)
4. Access the Airflow UI at [http://localhost:8080/](http://localhost:8080/) (Username: `admin`, Password: `admin`)
5. When finished, run `astro dev stop` to stop the docker containers

## How to Deploy The Project to Astronomer
1. Create an Astronomer Account
2. Follow [these steps](https://www.astronomer.io/docs/astro/manage-workspaces#create-a-workspace) to create an Astronomer Workspace
3. Follow [these steps](https://www.astronomer.io/docs/astro/create-deployment#create-a-deployment) to create a Deployment in your Workspace
6. Ensure that Docker is currently running on your local machine
7. In the command line, navigate to the root folder of the project
8. Begin the deployment by running `astro deploy`
9. If prompted, select the name of the deployment created in step 3
10. Access the deployment in the [Astronomer Cloud UI](https://cloud.astronomer.io) (it may take several minutes for the deployment to finish)

*For more details refer to the deployment section of the [Astronomer documentation](https://docs.astronomer.io/cloud/deploy-code/)*

## Using Multiple Meltano Projects
In situations where you want to have multiple Meltano projects within the same deployment, you can update the project to accomidate them. 
One way to do so is to add a folder to the project to contain all of the Meltano projects, then add each of the projects to that folder. Further, you can store the Meltano projects in Git submodules to better organize your code and allow for the Meltano projects to still be stored in seperate repositories.

We also need to update the Dockerfile to add the Astro permissions and install the Meltano plugins for all of the Meltano projects. For example, if we named the parent folder *meltano*, this can be done by updating lines 22-25
```
RUN ${MELTANO_EXECUTABLE} install

# Set astro as owner of the Meltano project to run the Meltano pipeline
RUN chown -R astro:astro ${MELTANO_FOLDER}
```

to the following lines which will loop through each project
```
RUN for dir in ${MELTANO_FOLDER}/*/; do cd "$dir" && ${MELTANO_EXECUTABLE} install && cd -; done

# Set astro as owner of the Meltano project to enable it to run the Meltano pipeline
RUN chown -R astro:astro .
```

## Pipeline State Handling
One of the downsides of using Docker containers is the inability to maintain the state of the Meltano pipelines when the image is rebuilt (for example, when redeploying your project). If your pipelines require state to function in production you can update your project to use Meltano state files stored in an external location. [This section of the Meltano documentation](https://docs.meltano.com/concepts/state_backends/) lists how this can be done and the different methods available. 

One example is to store the state files for your pipeline in an AWS S3 bucket in the production environment and in staging and local environments, continue using the default Meltano system database. This can be done by:

1. Updating the Meltano installation in the *meltano_requirements* file to use the AWS S3 extra
```
meltano[s3]
```
2. Adding the following environment variables to your .env file
```
AWS_ACCESS_KEY_ID=[ACCESS_KEY_ID]

AWS_SECRET_ACCESS_KEY=[ACCESS_KEY]

MELTANO_S3_URI=[S3_BUCKET_URI]
```
3. Adding the following lines after the project_id line in your Meltano project's meltano.yml file
```
state_backend:
  uri: $MELTANO_S3_URI
```

*Note: If you don't want to use the external state when running your pipeline locally or in a staging environment, comment out the two lines from step 3 before starting the Astronomer project*

## Schedules
Airflow supports both ad-hoc and scheduled DAG runs. The Airflow schedules are stored inside of the DAG files' configuration section as *schedule_interval* and are stored as a Cron String.

## Notifications When Pipelines Fail
Astronomer has the ability to send notifications when a DAG run fails. How to do so is illustrated in [this sections of their documentation](https://www.astronomer.io/docs/astro/alerts).

