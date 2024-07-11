# syntax=quay.io/astronomer/airflow-extensions:v1
FROM quay.io/astronomer/astro-runtime:11.6.0

# Create virtual environment to install Meltano in
USER astro
PYENV 3.11 meltano_env meltano_requirements.txt

# Intall git for Meltano plugin installation
USER root
RUN apt-get update
RUN apt-get -y install git 

# Set reusable environment variables
ENV MELTANO_EXECUTABLE /home/astro/.venv/meltano_env/bin/meltano
ENV MELTANO_FOLDER /home/astro/.venv/meltano_env/meltano

# Copy the Meltano project to the virtual environment
COPY meltano ${MELTANO_FOLDER}

# Install the meltano plugins
WORKDIR ${MELTANO_FOLDER}
RUN ${MELTANO_EXECUTABLE} install

# Set astro as owner of the Meltano project to run the Meltano pipeline
RUN chown -R astro:astro ${MELTANO_FOLDER}

# Switch Back to Astro Defaults
USER ${ASTRONOMER_USER}
WORKDIR ${AIRFLOW_HOME}

ENTRYPOINT ["/entrypoint"]
CMD ["airflow", "--help"]