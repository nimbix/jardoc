# Base Images

JARVICE supports most Ubuntu or CentOS-based images.  There is currently no explicit support for other types such as Alpine.

For convenience, Nimbix provides various base images for both **x86_64**, **ARM** and **ppc64le** platforms.  Please note that these images are maintained as "best effort", and are meant mainly for convenience:

## Popular x86_64 Base Images

### Ubuntu style

[nimbix/ubuntu-base](https://hub.docker.com/r/nimbix/ubuntu-base/)

(Base Ubuntu image with remote access capabilities)

[nimbix/ubuntu-desktop](https://hub.docker.com/r/nimbix/ubuntu-desktop/)

(Base Ubuntu image with Nimbix Desktop and remote access capabilities)


[nimbix/base-ubuntu-nvidia](https://hub.docker.com/r/nimbix/base-ubuntu-nvidia/)

([nvidia/cuda](https://hub.docker.com/r/nvidia/cuda/)-based image with remote access capabilities.)

### CentOS style

[nimbix/centos-base](https://hub.docker.com/r/nimbix/centos-base/)

(Base CentOS image with remote access capabilities)

[nimbix/centos-desktop](https://hub.docker.com/r/nimbix/centos-desktop/)

(Base CentOS image with Nimbix Desktop and remote access capabilities)

[nimbix/base-centos-nvidia](https://hub.docker.com/r/nimbix/base-centos-nvidia/)

([nvidia/cuda](https://hub.docker.com/r/nvidia/cuda/)-based image with remote access capabilities.)

## Popular ARM Images

### Ubuntu style

[nimbix/ubuntu-desktop:bionic-arm](https://console.cloud.google.com/gcr/images/jarvice/GLOBAL/ubuntu-desktop@sha256:c045f35269a9375a76b59dc39f592a059789e878fae531c56e7dd410ba056a88/details?tab=info)

(Ubuntu image for ARM with Nimbix Desktop and remote access capabilities)

## Popular ppc64le Base Images

[nimbix/ubuntu-cuda-ppc64le](https://hub.docker.com/r/nimbix/ubuntu-cuda-ppc64le/)

(CUDA-capable Ubuntu base image with remote access capabilities)

[nimbix/centos-cuda-ppc64le](https://hub.docker.com/r/nimbix/centos-cuda-ppc64le/)

(CUDA-capable Ubuntu base image with remote access capabilities)

## Specialty nimbix Base Images

[jarvice/ubuntu-ibm-mldl-ppc64le](https://hub.docker.com/r/jarvice/ubuntu-ibm-mldl-ppc64le/)

(PowerAI base image for ML/DL and Distributed Deep Learning (DDL); this image is maintained in sync with IBM updates.)

# Using 3rd party Base Images

It's possible to use virtually any Ubuntu or CentOS 3rd party base image, including those compatible with [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) (e.g. [nvidia/cuda](https://hub.docker.com/r/nvidia/cuda/)).

Nimbix provides simple, publicly accessible mechanisms to make these images "JARVICE-ready":

* [image-common](https://github.com/nimbix/image-common) for basic image readiness.
* [notebook-common](https://github.com/nimbix/notebook-common) for adding authenticated, secure Jupyter Notebooks.

In both cases please see the README.md for each repository for usage instructions.  Note that not all functions are available on all platforms - currently the Nimbix Desktop is only available on **x86_64**.

The following example Dockerfile creates a JARVICE-ready image from a 3rd party base image:

```
FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu14.04

RUN apt-get -y update && \
    apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash

# Expose port 22 for local JARVICE emulation in docker
EXPOSE 22
```

For a more complete example involving a Jupyter Notebook, please see the Dockerfile for [app-powerai-notebooks](https://github.com/nimbix/app-powerai-notebooks).

# Container Engine Differences

JARVICE provides a high performance container engine used to deploy large scale applications.  It does not use the Docker engine to run containers.  Because of this, there are some subtle differences in operation:

1. JARVICE containers run code as the user `nimbix`, not `root`.  It's important when writing persistent data (in `/data`) that this not be done as `root`.  Additionally, any `USER` directives in the Docker image are ignored once the container is run on JARVICE.
2. `EXPOSE` directives are ignored - JARVICE forwards most ports into the container automatically.  If you have problems with specific ports, please contact Support.
3. `ENTRYPOINT` is ignored.  JARVICE uses endpoints defined in the AppDef to run commands or start services inside the Docker image.

## Best Practices

1. Use wrapper scripts for commands to set environment variables, etc.
2. Use `sudo` to gain privileges - the `nimbix` user supports passwordless `sudo` if the image is set up properly with [image-common](https://github.com/nimbix/image-common).
3. Store persistent data in `/data`, but as user `nimbix` only.  Data in this directory persists after your image exits, and the user may transfer files to and from this directory without having to run your application.
4. Docker build stages should be performed as `root` rather than `nimbix`.
5. Avoid changing file ownership in Docker build stages and consider using `0666/0777` permissions while keeping `root:root` ownership. Use workflow scripts to change file ownership at runtime if stricter permissions are required.
6. If you will be building your images outside of the PushToCompute
[CI/CD Pipeline](cicd.md), make sure the `/etc/NAE/screenshot.png`,
`/etc/NAE/screenshot.txt`, `/etc/NAE/license.txt`, and `/etc/NAE/AppDef.json`
metadata files exist and are pushed into the final layer of your docker image.
This may be done by adding the following to the last line of your `Dockerfile`:
```
RUN mkdir -p /etc/NAE && touch /etc/NAE/screenshot.png /etc/NAE/screenshot.txt /etc/NAE/license.txt /etc/NAE/AppDef.json
```
