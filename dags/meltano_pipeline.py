from airflow.decorators import dag, task
import os

# Define the basic parameters of the DAG, like schedule and start_date
@dag(
    default_args={"owner": "Astro", "retries": 0},
    tags=["example"],
)
def Meltano_Pipeline():
    @task.bash()
    def bash_task():
        path = os.environ["MELTANO_FOLDER"]
        exec = os.environ["MELTANO_EXECUTABLE"]

        return f"cd { path } && { exec } run tap-csv target-jsonl"

    bash_task()

Meltano_Pipeline()
