# Release Process

This document outlines the blue-green deployment strategy for this project.

## Overview

The deployment process uses a blue-green strategy to minimize downtime. This means we have two identical environments, "blue" and "green", and we switch traffic between them.

This allows us to deploy a new version of the application to the inactive environment, run health checks, and then switch traffic to it with zero downtime.

This process is designed to work on a single instance, like an e2-micro, by using a front-facing reverse proxy.

## Local Development

For local development, you can use the `dev` profile in the `docker-compose.yml` file. This will start the application and the linting service.

To run the application locally, you can use the following `make` commands:

*   `make verify`: This will run all linters and tests. It will automatically bring up the necessary services using the `dev` profile, run the tests, and then shut them down.
*   `make test`: This will run the unit and integration tests.
*   `make lint`: This will run all the linters.

If you want to run the application locally for manual testing, you can use the following command:

```bash
docker compose --profile dev up
```

This will start the application, and you can access it at `http://localhost`.

## Prerequisites

Before you can deploy, you need the following:

1.  **Docker and Docker Compose:** These are required to build and run the application.
2.  **A Main Caddy Instance:** You need a main Caddy instance running on the host that acts as the front-facing reverse proxy. This Caddy instance is responsible for routing traffic to the active environment (blue or green).

### One-time network and volumes

Create the shared Docker network and volumes used by edge Caddy and API data:

```bash
docker network create edge-net || true
docker volume create edge_caddy_data || true
docker volume create app_data || true
```

### Running the Main Caddy Instance

To run the main Caddy instance, you can use the following command:

```bash
docker compose up -d edge
```

This will start a Caddy container named `loancalc-edge` that uses the `Caddyfile.edge` configuration.

## Deployment Steps

To deploy a new version of the application, follow these steps:

1.  **Choose an environment to deploy to.** If the current live environment is "blue", you will deploy to "green", and vice-versa.

2.  **Run the deployment script.** Use the `deploy.sh` script with the environment name as an argument.

    ```bash
    # To deploy to the blue environment
    ./deploy.sh blue

    # To deploy to the green environment
    ./deploy.sh green
    ```

3.  **The script will then:**
    *   Build the Docker images.
    *   Start the new environment.
    *   Run health checks against the new environment.
    *   If the health checks pass, it will generate a new `Caddyfile.edge` file with the correct upstream and reload the edge Caddy.
    *   Stop the old environment to save resources.

## Rollback

If you need to roll back to the previous version, you can simply deploy the old environment again. For example, if you just deployed the "green" environment and something went wrong, you can roll back to "blue" by running:

```bash
./deploy.sh blue
```

This will start the "blue" environment (if it was stopped), run health checks, and then switch the traffic back to it.
