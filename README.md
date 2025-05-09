## Summary
This example shows how to start Kind, install Traefik and install Nginx and configure it so that it will automatically exposed by Treafik to the Kind host machine. Nginx is available at the URL `http://localhost:8080/mynginx/` but the path segment `mynginx` needs to be remove before passed to Nginx so that Nginx can correctly handle the request.

## Tools used
### Kind
[Kind](https://kind.sigs.k8s.io/) is a local Kubernetes environment which runs in Docker or Podman.

### Traefik
[Traefik](https://doc.traefik.io/traefik/) is an open-source Application Proxy.

### Helm
[Helm](https://helm.sh/) is a Kubernetes package manager.

## Available services
* Nginx - http://localhost:8080/mynginx
* AKHQ - http://localhost:8080/myakhq
* PostgreSQL - localhost:5432
* Kafka - localhost:9092