#!/bin/bash



sudo podman build --tag docker.io/diehlpk/monte-carlo-codes:latest -f ./Dockerfile
sudo podman login docker.io
id=$(sudo podman inspect --format="{{.Id}}" docker.io/diehlpk/monte-carlo-codes:latest)
echo $id
sudo podman push "$id" docker://diehlpk/monte-carlo-codes:latest
