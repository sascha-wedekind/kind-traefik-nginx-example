## Summary
This example shows how to start Kind, install Traefik and install Nginx and confiure it so that it will automatically exposed by Treafik to the Kind host machine. Nginx is available at the URL `http://localhost:8080/mynginx/` but the path segment `mynginx` needs to be remove before passed to Nginx so that Nginx can correctly handle the request.

## Tools used
### Kind
[Kind](https://kind.sigs.k8s.io/) is a local Kubernetes environment which runs in Docker or Podman.

### Traefik
[Traefik](https://doc.traefik.io/traefik/) is an open-source Application Proxy.

### Helm
[Helm](https://helm.sh/) is a Kubernetes package manager.


## Step 1: configure and start Kind
This examaple configures Kind to use one worker node and maps the Kind container ports 32080 and 32090 to the host (the machine running Kind) ports 808 and 8090. Let's say the file is named `kind.config.yaml`
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
    extraPortMappings:
      # HTTP traffic - This is used for accessing the metrics and repair user interfaces
      - containerPort: 32080
        hostPort: 8080
        protocol: TCP
      # Traefik
      - containerPort: 32090
        hostPort: 8090
        protocol: TCP
```

To start a Kind (Kubernetes) cluster with the configuration above, execute
```sh
kind create cluster --config=kind.config.yaml
```

## Step 2: install and configure Traefik
The Traefik Helm chart version used in this example is `v30.0.2`
The configuration below tells Traefik to listen to HTTP (container) ports `32090`, `32080` and `32443`. See Kind configuration above, which maps these ports to individual host ports.
In addition this configuration configures Traefik to automatically recognize Kubernetes ingresses, which are annotated with `kubernetes.io/ingress.class: "traefik-private"`. 
Also a Trafik middleware is configured to remove the URL path prefix `/mynginx` so that Nginx can correctly handle the URL passed to it.
Let's say the file is named `traefik.values.yaml`

```yaml
---

# Current value config does not make it possible to use namespace traefik, so it must be specified in helm install
# Default values can be found at: https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml

providers:
  kubernetesCRD:
    namespaces:
      - default
      - traefik
  kubernetesIngress:
    namespaces:
      - default
      - traefik

service:
  type: NodePort

#exposedPort: true
#    nodePort: 32090

ports:
  traefik:
    expose:
         default: true
         internal: true
    nodePort: 32090
  web:
    nodePort: 32080
  websecure:
    nodePort: 32443

additionalArguments:
  - --api
  - --api.insecure
  - --providers.kubernetesingress.ingressclass=traefik-private
  - --providers.kubernetescrd.ingressclass=traefik-private
  - --serversTransport.insecureSkipVerify=true

ingressRoute:
  dashboard:
    enabled: true

ingressClass:
  enabled: true
  isDefaultClass: true

rollingUpdate:
  maxUnavailable: 0

# Whether Role Based Access Control objects like roles and rolebindings should be created
rbac:
  enabled: true
  # If set to false, installs ClusterRole and ClusterRoleBinding so Traefik can be used across namespaces.
  # If set to true, installs namespace-specific Role and RoleBinding and requires provider configuration be set to that same namespace
  namespaced: false
  
extraObjects:
  - apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: strip-mynginx-prefix
	    namespace: default
    spec:
      stripPrefix:
        prefixes:
          - "/mynginx"
```

To install Traefik in Helm-Chart-Version `v30.0.2` with the configuration above, execute
```sh
helm install traefik traefik/traefik --version v30.0.2 -n traefik --create-namespace -f traefik.values.yaml  --wait
```

## Step 3: install and configure Nginx
Nginx ist configured to create an Kubernetes Ingress with two annotations, which leads to get the ingress recognized by Traefik `kubernetes.io/ingress.class` and to apply the Traefik StripPrefix middleware `traefik.ingress.kubernetes.io/router.middlewares: default-strip-mynginx-prefix@kubernetescrd` before passing the URL to Nginx. Note that the middleware name must be prefixed with the Kubernetes namespace where the middleware is installed and and postfixed with `@kubernetescrd`.

Let's say the file is named `nginx.values.yaml`
```yaml
ingress:
    enabled: true
    annotations:
        kubernetes.io/ingress.class: "traefik-private"
        traefik.ingress.kubernetes.io/router.middlewares: default-strip-mynginx-prefix@kubernetescrd
    hostname: localhost
    path: "/mynginx"
```

To install Nginx with thconfiguration show, execute:
```sh
helm install my-nginx oci://registry-1.docker.io/bitnamicharts/nginx -f nginx.values.yaml --wait
```

## Step 4: test if the installation is valid
Open a browser and request the URL http://localhost:8080/mynginx/ . The response shall be the Nginx welcome page


The Traefik dashboard can be accesed with the URL http://localhost:8090/dashboard .


