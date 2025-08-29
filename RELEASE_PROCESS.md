# Release Process

This document outlines the blue-green deployment strategy for this project.

## Overview

The deployment process uses a blue-green strategy to minimize downtime. This means we have two identical environments, "blue" and "green", and we switch traffic between them.

This allows us to deploy a new version of the application to the inactive environment, run health checks, and then switch traffic to it with zero downtime.

This process is designed to work on a single instance, like an e2-micro, by using port-based routing and a front-facing reverse proxy.

## Local Development

The blue-green deployment setup is designed for production and staging environments. For local development, a simpler setup is used to make it easier to run and test the application.

The local development environment is defined in the `docker-compose.local.yml` file. This file is a simplified version of the main `docker-compose.yml` and does not include the blue-green deployment complexity.

To run the application locally, you can use the following `make` commands:

*   `make verify`: This will run all linters and tests. It will automatically bring up the necessary services using `docker-compose.local.yml`, run the tests, and then shut them down.
*   `make test`: This will run the unit and integration tests.
*   `make lint`: This will run all the linters.

If you want to run the application locally for manual testing, you can use the following command:

```bash
docker compose -f docker-compose.local.yml up
```

This will start the application, and you can access it at `http://localhost`.

## Prerequisites

Before you can deploy, you need the following:

1.  **Docker and Docker Compose:** These are required to build and run the application.
2.  **A Main Caddy Instance:** You need a main Caddy instance running on the host that acts as the front-facing reverse proxy. This Caddy instance is responsible for routing traffic to the active environment (blue or green).

### Running the Main Caddy Instance

To run the main Caddy instance, you can use the following command:

```bash
docker run -d --name main-caddy -p 80:80 -p 443:443 \
  -v $(pwd)/Caddyfile.main:/etc/caddy/Caddyfile \
  -v $(pwd)/live.caddy:/etc/caddy/live.caddy \
  -v caddy_data:/data \
  caddy:2.8
```

This will start a Caddy container named `main-caddy` that uses the `Caddyfile.main` configuration and imports the `live.caddy` file, which determines the active environment.

## Deployment Steps

To deploy a new version of the application, follow these steps:

1.  **Choose an environment to deploy to.** If the current live environment is "blue", you will deploy to "green", and vice-versa. You can see the current live environment in the `live.caddy` file.

2.  **Run the deployment script.** Use the `deploy.sh` script with the `--env` flag to specify the environment to deploy to.

    ```bash
    # To deploy to the blue environment
    ./deploy.sh --env blue

    # To deploy to the green environment
    ./deploy.sh --env green
    ```

3.  **The script will then:**
    *   Build the Docker images.
    *   Start the new environment on a different port.
    *   Run health checks against the new environment.
    *   If the health checks pass, it will update the `live.caddy` file to point to the new environment.
    *   Stop the old environment to save resources.

4.  **Reload the main Caddy instance.** After the script finishes, you need to reload the main Caddy instance to make the changes take effect.

    ```bash
    docker exec main-caddy caddy reload --config /etc/caddy/Caddyfile
    ```

## Rollback

If you need to roll back to the previous version, you can simply deploy the old environment again. For example, if you just deployed the "green" environment and something went wrong, you can roll back to "blue" by running:

```bash
./deploy.sh --env blue
```

This will start the "blue" environment (if it was stopped), run health checks, and then switch the traffic back to it.