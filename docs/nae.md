# Execution Model

When a user launches an application, JARVICE starts containers on all nodes selected and launches the command corresponding to the selected endpoint on the first (master) compute node only.  That command is then responsible for "fan out" or parallel execution across the remaining nodes, if any.  Passwordless `ssh` trust is automatically established across all nodes for the job.  Additionally, the job is protected via firewall from other job traffic.

If the job is interactive (meaning the endpoint accepts connections from the outside world), JARVICE provisions a public network address translation to the first (master) node in the job.  Other nodes are not accessible publicly.

JARVICE runs endpoint commands as the user `nimbix`.  This user may gain `root` privileges using the `sudo` command without password if the image is set up correctly (see [Docker Images on JARVICE](docker.md) for additional details).

# Runtime Directories and Files

Certain directories and files have special meaning on JARVICE:

### /data

This is where all persistent files should be stored; the user has access to this directory outside of your application as well.

### /tmp

Place all temporary files here for best performance; typically this volume provides at least 100GB of disk space on the Nimbix Cloud.  All files in this volume are wiped when your application exits.

### /home/nimbix

This directory is ephemeral and should not be used for storing persistent data.  If your application is designed to default to the home directory for persistent storage, either add a symbolic link to `/data` under `/home/nimbix` or change your configuration to default to `/data`

### /etc/JARVICE

This directory contains generated files from the container engine itself.  The most common files are:

#### /etc/JARVICE/nodes

Contains a list of compute nodes, one per line, that make up this job.  The "master" node is always first.  This is especially relevant for multinode jobs.  All entries in this list are resolvable by all nodes, and if `ssh` is supported in the application image, passwordless `ssh` trust is automatically established across all nodes in the job.`  This file may be passed verbatim to certain commands such as `mpirun` for parallel applications, for example.

#### /etc/JARVICE/cores

Similar to `/etc/JARVICE/nodes`, but contains one entry per core, sorted in the order of the compute nodes in the job.  For example if a job runs on 2 16 core nodes, there will be 32 entries in this file - the first 16 for the master node, and the second 16 for the slave node.  Each core entry is identical for the given node.

#### /etc/JARVICE/jobinfo.sh

Provides job information available to the application, and can be sourced into a shell script.

#### /etc/JARVICE/jobenv.sh

Provides account variables as environment variables for the application, and can be sourced into a shell script.  Account variables are managed for end users by Nimbix Support and are frequently used to describe license server addresses and keys.

### Container metadata

The directory `/etc/NAE` contains certain metadata files for the JARVICE system; these are managed by the application developer and are part of the Docker image:

#### /etc/NAE/AppDef.json

This is the AppDef - if present a pull into JARVICE replaces the endpoint and metadata definitions on file.  You may download the AppDef from the JARVICE portal as described in [CI/CD Pipeline](cicd.md), and modify it per the [JARVICE Application Definition Guide](https://www.nimbix.net/jarvice-application-deployment-guide/).  The JARVICE API also provides a validation endpoint that can interrupt the `docker build` if it fails.  You may call this endpoint manually as well.  The following example snippet inserts an AppDef into a Docker image and validates it at build time:

```
COPY AppDef.json /etc/NAE/AppDef.json
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://api.jarvice.com/jarvice/validate
```

The example above assumes that `AppDef.json` contains a valid application definition and lives adjacent to the Dockerfile in the repository.

#### /etc/NAE/screenshot.png

A screenshot or graphic to display in the "large" card - when an application card is clicked.  This should be 960x540 resolution for optimal results.

#### /etc/NAE/url.txt

The URL to provide when a user clicks on a running application - this is used to connect the end user to whatever service the application provides.  Substitutions are supported as well.  For example, `https://%PUBLICADDR%/` in `/etc/url.txt` sends the user to the public IP address of the running application when they connect (%PUBLICADDR% is a substitution).

#### /etc/NAE/help.html

HTML help to pop up when the user clicks the help button while the application is running.

