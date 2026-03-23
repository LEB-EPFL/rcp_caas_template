set dotenv-load

# Build the container image for this project
build VERSION="latest":
  docker build . \
    --platform linux/amd64 \
    --tag registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:{{VERSION}} \
    --build-arg LDAP_GROUPNAME=leb \
    --build-arg LDAP_GID="$LDAP_GID" \
    --build-arg LDAP_USERNAME="$USERNAME" \
    --build-arg LDAP_UID="$LDAP_UID"

# Push the container image to the EPFL image registry
push VERSION="latest":
  docker push registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:{{VERSION}}

# Run the container image locally (optionally mount a local folder from this directory into /scratch)
[arg("VERSION", long, short = "v")]
[arg("SCRATCH", long, short = "m")]
run VERSION="latest" SCRATCH="":
  docker run --rm -it {{ if SCRATCH != "" { "-v $(pwd)/" + SCRATCH + ":/scratch" } else { "" } }} \
    registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:{{VERSION}}

# Run the container image with a shell (optionally mount a local folder from this directory into /scratch)
[arg("VERSION", long, short = "v")]
[arg("SCRATCH", long, short = "m")]
shell VERSION="latest" SCRATCH="":
  docker run --rm -it {{ if SCRATCH != "" { "-v $(pwd)/" + SCRATCH + ":/scratch" } else { "" } }} \
    registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:{{VERSION}} /bin/sh

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
  ssh "$USERNAME@jumphost.rcp.epfl.ch" "ls -la /mnt/leb/scratch"

# Submit a job to the RCP cluster
[arg("GPUS", long, short = "g")]
[arg("VERSION", long, short = "v")]
submit name GPUS="1" VERSION="latest":
  runai submit \
    --name "{{name}}" \
    --image registry.rcp.epfl.ch/$PROJECT_NAME/$IMAGE_NAME:{{VERSION}} \
    --gpu {{GPUS}} \
    --existing-pvc claimname=leb-scratch,path=/scratch \
    --existing-pvc claimname=home,path=/home/$USERNAME \
    --command \
    -- /bin/ash -ic "sleep 600"
