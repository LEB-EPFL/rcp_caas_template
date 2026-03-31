set dotenv-load

DEFAULT_TAG := "latest"

# Build the container image for this project
[arg("local", long="local", short="l", value="local")]
build local="":
  docker build . \
    --platform linux/amd64 \
    --tag registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:{{ if local == "local" { "local" } else { DEFAULT_TAG } }} \
    --build-arg LDAP_GROUPNAME=leb \
    --build-arg LDAP_GID={{if local == "local" { "$(id -g)" } else { "$LDAP_GID" } }} \
    --build-arg LDAP_USERNAME={{if local == "local" { "$(whoami)" } else { "$LDAP_USERNAME" } }} \
    --build-arg LDAP_UID={{if local == "local" { "$(id -u)" } else { "$LDAP_UID" } }}

# Push the container image to the EPFL image registry
push: build
  docker push registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:{{DEFAULT_TAG}}

# Run the container image locally (optionally mount a local folder from this directory into /scratch)
[arg("scratch", long, short = "m")]
run scratch="":
  docker run --rm -it {{ if scratch != "" { "-v $(pwd)/" + scratch + ":/scratch" } else { "" } }} \
    registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:local

# Run the container image with a shell (optionally mount a local folder from this directory into /scratch)
[arg("scratch", long, short = "m")]
shell scratch="":
  docker run --rm -it {{ if scratch != "" { "-v $(pwd)/" + scratch + ":/scratch" } else { "" } }} \
    registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:local /bin/sh

# Add a secret to the Kubernetes cluster
add-secret secret:
  kubectl create secret docker-registry $PROJECT_NAME-secret \
    --docker-server=registry.rcp.epfl.ch \
    --docker-username="robot\$${PROJECT_NAME}+${ROBOT_NAME}" \
    --docker-password="{{secret}}"

# List all configured secrets in Kubernetes
ls-secrets:
  kubectl get secrets

# Attach a shell to the job; name must be the pod name, e.g. "my-job-0-0"
attach name cmd="/bin/bash":
  kubectl exec -it {{name}} -- {{cmd}}

# Delete a job
delete-job name:
  runai delete job "{{name}}"

# Describe a submitted job
describe-job name:
  runai describe job "{{name}}"

# List all jobs that have been submitted to the RCP cluster
ls-jobs:
  runai list jobs

# List all pods that are running on the RCP cluster
ls-pods:
  kubectl get pods

# List the contents of the scratch directory on the RCP cluster
ls-scratch:
  ssh "$LDAP_USERNAME@jumphost.rcp.epfl.ch" "ls -la /mnt/leb/scratch"

# Submit a job to the RCP cluster
[arg("gpus", long, short = "g")]
submit name gpus="1":
  runai submit \
    --name "{{name}}" \
    --image registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:{{DEFAULT_TAG}} \
    --gpu {{gpus}} \
    --existing-pvc claimname=leb-scratch,path=/scratch \
    --existing-pvc claimname=home,path=/home/$LDAP_USERNAME
