#!/bin/bash



sudo docker build --tag docker.io/diehlpk/monte-carlo-codes:latest -f ./Dockerfile
sudo docker login docker.io
id=$(sudo docker inspect --format="{{.Id}}" docker.io/diehlpk/monte-carlo-codes:latest)
echo $id
sudo docker push "$id" docker://diehlpk/monte-carlo-codes:latest
