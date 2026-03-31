# RCP CaaS Template

A template repo for creating a container image to run on the EPFL RCP CaaS cluster.

## Quickstart

Assuming you have completed the [prerequisites](#prerequisites):

```console
just build
just push
just submit JOB_NAME
```

## Scope

- You are a member of the LEB
- You want to use this template repository as the starting point for a new code repository that runs on the CaaS cluster
- You want to run a batch processing job on the RCP CaaS cluster for
  - neural network training
  - headless (no gui) electron microscopy image processing

## Assumptions

- You are using Windows
- You perform all of the steps in the [Prerequisites](#prerequisites) section without errors before proceeding to the development steps
- We only have one container image per project

### Misc. Info

- The LEB CaaS admin was Kyle on 2026/03/26.
- GASPAR login refers to your EPFL username and password.
- nas1: RCP refers to this as "collaborative storage." We refer to this as "the file server."
- nas3: RCP refers to this as "scratch storage." Data must be copied here to be accessible from the cluster.

## Prerequisites

### Gain access to the RCP CaaS service

Ask an admin to be added to the LEB's RCP CaaS users. 

### Windows Software

1. Install the WSL 2 with the latest version of Ubuntu: <https://learn.microsoft.com/en-us/windows/wsl/install>
  - The WSL is the official Microsoft tool that provides a fully functional Linux distribution running inside Windows
2. Install Docker Desktop: <https://docs.docker.com/desktop/setup/install/windows-install/>
3. Configure Docker Desktop to use the WSL backend: <https://docs.docker.com/desktop/features/wsl/>
  - This step configures Docker Desktop to build and run **Linux container images**, not Windows containers
4. Install `kubectl` within the WSL
  - Download directly to `$HOME/.local/bin` with this command: `curl -L -o "$HOME/.local/bin/kubectl" https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl`
  - Verify installation with `kubectl version`
  - Ensure that `$HOME/.local/bin` is on your PATH, where `$HOME=/home/YOUR_USERNAME`: `echo $PATH`.
  - Ensure you are using kubectl in `$HOME/.local/bin` with `which kubectl`. It should point to the one in `$HOME/.local/bin`, not `/usr/local/bin`.
  - More general instructions are here: <https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux>
5. Install Run:ai within the WSL
  - Download to your tmp directory: `curl -sLo /tmp/runai https://rcp-caas-prod.rcp.epfl.ch/cli/linux`
  - Install: `sudo install /tmp/runai /usr/local/bin/runai`
  - Verify installation: `runai version`
6. Install `just` within the WSL: <https://just.systems/man/en/pre-built-binaries.html>
  - Install the latest version from the shell script installer: `curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin`
  - `~/.local.bin` should already be on your PATH if using a Ubuntu distribution for your WSL. Verify this by running: `echo $PATH`
    - Note that `~` is shorthand for your home directory, i.e. `/home/USERNAME`.
  - `just` is a tool for mapping long commands, such as Docker commands, to short, user-defined alternatives

All of the following console commands are assumed to be run from the WSL.

### Get your user id (UID) and group ID (GID)

This information is required to mount networked directories into the running containers. The official documentation is here: <https://wiki.rcp.epfl.ch/home/CaaS/FAQ/how-to-find-uid-gid>

```console
# Replace USERNAME with your GASPAR username
ssh USERNAME@jumphost.rcp.epfl.ch

# Print your UID
id -u

# Print your GID
id -g
```

### Set up the project variables

Create a file called `.env` in the root folder of this repository with the following contents.

```
IMAGE_NAME=hello-leb
LDAP_UID=XXXXXX
LDAP_GID=XXXXX
PROJECT_NAME=leb-test
ROBOT_NAME=leb-test-robot
USERNAME=XXXXXXXX
```

- Replace `hello-leb` with the name of your container image. This should reflect what the software does.
- Use the UID and GID values that you just found for `LDAP_UID` and `LDAP_GID`.
- `PROJECT_NAME` is the name given to the project in the Harbor registry. `leb-test` is a test project that we can use to test RCP CaaS workflows. Our other project is `leb-smartmicroscopy`.
- `ROBOT_NAME` is the name of the robot user for the Harbor project. See [the section on creating a registry project](#optional-create-a-project-on-the-rcp-container-image-registry) for more information.
- `USERNAME` should be your EPFL GASPAR username.

The `.env` file is listed in the `.gitignore` file and is therefore ignored by Git. You will need to create it every time you set up this repository from scratch.

### Log in to the RCP Container Registry

```console
$ docker login registry.rcp.epfl.ch
```

Use your GASPAR credentials to login.

### Configure Run:ai

The following is a summary of the documentation here: <https://wiki.rcp.epfl.ch/home/CaaS/FAQ/how-to-use-runai>.

Download the kube config file from RCP and put it in ~/.kube/config.

```console
# Make the ~/.kube directory if it doesn't already exist
mkdir -p ~/.kube

curl https://wiki.rcp.epfl.ch/public/files/kube-config.yaml -o ~/.kube/config && chmod 600 ~/.kube/config
```

Next login to Run:ai with the following command:

```console
runai login
```

Open the link that appears, copy the token, paste it back into the terminal, and press ENTER. Validate that you are logged in with the command `runai whoami`.

Next set the default cluster to the RCP CaaS:

```console
runai config cluster rcp-caas-prod
```

Then, you need to create a project. This is confusingly different from the Harbor image registry project. The Run:ai project **must** be called `leb-GASPAR_USERNAME`:

```console
# Replace GASPAR_USERNAME with your EPFL login name
runai config project leb-GASPAR_USERNAME
```

Verify that the cluster and project have been configured:

```console
$ runai config view
INFO[0000] Project: leb-GASPAR_USERNAME
INFO[0000] Cluster: rcp-caas-prod
```

Finally, verify that you can launch a job called `test` that uses a single GPU and runs the `nvidia-smi` command:

```console
runai submit --name test -i ubuntu -g 1 -- nvidia-smi
runai describe job test
```

It should report a status of `SUCEEDED`  a few seconds after submission.

### (Optional) Create a Project on the RCP Container Image Registry

How to use the RCP image registry: <https://wiki.rcp.epfl.ch/home/CaaS/FAQ/how-to-registry>

This step might already have been done for you. Ask the LEB admin first.

The purpose of this step is to create a project in Harbor (the container registry) that will host your Docker image.

1. Login to <https://registry.rcp.epfl.ch> using your GASPAR username and password.
2. Select `New Project`
3. Enter a name and visibility for the project. If the visibility is `Public`, you can stop here.
4. Search for the project in the search bar after creating it and select it.
5. Add any users to the project that you want to have access by clicking the `+ User` button.
6. Set up robot users that can pull your image as described here: <https://wiki.rcp.epfl.ch/home/CaaS/FAQ/how-to-registry#robot-account>

**There is a private `leb-test` project that you can use to test your project against. Ask our lab's admin for access.**

#### Add the Secret for the Robot Account

Add the secret for the project's robot account (if any), replacing `SECRET` with the string provided by the admin:

```console
just add-secret SECRET
```

Verify that the secret has been added:

```console
just list-secrets
```

If you are setting up a new project on the Harbor registry, follow the directions at <https://wiki.rcp.epfl.ch/home/CaaS/FAQ/how-to-registry#robot-account> to generate the secret for the robot user and add it with `just add-secret SECRET`.

## Local Development

### Build and Run Images and Containers

From the command line:

```console
# Build the container image
just build

# Run the container locally
just run

# Run the container locally, mount the data directory into the container
mkdir data  # Make the folder first if it doesn't exist
just run -m data
ls data  # Show the contents of the folder

# Get a shell inside the container
just shell

# Get a shell inside the container, and also mount the data folder (which must exist)
just shell -m data
```

## RCP Development

## Push an Image to the Registry

This assumes that you have logged in to the RCP Harbor Container Image Registry.

```console
# Build the container image
just build

# Push the image to the registry
just push
```

## Run a Job on the Cluster

<https://wiki.rcp.epfl.ch/home/STaaS/Collaborative-General>

Running a job on the cluster goes as follows:

1. Connect to the RCP Jumphost: `ssh USERNAME@jumphost.rcp.epfl.ch`
2. Copy data from the file server (NAS1) or your local workstation to scratch storage (NAS3).
  - Workstation
  - File server
3. Launch the job.
4. Copy the computation results from NAS3 to NAS1.
5. Repeat the process.

### Prepare Data for Processing

The cluster can only access data inside `/mnt/leb/scratch`. You therefore need to copy any data there before running a job.

To copy data from your workstation to scratch storage:

```console
# Run from your workstation
scp -r ~/Documents/my-data jumphost.rcp.epfl.ch:/mnt/leb/scratch/
```

To copy data from the file server to scratch storage:

```console
ssh USERNAME@jumphost.rcp.epfl.ch
cp -r /mnt/leb/Scientific_projects/MY_PROJECT/data /mnt/leb/scratch/
```

To verify the files are in scratch storage:

```console
just ls-scratch
```

### Launch a job

```console
# Submit a job with name JOB_NAME
just submit JOB_NAME

# Submit a job requesting only 0.1 fractional GPUs
just submit JOB_NAME -g 0.1

# List jobs
just ls-jobs

# Describe a specific job
just describe-job JOB_NAME

# Get a shell inside the container
just get-pods  # Get pod names; this is to support containers without bash, such as Alpine
just attach POD_NAME
```

### Delete a job

```console
just delete-job NAME
```

## List all `just` Commands

```console
just --list
```
