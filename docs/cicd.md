# CI/CD Pipeline Overview

JARVICE provides an end-to-end continuous integration/continuous deployment (CI/CD) pipeline for compiling, deploying, testing, and maintaining containerized cloud computing applications.  This is all part of the PushToCompute&trade; feature of the platform.

This pipeline consists of various elements:

- Base images for facilitating building and local unit testing
- Integration with 3rd party Git repositories using trusted deployment keys
- Integration with 3rd party Docker registries using various forms of authentication
- Multiple application targets for various stages of the lifecycle (integration testing, system testing, production, etc.)

While Docker images may be built and pushed locally or built by 3rd party services (e.g. Docker Hub automated builds), JARVICE's PushToCompute&trade; provides multiplatform build services for both **x86_64** and **ppc64le** (64-bit Little Endian IBM POWER) as an integrated function. 
