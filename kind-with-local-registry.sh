#!/bin/zsh
set -o errexit

#
# Create local Docker registry container unless it already exists
# This improves Kind startup performance drastically because the Docker images are coache locally on the host machine 
#
reg_name='kind-registry'
reg_port='5000'

if [ "$(podman ps -a -q -f name=$reg_name)" ]; then
    # Check if the container is not running
    if [ "$(podman ps -q -f name=$reg_name)" ]; then
        echo "Container '$reg_name' is already running."
    else
        echo "Starting container '$reg_name'..."
        podman start $reg_name
    fi
else
    echo "Creating container '$reg_name'"
    podman run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi


SOURCE=$(dirname "$0")

#
# Create Kind cluster
#
kind create cluster --config="$SOURCE/kind-with-local-registry.config.yaml"

#
# Connect the local Docker registry to the cluster network if not already connected
#
if [ "$(podman inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  podman network connect "kind" "${reg_name}"
fi

#
# Install and confiugre Traefik
#
helm install traefik traefik/traefik --version v30.0.2 -n traefik --create-namespace -f $SOURCE/traefik.values.yaml  --wait

#
# Install and configure Nginx
#
helm install my-nginx oci://registry-1.docker.io/bitnamicharts/nginx -f $SOURCE/nginx.values.yaml --wait