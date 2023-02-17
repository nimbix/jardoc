# Jarvice Applications Push to Compute tutorial

![GlobalProcess](img/apps_tutorial/SuperNimbix.svg)

This tutorial should allow end users to build their own applications (apps) for Jarvice clusters
through Jarvice PushToCompute interface.

This tutorial assumes user is building applications based on `appdefversion` version `2`.

First part of the tutorial is dedicated to general knowledge 
and how to build and deploy a basic application.

Second part covers most standard use cases users could need
to build their application.

It is assumed user have already installed **docker** on its personal system.

It is recommended to first read all sections from part 1 (Global view) to part 5 (Review application parameters) before proceeding to desired application target examples.
Each of these general steps will help understand all features available, and provides key tips for new applications developers.

Table of content:

- [1. Global view](##1-global-view)
- [2. Hello world](##2-hello-world)
    * [2.1. Create Dockerfile](##21-create-dockerfile)
    * [2.2. Create AppDef.json](##22-create-appdefjson)
    * [2.3. Finalize image](##23-finalize-image)
    * [2.4. Register to registry (optional)](##24-register-to-registry--optional-)
    * [2.5. Push image](##25-push-image)
    * [2.6. Pull image with Push to Compute](##26-pull-image-with-push-to-compute)
    * [2.7. Run application in Jarvice](##27-run-application-in-jarvice)
    * [2.8. Gather logs](##28-gather-logs)
- [3. Important building guidelines](##3-important-building-guidelines)
    * [3.1. Repush image](##31-repush-image)
    * [3.2. Multi stages](##32-multi-stages)
    * [3.3. Optimize packages installation](##33-optimize-packages-installation)
    * [3.4. End with NAE](##34-end-with-nae)
- [4. Basic interactive job](##4-basic-interactive-job)
    * [4.1. Standard way](##41-standard-way)
    * [4.2. On an existing application image](##42-on-an-existing-application-image)
- [5. Review application parameters](##5-review-application-parameters)
    * [5.1. Commands](##51-commands)
    * [5.2. Commands parameters](##52-commands-parameters)
    * [5.3. Commands parameters advanced settings](##53-commands-parameters-advanced-settings)
- [6. Non interactive application](##6-non-interactive-application)
    * [6.1. Dockerfile](##61-dockerfile)
    * [6.2. AppDef](##62-appdef)
    * [6.3. Run application](##63-run-application)
- [7. Basic shell interactive application](##7-basic-shell-interactive-application)
    * [7.1. Create image](##71-create-image)
    * [7.2. Create calculator.py file](##72-create-calculatorpy-file)
    * [7.3. Create AppDef](##73-create-appdef)
    * [7.4. Launch and use](##74-launch-and-use)
- [8. Basic UI interactive application](##8-basic-ui-interactive-application)
    * [8.1. Create image](##81-create-image)
    * [8.2. Create AppDef](##82-create-appdef)
    * [8.3. Launch application](##83-launch-application)
- [9. MPI application](##9-mpi-application)
    * [9.1. Basic benchmark application](##91-basic-benchmark-application)
    * [9.2. Using another MPI implementation](##92-using-another-mpi-implementation)
- [10. Script based application](##10-script-based-application)
    * [10.1. Plain text script](##101-plain-text-script)
    * [10.2. Base64 encoded script](##102-base64-encoded-script)

## 1. Global view

In order to use Jarvice cluster, users need to build their own application container image, then push it to a registry accessible from the cluster, pull it using PushToCompute interface, and then simply submit jobs.

Process global view can be reduced to this simple schema:

![GlobalProcess](img/apps_tutorial/GlobalProcess.svg)

In order to explain in details this process, best way is to build a Hello World application, steps by steps.

## 2. Hello world

Objective of this Hello World application is simply to display a Hello World as output message of a Jarvice job.

In order to achieve that, we will need to go through multiple steps.
Process is not complex, but need steps to be understood in ordure to avoid basic issues.

### 2.1. Create Dockerfile

![GlobalProcess_step_1](img/apps_tutorial/GlobalProcess_step_1.svg)

First step is to create the Dockerfile that will be used to build application container image.

Create folder hello_world:

```
mkdir hello_world
cd hello_world
```

Create then a Dockerfile. A Dockerfile is a multi-steps description of how image should be created, and from what. 
We are going to start from basic Ubuntu image, as this source image is a widely used starting point.

To get more details on how this Dockerfile can be extended and used, refer to https://docs.docker.com/engine/reference/builder/ .

Create file `Dockerfile` with the following content, which should be self-explained:

```dockerfile
# Use Ubuntu latest image as starting point.
# This image will be automatically pulled from web at build.
FROM ubuntu:latest
```

Note: we did not specify any `CMD` or `ENDPOINT`. This is on purpose, as this will be handled by a separated file later.

Now, generate the hello_world image, tagging it as `tutorial:hello_word` (to get more details on how to build images, refer to https://docs.docker.com/engine/reference/commandline/build/):

```
docker build --tag="tutorial:hello_world" -f Dockerfile .
```

Once image has been successfully created, it is possible to test it by manually executing it:

```
:~$ docker run -it --rm tutorial:hello_world /usr/bin/echo "Hello World!"
Hello World!
:~$ docker run -it --rm tutorial:hello_world /usr/bin/cat /etc/os-release
NAME="Ubuntu"
VERSION="20.04.2 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.2 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
:~$
```

We can see here that image contains Ubuntu 20.04 release.

### 2.2. Create AppDef.json

![GlobalProcess_step_2](img/apps_tutorial/GlobalProcess_step_2.svg)

We now need to create the Jarvice application file.

Create folder NAE:

```
mkdir NAE
cd NAE
```

And create here `AppDef.json` file with the following content:

```json
{
    "name": "Hello World App",
    "description": "A very basic app thay says hello to world.",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Hello": {
            "path": "/usr/bin/echo",
            "interactive": false,
            "name": "Echo with arguments",
            "description": "Execute /usr/bin/echo with 'Hello World!' as argument.",
            "parameters": {
                "message": {
                    "name": "message",
                    "description": "hello world message",
                    "type": "CONST",
                    "value": "Hello World!",
                    "positional": true,
                    "required": true
                }
            }
        }
    },
    "image": {
        "type": "image/png",
        "data": ""
    }
}
```

Let’s review key parts of this file (when not detailed, just keep it as it):

```json
{
    "name": "Hello World App",
    "description": "A very basic app that says hello to world.",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
...
}
```

This first section of the file details general settings, like application name, a description, the author, if application is under license or not, and application classification.

```json
{
...
    "machines": [
        "*"
    ],
...
}
```

Machines allows you to restrict usage of the application to a specific set of machines registered in the targeted Jarvice cluster. For example, if your application is GPU dedicated, it would make no sense to run it on non-GPU nodes, and so only GPU able nodes should be added here.
Note that only Jarvice cluster administrator can create machines profiles on its cluster. Please contact your JXE administrator to get a detailed list of available machines.

```json
{
...
    "commands": {
        "Hello": {
            "path": "/usr/bin/echo",
            "interactive": false,
            "name": "Echo with arguments",
            "description": "Execute /usr/bin/echo with 'Hello World!' as argument.",
            ...
        }
    },
...
}
```

Commands section describes possible commands available with the application. An application can have multiple commands available (For this same image, we could have for example a command named `hello` with `/usr/bin/echo` with argument `Hello World!` as entry point, and a second command named `os infos` with `/usr/bin/cat` with argument `/etc/os-release` as entry point). This case will be covered later.

Path is application entry point, and interactive lets you decide if user will be able to interact with running application or if all running process is automated.

Refers to https://jarvice.readthedocs.io/en/latest/appdef/#commands-object-reference for more details.

```json
{
...
    "commands": {
        "Hello": {
            "path": "/usr/bin/echo",
            "interactive": false,
            "name": "Echo with arguments",
            "description": "Execute /usr/bin/echo with 'Hello World!' as argument.",
            "parameters": {
                "message": {
                    "name": "message",
                    "description": "hello world message",
                    "type": "CONST",
                    "value": "Hello World!",
                    "positional": true,
                    "required": true
                }
            }
        }
    },
...
}
```

Parameters are required and optional parameters passed to entry point as arguments or available in `/etc/JARVICE/jobenv.sh` during run (which can be imported by scripts or users).

In this example, we are going to pass a `CONST` with value `"Hello World!"` as parameter to entry point. This will result in `/usr/bin/echo "Hello World!"` being called. Other parameters (positional, etc.) will be described later.

Refer to https://jarvice.readthedocs.io/en/latest/appdef/#parameters-object-reference for more details.

```json
{
...
    "image": {
        "type": "image/png",
        "data": ""
    }
}
```

The last section, image, refer to logo that will be displayed inside Jarvice interface, for our application. It has to be encoded as text.
Let's add an image to our application. Download a basic sample from wikimedia:

```
wget https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/HelloWorld.svg/128px-HelloWorld.svg.png
```

And encode it with base64:

```
base64 -w 0 128px-HelloWorld.svg.png
```

Get the output (which can be very large for big images), and add it into AppDef.json inside `images.data` value:

```json
{
...
    "image": {
        "type": "image/png",
        "data": "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"
    }
}
```

Now that our AppDef file is ready, lets inject it into final image.

### 2.3. Finalize image

![GlobalProcess_step_3](img/apps_tutorial/GlobalProcess_step_3.svg)

Edit again Dockerfile and add a step to inject AppDef.json file into image, and another step to validate it:

```dockerfile
FROM ubuntu:latest

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
```

And build again image with this new Dockerfile:

```
:~$ docker build --tag="tutorial:hello_world" -f Dockerfile .
Sending build context to Docker daemon   16.9kB
Step 1/3 : FROM ubuntu:latest
 ---> 7e0aa2d69a15
Step 2/3 : COPY NAE/AppDef.json /etc/NAE/AppDef.json
 ---> 0f8bdf9181e6
Step 3/3 : RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
 ---> Running in eb716411eb8c
/bin/sh: 1: curl: not found
The command '/bin/sh -c curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate' returned a non-zero code: 127
:~$
```

You can see here that we are missing a tool: `curl`. This tool is contained in package curl. We have to add a step in Dockerfile to add it.

```dockerfile
FROM ubuntu:latest

RUN apt-get update; apt-get install curl -y --no-install-recommends;

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
```

Please note that we also added the `--no-install-recommends` to apt-get command. By default, apt-get or yum/dnf will try to install all recommended packages, generating huge images. 99% of time with app images, we do not need these packages. Setting `--no-install-recommends` for apt-get or `--nobest` for yum and dnf will sometime significantly reduce images sizes.

And build again:

```
:~$ docker build --tag="tutorial:hello_world" -f Dockerfile .
Sending build context to Docker daemon   16.9kB
Step 1/4 : FROM ubuntu:latest
 ---> 7e0aa2d69a15
Step 2/4 : RUN apt-get update; apt-get install curl -y --no-install-recommends;
 ---> Running in d97271342b81
...
Removing intermediate container d97271342b81
 ---> 88667cf55ce3
Step 3/4 : COPY NAE/AppDef.json /etc/NAE/AppDef.json
 ---> e167bfac86e5
Step 4/4 : RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
 ---> Running in 3ab8ff302d45
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  4237  100    21  100  4216    567   111k --:--:-- --:--:-- --:--:--  111k
{
    "valid": true
}
Removing intermediate container 3ab8ff302d45
 ---> a32ee72e76f6
Successfully built a32ee72e76f6
Successfully tagged tutorial:hello_world
:~$
```

We can see the output of Nimbix application validator:

```json
{
    "valid": true
}
```

Our image is ready.

Next step is to push image to a registry.

### 2.4. Register to registry (optional)

![GlobalProcess_step_4](img/apps_tutorial/GlobalProcess_step_4.svg)

This step is optional.

If you do not own a registry, or do not own an account on a third-party registry, you will need to obtain one.

In this tutorial, we are going to get a free account from https://hub.docker.com/ . There are others free registry available on the market, this is only an example. Note that by default, a free account on https://hub.docker.com/ allows unlimited public repositories, but only a single private repository. If you need to host multiple private images, you will need to consider another solution.

Create an account on https://hub.docker.com/.

Once account is created, sign in, and click on **Create Repository**.

![DockerHub_step_1](img/apps_tutorial/docker_hub_step_1.png)

Fill required information, as bellow:

![DockerHub_step_2](img/apps_tutorial/docker_hub_step_2.png)

And click **Create**.

Our application repository is now created and ready to host our image.
Pull command is displayed on repository page:

![DockerHub_step_3](img/apps_tutorial/docker_hub_step_3.png)

### 2.5. Push image

![GlobalProcess_step_5](img/apps_tutorial/GlobalProcess_step_5.svg)

Now that image is ready and registry repository is ready to host image, we need to login to registry and upload image into repository.

Check image is ready:

```
:~$ docker images | grep tutorial
tutorial                                                           hello_world                                       a32ee72e76f6   5 hours ago     124MB
:~$
```

Now login to docker hub registry, using your credentials (or login to your private registry if not using docker, command may vary):

```
:~$ docker login
...
Login Succeeded
:~$
```

Now tag and push image. We are going to tag it as `v1` version. Do not copy as it the bellow command, replace `oxedions` by your docker hub user name to match your repository.

```
docker tag tutorial:hello_world oxedions/app-hello_world:v1
```

And push image into registry (again, replace `oxedions` by your docker hub user name to match your repository):

```
:~$ docker push oxedions/app-hello_world:v1
The push refers to repository [docker.io/oxedions/app-hello_world]
42221693cbf0: Pushed
1594cdd4a24c: Pushed
...
v1: digest: sha256:7c37fb5840d4677f5e8b45195b8aa64ef0059ccda9fcefc0df62db49e426d805 size: 1363
:~$
```

Image is now pushed and can be pulled from Jarvice Push to Compute interface.

### 2.6. Pull image with Push to Compute

![GlobalProcess_step_6](img/apps_tutorial/GlobalProcess_step_6.svg)

We are ready to inject our image into our Jarvice cluster.

Login as usual user, and in the main interface, go to **PushToCompute** tab on the right:

![PushToCompute_step_1](img/apps_tutorial/PTC_step_1.png)

Then, click on **New** to create a new application.

![PushToCompute_step_2](img/apps_tutorial/PTC_step_2.png)

Fill only `App ID` and `Docker repository`. Everything else will be automatically grabbed from the AppDef.json file created with the application. Then click **OK**.

![PushToCompute_step_3](img/apps_tutorial/PTC_step_3.png)

Now that application is registered into Jarvice, we need to request an image pull, so that Jarvice will retrieve AppDef.json embed into image and update all application data. To do so, click on the small burger on the top left of the application, then **Pull**, confirm pull by clicking **OK**, and close Pull response windows. Then wait few seconds for image to be pulled.

![PushToCompute_step_4](img/apps_tutorial/PTC_step_4.png)

Once image has been pulled, you can see that application logo has been updated by our base64 encoded png.

![PushToCompute_step_5](img/apps_tutorial/PTC_step_5.png)

It is possible to check application logs / history to see pull process. To do so, press burger again, then go to **History**, and you can visualise here the pull process logs. Close the windows once read.

![PushToCompute_step_6](img/apps_tutorial/PTC_step_6.png)

Application is now ready to be run in Jarvice.

### 2.7. Run application in Jarvice

![GlobalProcess_step_7](img/apps_tutorial/GlobalProcess_step_7.svg)

To submit an application job to the cluster, simply click on the application card:

![Run_Application_step_1](img/apps_tutorial/Run_Application_step_1.png)

Then on the application window, click on **Echo With Arguments** (remember, all of this was set in the AppDef.json file when building application image).

![Run_Application_step_2](img/apps_tutorial/Run_Application_step_2.png)

In the next window, select the Machine type to be used. For this tutorial hello world, you can use the smallest available.

Then click **Submit** to submit the application job and run the application.

![Run_Application_step_3](img/apps_tutorial/Run_Application_step_3.png)

If all goes well, you are automatically redirected to **Dashboard** tab. If not, click on it on the right. You can see here that your job has been submitted, and is now queued. After few seconds/minutes, job will start and application will run. Note the job number here: 11776. This will be the reference for job logs later.

![Run_Application_step_4](img/apps_tutorial/Run_Application_step_4.png)

Once application has finished to run, you will see it marked as **Completed**.

![Run_Application_step_5](img/apps_tutorial/Run_Application_step_5.png)

### 2.8. Gather logs

![GlobalProcess_step_8](img/apps_tutorial/GlobalProcess_step_8.svg)

Now that our application as run, lets gather few logs about it. Note that if the application failed to run, Jarvice local Administrator have access to advanced logs that might help to debug.

First, to grab job output, simply click on the small arrow on the right of the "completed" job card.

We can see that our "Hello World!" message is here.

![Gather_Logs_step_1](img/apps_tutorial/Gather_Logs_step_1.png)

Now, click on **Jobs** tab on the left, and then **History**. You can see here all your jobs history.

![Gather_Logs_step_2](img/apps_tutorial/Gather_Logs_step_2.png)

Last part, it is possible to go into **Account** tab on the right, then **Team Log** on the left. In the central area, we can see all team's job.

![Gather_Logs_step_3](img/apps_tutorial/Gather_Logs_step_3.png)

This is the general process to create an application for Jarvice and inject it through PushToCompute. You may need to iterate time to time between image creation and application jobs, to fix application execution issues. This is an expected behavior.

Also, if too much issues, switch for a time to interactive application (seen later in this documentation) to debug application, and then switch back to non-interactive.

We can now proceed to more productive applications and general guidelines. Next examples will not be as detailed as this one as process is always the same.

## 3. Important building guidelines

Before proceeding to more examples, it is important to keep in mind few image building guidelines.

### 3.1. Repush image

When you need to fix image and rebuild it, you need to delete local tag and create it again in order to be able to push again image.

Let’s take an example: we need to fix our hello_world application image, since we made a mistake in it.

First, delete local tag to remote repository:

```
docker rmi oxedions/app-hello_world:v1
```

Then build fixed image, it will update local copy:

```
docker build --tag="tutorial:hello_world" -f Dockerfile .
```

Note: sometime, you may want to force rebuilding all the steps, so forcing docker not using build cache. To do so, add `--no-cache` to `docker build` line.

And tag and push again local copy:

```
docker tag tutorial:hello_world oxedions/hello_world:v1
docker push oxedions/hello_world:v1
```

Don't forget to request a new pull in Jarvice interface to grab latest image NAEs.

### 3.2. Multi stages

Application images can be really big. Images builder should care about images size, and so optimize build process in order to save disk, memory, and bandwidth.

Docker containers images work with layers. Each step generates a layer that is stacked over others (like a git repository).
This means that if user import (ADD/COPY/RUN wget) huge archives or files or installer binaries during process, even if file is deleted in a next step, this file will be 
stored in image stack, and so will grow image size without usage.

In order to prevent that, it is common and recommended to use multi-stages builds.

Idea is simple: instead of having a single stage in Dockerfile, we create multiple, and import all what we need in the final stage from previous ones, as only this last stage will be in our final image.

Let’s take an example:

We want to install Intel Parallel Studio Compilers. Archive is big (> 3GB).

In stage 0 (counter start at 0), we **ADD** archive to image, and install Intel product into `/opt/intel` folder. Final image layers contains both installer archive, extracted archive content, and final installed product.

Then, in second stage we simply say "now copy all that is in `/opt/intel` from stage 0 into current stage, so final image of this stage only contains final installed product in its layers, we don't have archive and extracted archive in final application image layer, which saves a LOT of disks and bandwidth.

As a simple example here, lets create a naive standard image that would download and install ffmpeg, the famous video processing tool:

```dockerfile
FROM ubuntu:latest

RUN apt-get update; apt-get install tar xz-utils wget -y;

RUN wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz;

RUN tar xvJf ffmpeg-release-amd64-static.tar.xz;

RUN cd ffmpeg-5.0.1-amd64-static; cp ffmpeg /usr/bin/ffmpeg;
```

Build it:

```
docker build --tag="tutorial:ffmpeg" -f Dockerfile .
```

And check size of image:

```
:~$ docker images | grep ffmpeg
tutorial                                                           ffmpeg                                            f2da746cb648   12 seconds ago   401MB
:~$
```

401 MB, this is a lot for such a small program. Problem here is: our image has in memory apt cache, few packages installed needed to download and extract archive, archive itself, and archive content that we do not need.

Let’s update it to a multi-stage build now:

```dockerfile
# Stage 0, lets give it a name for convenience: download_extract_ffmpeg
FROM ubuntu:latest AS download_extract_ffmpeg

RUN apt-get update; apt-get install tar xz-utils wget -y;

RUN wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz;

RUN tar xvJf ffmpeg-release-amd64-static.tar.xz;

RUN cd ffmpeg-5.0.1-amd64-static; cp ffmpeg /usr/bin/ffmpeg;

# Stage 1, we simply import /usr/bin/ffmpeg from stage download_extract_ffmpeg
FROM ubuntu:latest 

COPY --from=download_extract_ffmpeg /usr/bin/ffmpeg /usr/bin/ffmpeg
```

Note: we could also have `COPY --from=0`, stage number are accepted. But using names is more convenient for large dockerfiles.

Let’s build again our image now, and we will need this time to prevent cache usage to be sure image is done again from scratch.

```
docker build --no-cache --tag="tutorial:ffmpeg" -f Dockerfile .
```

And now let’s check again image size:

```
:~$ docker images | grep ffmpeg
tutorial                                                           ffmpeg                                            610696e0d2eb   13 seconds ago   151MB
:~$
```

If you take a deeper look, you can see the stage 0 download_extract_ffmpeg in images list:

```
:~$ docker images
REPOSITORY                                                         TAG                                               IMAGE ID       CREATED          SIZE
tutorial                                                           ffmpeg                                            610696e0d2eb   12 minutes ago   151MB
<none>                                                             <none>                                            8a182a98de1f   12 minutes ago   401MB
:~$
```

We have our first 401MB image, without name, only ID, and our stage 1 image, as final ffmpeg image. We can safely remove intermediate stage now (or keep it if you wish to benefit from cache if you think you will need to rebuild same image to fix things in stage 1):

```
docker rmi 8a182a98de1f
```

We went from 401MB to 151MB. This is a huge size reduction. While with this small example image size does not really matter, with huge applications, this could have a significant impact.

For more details, please visit official documentation on multi stage builds: https://docs.docker.com/develop/develop-images/multistage-build/

### 3.3. Optimize packages installation

Most of the time, final image will need to have few packages installed.
In order to reduce size of image, and prevent waste, two actions can be done:

* Prevent recommended/best packages
* Pipe all packages management on the same line, ending with cache clean

As an example, lets create an image with Python 3 and curl installed. A basic Dockerfile would be:

```
FROM ubuntu:latest

RUN apt-get update
RUN apt-get install python3 curl -y
```

Build image:

```
docker build --tag "size" -f Dockerfile .
```

The result image will be of size:

```
:~$ docker images | grep size
size                                                               latest                                              0bf03cdd01d2   12 seconds ago   159MB
:~$ ls
```

Now, simple tune image by adding `--no-install-recommends` and having all packages task, including cache clean, as a single RUN task.

```
FROM ubuntu:latest

RUN apt-get update && apt-get install python3 curl -y --no-install-recommends && apt-get clean
```

Resulting image size is now:

```
:~$ docker images | grep size
size                                                               latest                                              79b6275b8518   About a minute ago   150MB
:~$ ls
```

We saved 9MB. With bigger packages, like desktop applications, size reduction is even larger and can sometime leads to around 30-40% size reduction.

### 3.4. End with NAE

We have seen that container images are multi layers images.

When pulling an image into Jarvice, Jarvice system needs to grab NAE content (AppDef.json file) from layers. To do so, it will search in each layer, starting from last one, for files. This process can take a long time. To speedup pull process, it is recommended to always perform NAE copy at last stage of a build, or to simply add a "touch" line that will simply contains copy of files:

```dockerfile
RUN mkdir -p /etc/NAE && touch /etc/NAE/screenshot.png /etc/NAE/screenshot.txt /etc/NAE/license.txt /etc/NAE/AppDef.json
```

This line has to be adapted to files provided with the application image. If you only provide AppDef.json file, reduce the line to:

```dockerfile
RUN mkdir -p /etc/NAE && touch /etc/NAE/AppDef.json
```

So, for hello world application, this would be:

```dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get install curl -y --no-install-recommends && apt-get clean

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

RUN mkdir -p /etc/NAE && touch /etc/NAE/AppDef.json
```

For such a small image, it does not worth it, but for very large images, this small tip can have interesting benefit.

## 4. Basic interactive job

Before reviewing available application parameters, next step is to be able to launch interactive jobs.

Interactive jobs are very useful to debug when creating an application, as you can test launch application end point yourself,
and debug directly inside the Jarvice cluster context.

### 4.1. Standard way

Create a new application folder aside app-hello_world folder, called app-interactive_shell:

```
mkdir app-interactive_shell
cd app-interactive_shell
mkdir NAE
```

Now, create here a Dockerfile with the following content:

```dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get install curl -y --no-install-recommends && apt-get clean

RUN echo "Sarah Connor?" > /knock_knock ;

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
```

Then create AppDef.json in NAE folder with the following content:

```json
{
    "name": "Interactive application",
    "description": "Start bash command in a gotty",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Gotty": {
            "path": "/bin/bash",
            "webshell": true,
            "name": "Gotty Shell",
            "description": "Start bash command in a gotty",
            "parameters": {}
        }
    },
    "image": {
        "type": "image/png",
        "data": ""
    }
}
```

Now build application:

```
:~$ docker build --tag="tutorial:interactive_shell" -f Dockerfile .
Sending build context to Docker daemon  4.096kB
Step 1/5 : FROM ubuntu:latest
 ---> 7e0aa2d69a15
Step 2/5 : RUN apt-get update; apt-get install curl -y;
 ---> Using cache
 ---> 88667cf55ce3
Step 3/5 : RUN echo "Sarah Connor?" > /knock_knock ;
 ---> Running in 12a077247095
Removing intermediate container 12a077247095
 ---> b4218b95fca0
Step 4/5 : COPY NAE/AppDef.json /etc/NAE/AppDef.json
 ---> 9e360a999e3f
Step 5/5 : RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
 ---> Running in 7dd760c1f55e
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   963  100    21  100   942    333  14952 --:--:-- --:--:-- --:--:-- 15285
{
    "valid": true
}
Removing intermediate container 7dd760c1f55e
 ---> 3fbe9926327b
Successfully built 3fbe9926327b
Successfully tagged tutorial:interactive_shell
:~$
```

Then as for hello world application, create a dedicated repository on docker hub, and tag image and push it:

```
docker tag tutorial:interactive_shell oxedions/app-interactive_shell:v1
docker push oxedions/app-interactive_shell:v1
```

Once image is pushed, add application into Jarvice as before. Note that this time, we didn't base64 encoded a png image, so default image is used.

When clicking on application card, you should now have:

![app_interactive_shell_step_1](img/apps_tutorial/app_interactive_shell_step_1.png)

Click on **Gotty Shell**, and in the next window, observe that you can tune the command to be launched if desired (here default value is `/bin/bash` as requested in AppDef.json file).
 
![app_interactive_shell_step_2](img/apps_tutorial/app_interactive_shell_step_2.png)

Click on **Submit** to launch the job.

Once job is started, it is possible to click on its card to open a new tab in web browser.

![app_interactive_shell_step_3](img/apps_tutorial/app_interactive_shell_step_3.png)

In the new tab, you now have an interactive bash shell. It is possible from here to check file created via Dockerfile (`/knock_knock`):

![app_interactive_shell_step_4](img/apps_tutorial/app_interactive_shell_step_4.png)

### 4.2. On an existing application image

Sometime, in order to debug an app image, and launch entry point manually to check what is failing, it is useful to temporary switch it to an interactive shell. This basically allows you to "enter" the image inside the running context, and debug interactively.

There is no need to rebuild the image for that, we can live "hack" the AppDef inside Jarvice interface.

Let’s take our hello world application. Click on its burger, and select **Edit**.

![app_interactive_shell_step_5](img/apps_tutorial/app_interactive_shell_step_5.png)

Now, go into tab **APPDEFF** and copy all curent AppDef content from the text area. Edit this json into a text editor, and "hack" it this way (explanations follow):

```json
{
    "name": "Hello World App",
    "description": "A very basic app thay says hello to world.",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Hello": {
            "path": "/usr/bin/echo",
            "interactive": false,
            "name": "Echo with arguments",
            "description": "Execute /usr/bin/echo with 'Hello World!' as argument.",
            "parameters": {
                "message": {
                    "name": "message",
                    "description": "hello world message",
                    "type": "CONST",
                    "value": "Hello World!",
                    "positional": true,
                    "required": true
                }
            }
        },
        "Gotty": {
            "path": "/bin/bash",
            "webshell": true,
            "name": "Gotty shell",
            "description": "Enter an interactive shell",
            "parameters": {}
        }
    },
    "image": {
        "type": "image/png",
        "data": "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"
    }
}
```

Basically, only changes made are the additional command entry added called **Gotty**.

Then click on **LOAD FROM FILE** and select the hacked json file. This will update application AppDef inside the Jarvice cluster.

![app_interactive_shell_step_6](img/apps_tutorial/app_interactive_shell_step_6.png)

Now, when clicking on application to launch it, you can observe we have a second possible entry point into image (you may need to refresh page):

![app_interactive_shell_step_7](img/apps_tutorial/app_interactive_shell_step_7.png)

Using this entry point starts an interactive shell, and allows to debug inside the image: once logged, you can start manually the desired command, here `/usr/bin/echo Hello World!`.

Once issues are solved, AppDef will be restored when pulling fixed image into Jarvice.

## 5. Review application parameters

Let’s review now available parameters in AppDef for commands entry. We will not cover all of them in this guide, only the most used ones. Please refer to [Appdf commands object reference](https://jarvice.readthedocs.io/en/latest/appdef/#commands-object-reference) and [Appdf parameters object reference](https://jarvice.readthedocs.io/en/latest/appdef/#parameters-object-reference) for more details.

Target here is to test most of the possibilities offered.

### 5.1. Commands

Let's focus on commands, which is the level above parameters:

```json
...
    "commands": {
        "Hello": {
            "path": "/usr/bin/echo",
            "interactive": false,
            "name": "Echo with arguments",
            "description": "Execute /usr/bin/echo with 'Hello World!' as argument.",
            "parameters": {}
            }
        }
...
```

Basic commands can take the following settings: (note: an * means key is mandatory)

* <u>**path***</u>: Command entry point which is run when application start.
* <u>**name***</u>: Command’s name, which is used as the title of the command in the Jarvice interface.
* <u>**description***</u>: Description of the command’s functionality that is used in the Jarvice interface.
* <u>**interactive**</u>: (default to `false`) defines if application execution should return to user an URL to interact with execution (automatically forced to true if webshell or desktop are set to true).
* <u>**webshell***</u>: (default to `false`) run command inside a gotty shell.
* <u>**desktop***</u>: (default to `false`) run command inside Jarvice Xfce desktop (assumes image includes https://github.com/nimbix/jarvice-desktop).
* <u>**mpirun***</u>: (default to `false`) run command under mpi environment.
* <u>**verboseinit***</u>: (default to `false`) enable verbose init app execution phase, including parameters passed to command.
* <u>**cmdscript***</u>: if set, will trigger cmdscript execution mode. Value of this key will be written into a file matching **path** set above, and executed. This allows injecting scripts directly from AppDef json. User can pass a single line plain text script, or a base64 encoded script (auto detected, allows multilines scripts).
* <u>**parameters***</u>: Parameters are used to construct the arguments passed to the command. If no parameters are needed, set it to `{}`

When using standalone binary applications, no parameters are needed. However, most of the time, some 
additional settings are required by applications' binary (input file path, parameters, etc.).
You may also wish that user could define some application settings.

This is where parameters are needed.

### 5.2. Commands parameters

Commands parameters allows to:

* Force specific read only values to be passed to application's entry point as arguments (CONST)
* Allows users to tune settings to be passed to application's entry point or scripts (with mandatory or optional values)

Remember the Command parameter to be set for interactive gotty shell example:

```json
...
    "commands": {
        "echo": {
            "path": "/bin/echo",
            "interactive": true,
            "name": "Say hello",
            "description": "Say hello example",
            "parameters": {
                "command": {   <<<<<<<<<<<<<< This
                    "name": "To who?",
                    "description": "Say hello to who?",
                    "type": "STR",
                    "value": "hello world!",
                    "positional": true,
                    "required": true
                }
            }
        }
    }
...
```

![parameters_step_1.png](img/apps_tutorial/parameters_step_1.png)

It is possible to create a detailed environment for an application with a variety of input format.

There are multiple available parameters types: `CONST`, `STR`, `INT`, `FLOAT`, `RANGE`, `BOOL`, `selection`, `FILE`, `UPLOAD`.

[A detailed list of available values/keys is available.](https://jarvice.readthedocs.io/en/latest/appdef/#parameter-type-reference)

In order to simplify visual understanding, you can find bellow a table with a screenshot of what each type would generate in job user interface:

| Type      |      Screenshot      |
|-----------|----------------------|
| CONST     | Nothing will be displayed in interface |
| STR       | ![type_STR](img/apps_tutorial/type_STR.png) |
| INT       | ![type_INT](img/apps_tutorial/type_INT.png) |
| RANGE     | ![type_RANGE](img/apps_tutorial/type_RANGE.png) |
| FLOAT     | ![type_FLOAT](img/apps_tutorial/type_FLOAT.png) |
| BOOL      | ![type_BOOL](img/apps_tutorial/type_BOOL.png) |
| selection | ![type_selection](img/apps_tutorial/type_selection.png) |
| FILE      | ![type_FILE](img/apps_tutorial/type_FILE.png) |
| UPLOAD    | ![type_UPLOAD](img/apps_tutorial/type_UPLOAD.png) |


In order to understand all possible combination, lets create a specific application. This application makes no sense, this is for testing and understanding purposes.

Note: if you want to play with parameters, remember that you can directly edit AppDef Json in Jarvice UI by editing application. For testing purposed, do not bother building and pushing/pulling an image: simply edit directly in Jarvice UI by pushing updated AppDef jsons.

Create a new application called app-reverse_engineer, with the following Dockerfile:

```dockerfile
FROM ubuntu:latest

RUN apt-get update; apt-get install curl -y;

COPY launch.sh /launch.sh

RUN chmod +x /launch.sh;

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
```

Then create in same folder a file called `launch.sh` with the following content:

```bash
#!/usr/bin/env bash
echo Launch script is starting

echo
echo Checking arguments passed directly to entry point
cat << EOF
Arguments passed: $@
EOF

echo
echo Checking job environment
cat /etc/JARVICE/jobenv.sh

echo
echo Checking job information
cat /etc/JARVICE/jobinfo.sh

echo
echo Checking job cores and nodes
echo   - cores
cat /etc/JARVICE/cores
echo   - nodes
cat /etc/JARVICE/nodes

echo
echo Checking uploaded file
cat /opt/JARVICE/file.txt

echo
echo Script end
```

Note: we are using `cat` and not `echo` to display parameters, to avoid echo evaluating some values.

Create the following `AppDef.json` file with all possible types available, sometime combined with different settings.

```json
{
    "name": "Reverse engineer application",
    "description": "A environment test application",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Hello": {
            "path": "/launch.sh",
            "interactive": false,
            "name": "Test script",
            "description": "Execute launch.sh",
            "parameters": {
                "const_1": {
                    "name": "const_1_name",
                    "description": "const_1_description",
                    "type": "CONST",
                    "value": "const_1_value",
                    "positional": true,
                    "required": true
                },
                "const_2": {
                    "name": "const_2_name",
                    "description": "const_2_description",
                    "type": "CONST",
                    "value": "const_2_value",
                    "positional": false,
                    "required": true
                },
                "const_3": {
                    "name": "const_3_name",
                    "description": "const_3_description",
                    "type": "CONST",
                    "value": "const_3_value",
                    "positional": true,
                    "required": true,
                    "variable": true
                },
                "str_1": {
                    "name": "str_1_name",
                    "description": "str_1_description",
                    "type": "STR",
                    "value": "str_1_value",
                    "positional": true,
                    "required": true,
                    "variable": false
                },
                "str_2": {
                    "name": "str_2_name",
                    "description": "str_2_description",
                    "type": "STR",
                    "value": "str_2_value",
                    "positional": true,
                    "required": true,
                    "variable": true
                },
                "str_3": {
                    "name": "str_3_name",
                    "description": "str_3_description",
                    "type": "STR",
                    "value": "str_3_value",
                    "positional": true,
                    "required": false,
                    "variable": false
                },
                "int_1": {
                    "name": "int_1_name",
                    "description": "int_1_description",
                    "type": "INT",
                    "value": 2,
                    "min": 0,
                    "max": 10,
                    "positional": true,
                    "required": true,
                    "variable": false
                },
                "float_1": {
                    "name": "float_1_name",
                    "description": "float_1_description",
                    "type": "FLOAT",
                    "value": "1.2",
                    "min": "0.0",
                    "max": "10.0",
                    "positional": true,
                    "required": true,
                    "variable": false
                },
                "range_1": {
                    "name": "range_1_name",
                    "description": "range_1_description",
                    "type": "RANGE",
                    "value": 2,
                    "min": 0,
                    "max": 10,
                    "step": 1,
                    "positional": true,
                    "required": true,
                    "variable": false
                },
                "bool_1": {
                    "name": "bool_1_name",
                    "description": "bool_1_description",
                    "type": "BOOL",
                    "value": true,
                    "positional": true,
                    "required": true,
                    "variable": false
                },
                "selection_1": {
                    "name": "selection_1_name",
                    "description": "selection_1_description",
                    "type": "selection",
                    "values": ["selection_1_val1","selection_1_val2"],
                    "positional": true,
                    "required": true,
                    "variable": false
                },
                "file_1": {
                    "name": "file_1_name",
                    "description": "file_1_description",
                    "type": "FILE",
                    "positional": true,
                    "required": true,
                    "variable": false
                },
                "upload_1": {
                    "name": "upload_1_name",
                    "description": "upload_1_description",
                    "type": "UPLOAD",
                    "target": "file.txt",
                    "filter": ".txt",
                    "size": 4096,
                    "required": true
                }
            }
        }
    },
    "image": {
        "type": "image/png",
        "data": ""
    }
}
```

Build application, create a repository to host it, and pull it into Jarvice.
Once done, click on **Test Script** to open application's job settings interface.

![reverse_engineer_step_1](img/apps_tutorial/reverse_engineer_step_1.png)

In **GENERAL**, you can observe all parameters set in our AppDef file.

![reverse_engineer_step_2](img/apps_tutorial/reverse_engineer_step_2.png)

Observe also in **OPTIONAL** tab the non-required `STR` value set in AppDef.

![reverse_engineer_step_3](img/apps_tutorial/reverse_engineer_step_3.png)

Ensure all fields are set (for this example a txt file with `coucou` as content was uploaded in upload_1 parameter), and click on **Submit** to submit application job.

Once job completed, check job output log, you should have:

```
INIT[1]: Initializing networking...
INIT[1]: Reading keys...
INIT[1]: Finalizing setup in application environment...
INIT[1]: WARNING: Cross Memory Attach not available for MPI applications
INIT[1]: Platform fabric and MPI libraries successfully deployed
INIT[1]: Detected preferred MPI fabric provider: tcp
INIT[1]: Securing application environment...
INIT[1]: Configuring user: nimbix ...
INIT[1]: /home/nimbix does not exist or is external
INIT[1]: Waiting for job configuration before executing application...
INIT[1]: hostname: jarvice-job-11859-nw2fm
INIT[64]: HOME=/home/nimbix
################################################################################

Launch script is starting

Checking arguments passed directly to entry point
Arguments passed: const_2 const_2_value const_1_value str_1_value str_3_value 2 1.2 0 bool_1 selection_1_val1 /data/jellyfish-3-mbps-hd-h264.mkv

Checking job environment
:
const_3=\c\o\n\s\t\_\3\_\v\a\l\u\e
str_2=\s\t\r\_\2\_\v\a\l\u\e

Checking job information
:
JOB_NAME="20220420201746-IZP8L-bleveugle-reverse_engineer-bleveugle_s1"
JOB_LABEL=
JOB_PRIVATEIP=10.88.4.13
JOB_PUBLICIP=

Checking job cores and nodes
- cores
jarvice-job-11864-mrdvs
- nodes
jarvice-job-11864-mrdvs

Checking files in /opt
coucou
Script end
```

You can see that:

* `const_2` value was passed first in arguments, because `positional` is `false`, and was a combination of the main entry key and its value. This is useful to define parameters like `-c blue`:
```
                  "-c": {
                    "name": "define color",
                    "description": "-c parameters allows to change color",
                    "type": "CONST",
                    "value": "blue",
                    "positional": false,
                    "required": true
                },
```
* `const_3` and `str_2` were not passed as arguments, but instead are available in file `/etc/JARVICE/jobenv.sh`, which can be sourced from scripts to be used as variables.
* Other values were passed in the same order than defined in the AppDef file as arguments.
* Uploaded file was correctly uploaded as `/opt/file.txt`.

We have seen all possible and existing parameters. You can now use the ones needed to create tunable applications for Jarvice.

### 5.3. Commands parameters advanced settings

It is possible to use conditionals on parameters keys, combined with a boolean value, in order to trigger specific parameters only when needed.

Scenario. We have an application that accepts 2 
kind of licences : either a full file path, or a remote server (ip:port).

We can create a boolean, to only pass to application needed value (and prevent possible user miss-usage).

```json
            "parameters": {
                "license": {
                    "name": "License argument",
                    "description": "License argument",
                    "type": "CONST",
                    "value": "-i",
                    "required": true
                },
                "license_file_path": {
                    "name": "License file path",
                    "description": "License file path provided by your beloved administrator",
                    "type": "STR",
                    "value": "",
                    "if": [
                        "license_is_file"
                    ],
                    "required": false
                },
                "license_server": {
                    "name": "License server",
                    "description": "License server ip:port to reach",
                    "type": "STR",
                    "value": "black",
                    "variable": true,
                    "ifnot": [
                        "license_is_file"
                    ],
                    "required": false
                },
                "license_is_file": {
                    "name": "Use a file based license",
                    "description": "Use a file based license instead of a remote server?",
                    "type": "BOOL",
                    "value": false,
                    "required": true
                }
            }
```

In this specific case, if `license_is_file` boolean is true, then command will be: `-i license_file_path.value`, else it will be `-i license_server.value`.

## 6. Non interactive application

Non-interactive applications are very common.

Users specify some settings via provided application command parameters (input file or folder, solver to use, tunings, etc.) and launch job. Job executes then in background, and user can collect result once job has ended.

Users can also check application logs in their user space on Jarvice interface.

Let’s create a very basic **ffmpeg** application that will be used to convert uploaded video to `h265` codec. User will be able to set `crf` (video quality). To simplify this tutorial, we will not consider anything else than video (sound streams, subtitles, etc. will be ignored).

Note that you can easily find video samples here: [jell.yfish.us](https://jell.yfish.us/).

### 6.1. Dockerfile

We can already re-use the multi stages example above:

```dockerfile
# Stage 0, let’s give it a name for convenience: download_extract_ffmpeg
FROM ubuntu:latest AS download_extract_ffmpeg

RUN apt-get update; apt-get install tar xz-utils wget -y;

RUN wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz;

RUN tar xvJf ffmpeg-release-amd64-static.tar.xz;

RUN cd ffmpeg-5.0.1-amd64-static; cp ffmpeg /usr/bin/ffmpeg;

# Stage 1, we simply import /usr/bin/ffmpeg from stage download_extract_ffmpeg
FROM ubuntu:latest

RUN apt-get update; apt-get install curl -y; apt-get clean;

COPY --from=download_extract_ffmpeg /usr/bin/ffmpeg /usr/bin/ffmpeg

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

RUN mkdir -p /etc/NAE && touch /etc/NAE/AppDef.json
```

### 6.2. AppDef

Let’s now create a related `AppDef.json` file:

```json
{
    "name": "Video conversion",
    "description": "A basic video conversion app, for a tutorial",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Convert": {
            "path": "/usr/bin/ffmpeg",
            "interactive": false,
            "name": "Convert video",
            "description": "Convert video to h265 using ffmpeg",
            "parameters": {
                "-i": {
                    "name": "Input file parameter",
                    "description": "File to be processed parameter",
                    "type": "CONST",
                    "value": "-i",
                    "positional": true,
                    "required": true
                },
                "input_file": {
                    "name": "Input file path",
                    "description": "File to be processed parameter path",
                    "type": "FILE",
                    "positional": true,
                    "required": true
                },
                "-c_v": {
                    "name": "Video codec parameter",
                    "description": "Video codec parameter",
                    "type": "CONST",
                    "value": "-c:v",
                    "positional": true,
                    "required": true
                },
                "libx265": {
                    "name": "Video codec h265",
                    "description": "Video codec h265",
                    "type": "CONST",
                    "value": "libx265",
                    "positional": true,
                    "required": true
                },
                "-crf": {
                    "name": "crf parameter",
                    "description": "crf parameter (quality)",
                    "type": "CONST",
                    "value": "-crf",
                    "positional": true,
                    "required": true
                },
                "crf_value": {
                    "name": "crf value",
                    "description": "crf value, between 0 (quality lossless) and 51 (worse quality). Default is 28.",
                    "type": "RANGE",
                    "value": 28,
                    "min": 0,
                    "max": 51,
                    "step": 1,
                    "positional": true,
                    "required": true
                },
                "output_file": {
                    "name": "Output file",
                    "description": "Output file path and name. Must be /data/XXX .",
                    "type": "STR",
                    "value": "/data/out.mkv",
                    "positional": true,
                    "required": true
                }
            }
        }
    },
    "image": {
        "type": "image/png",
        "data": ""
    }
}
```

User will be able to set CRF video quality value, and output file path.

### 6.3. Run application

Build and upload to cluster application.

Launch a job, using an input sample. In this test, we used `jellyfish-3-mbps-hd-h264.mkv` file.

Set CRF quality. We let 28 here as default.

Then submit. Note that video processing benefits from multi cores, and so you should select 
a machine with multiple cores. Memory doesn't matter here, 1Gb is enough.

Once processed, you should see the following result:

```
INIT[1]: Initializing networking...
INIT[1]: Reading keys...
INIT[1]: Finalizing setup in application environment...
INIT[1]: WARNING: Cross Memory Attach not available for MPI applications
INIT[1]: Platform fabric and MPI libraries successfully deployed
INIT[1]: Detected preferred MPI fabric provider: tcp
INIT[1]: Securing application environment...
INIT[1]: Configuring user: nimbix ...
INIT[1]: /home/nimbix does not exist or is external
INIT[1]: Waiting for job configuration before executing application...
INIT[1]: hostname: jarvice-job-12180-z9ldv
INIT[64]: HOME=/home/nimbix
################################################################################
ffmpeg version 5.0.1-static https://johnvansickle.com/ffmpeg/  Copyright (c) 2000-2022 the FFmpeg developers
  built with gcc 8 (Debian 8.3.0-6)
  configuration: --enable-gpl --enable-version3 --enable-static --disable-debug --disable-ffplay --disable-indev=sndio --disable-outdev=sndio --cc=gcc --enable-fontconfig --enable-frei0r --enable-gnutls --enable-gmp --enable-libgme --enable-gray --enable-libaom --enable-libfribidi --enable-libass --enable-libvmaf --enable-libfreetype --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg --enable-librubberband --enable-libsoxr --enable-libspeex --enable-libsrt --enable-libvorbis --enable-libopus --enable-libtheora --enable-libvidstab --enable-libvo-amrwbenc --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-libdav1d --enable-libxvid --enable-libzvbi --enable-libzimg
  libavutil      57. 17.100 / 57. 17.100
  libavcodec     59. 18.100 / 59. 18.100
  libavformat    59. 16.100 / 59. 16.100
  libavdevice    59.  4.100 / 59.  4.100
  libavfilter     8. 24.100 /  8. 24.100
  libswscale      6.  4.100 /  6.  4.100
  libswresample   4.  3.100 /  4.  3.100
  libpostproc    56.  3.100 / 56.  3.100
Input #0, matroska,webm, from '/data/jellyfish-3-mbps-hd-h264.mkv':
  Metadata:
    encoder         : libebml v1.2.0 + libmatroska v1.1.0
    creation_time   : 2016-02-06T03:58:03.000000Z
  Duration: 00:00:30.03, start: 0.000000, bitrate: 2984 kb/s
  Stream #0:0(eng): Video: h264 (High), yuv420p(tv, bt709, progressive), 1920x1080 [SAR 1:1 DAR 16:9], 29.97 fps, 29.97 tbr, 1k tbn (default)
Stream mapping:
  Stream #0:0 -> #0:0 (h264 (native) -> hevc (libx265))
Press [q] to stop, [?] for help
x265 [info]: HEVC encoder version 3.5+1-f0c1022b6
x265 [info]: build info [Linux][GCC 8.3.0][64 bit] 8bit+10bit+12bit
x265 [info]: using cpu capabilities: MMX2 SSE2Fast LZCNT SSSE3 SSE4.2 AVX FMA3 BMI2 AVX2
x265 [info]: Main profile, Level-4 (Main tier)
x265 [info]: Thread pool created using 16 threads
x265 [info]: Slices                              : 1
x265 [info]: frame threads / pool features       : 4 / wpp(17 rows)
x265 [info]: Coding QT: max CU size, min CU size : 64 / 8
x265 [info]: Residual QT: max TU size, max depth : 32 / 1 inter / 1 intra
x265 [info]: ME / range / subpel / merge         : hex / 57 / 2 / 3
x265 [info]: Keyframe min / max / scenecut / bias  : 25 / 250 / 40 / 5.00 
x265 [info]: Lookahead / bframes / badapt        : 20 / 4 / 2
x265 [info]: b-pyramid / weightp / weightb       : 1 / 1 / 0
x265 [info]: References / ref-limit  cu / depth  : 3 / off / on
x265 [info]: AQ: mode / str / qg-size / cu-tree  : 2 / 1.0 / 32 / 1
x265 [info]: Rate Control / qCompress            : CRF-40.0 / 0.60
x265 [info]: tools: rd=3 psy-rd=2.00 early-skip rskip mode=1 signhide tmvp
x265 [info]: tools: b-intra strong-intra-smoothing lslices=6 deblock sao
Output #0, matroska, to '/data/out.mkv':
  Metadata:
    encoder         : Lavf59.16.100
  Stream #0:0(eng): Video: hevc, yuv420p(tv, bt709, progressive), 1920x1080 [SAR 1:1 DAR 16:9], q=2-31, 29.97 fps, 1k tbn (default)
    Metadata:
      encoder         : Lavc59.18.100 libx265
    Side data:
      cpb: bitrate max/min/avg: 0/0/0 buffer size: 0 vbv_delay: N/A
frame=    1 fps=0.0 q=0.0 size=       3kB time=00:00:00.00 bitrate=N/A speed=   0x     frame=   25 fps=0.0 q=0.0 size=       3kB time=00:00:00.00 bitrate=N/A speed=   0x     frame=   28 fps= 11 q=0.0 size=       3kB time=00:00:00.00 bitrate=N/A speed=   0x     frame=   30 fps=9.5 q=0.0 size=       3kB time=00:00:00.00 bitrate=N/A speed=   0x     frame=   32 fps=7.7 q=41.8 size=       3kB time=-00:00:00.03 bitrate=N/A speed=N/A     frame=   35 fps=7.1 q=41.4 size=       3kB time=00:00:00.06 bitrate= 357.3kbits/s speed=0.frame=  900 fps=4.2 q=47.9 Lsize=    1994kB time=00:00:29.93 bitrate= 545.7kbits/s speed=0.138x    
video:1984kB audio:0kB subtitle:0kB other streams:0kB global headers:2kB muxing overhead: 0.470304%
x265 [info]: frame I:      4, Avg QP:40.24  kb/s: 2734.29 
x265 [info]: frame P:    264, Avg QP:42.01  kb/s: 1366.43 
x265 [info]: frame B:    632, Avg QP:46.71  kb/s: 181.45  
x265 [info]: Weighted P-Frames: Y:5.7% UV:5.7%
x265 [info]: consecutive B-frames: 1.5% 2.6% 71.3% 7.8% 16.8% 
encoded 900 frames in 216.00s (4.17 fps), 540.39 kb/s, Avg QP:45.30
```

Launch Jarvice files manager, and see the compressed video:

![app_ffmpeg_step_1](img/apps_tutorial/app_ffmpeg_step_1.png)

Using h265 instead of h264, we reduced video size. This is however a very basic example, and video quality was also reduced. A real ffmpeg application would need much more 
settings available to users. This was however enough as an example.

## 7. Basic shell interactive application

It is possible to obtain an interactive shell directly from the browser. This can be useful for applications that
requires interactions with users (or have to be manually launched) and that do not require a full GUI desktop.

We are going to create a very basic and naive python-based calculator, as an example.

### 7.1. Create image

Create Dockerfile, that includes python3 and our basic application.

```dockerfile
FROM ubuntu:latest 

RUN apt-get update \
  && apt-get install -y python3-pip python3-dev curl \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 install --upgrade pip

COPY calculator.py /calculator.py

RUN chmod +x /calculator.py;

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

RUN mkdir -p /etc/NAE && touch /etc/NAE/AppDef.json
```

### 7.2. Create calculator.py file

Create now the basic python-based application, in file `calculator.py`:

```python
#!/usr/bin/env python3
print('Calculator example')
while True:
    eval_output = eval(input("Enter any operation of your choice: "))
    print("Result: " + str(eval_output))
```

### 7.3. Create AppDef

Create AppDef file, with target path to gotty shell, and command to our application.

```json
{
    "name": "Gotty shell command",
    "description": "Run a command in a gotty webshell on image",
    "author": "Nimbix, Inc.",
    "licensed": true,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Gotty": {
            "path": "/calculator.py",
            "webshell": true,
            "interactive": true,
            "name": "Interactive webshell",
            "description": "Start a command in a gotty webshell",
            "parameters": {}
        }
    },
    "image": {
        "type": "image/png",
        "data": ""
    }
}
```

### 7.4. Launch and use

Once built and submitted to cluster, it is possible to join session by clicking on "Click here to connect".

![app_gotty_step_1](img/apps_tutorial/app_gotty_step_1.png)

It should open a new tab in your web browser, and connect you directly to a shell running the application:

![app_gotty_step_2](img/apps_tutorial/app_gotty_step_2.png)

Note also that you can replace application command path (`/calculator.py` here) by a full shell instead of an application, like `/usr/bin/bash`, to fully manipulate image.

When debugging an application, it can be a real added value to add a second entry to image, with a gotty shell combined to the bash shell to be able to interactively launch scripts and debug.

## 8. Basic UI interactive application

Some applications need a full GUI to be used, with a windows manager.

It is possible to get a full XFCE desktop by adding needed dependencies during docker build step, and using the correct 
command entry point.

In this example, we are going to create a GIMP (image manipulation software) application. Note that we are using here Ubuntu, but you can also use any RHEL derivate distribution. Refer to https://github.com/nimbix/jarvice-desktop for more details.

### 8.1. Create image

Create Dockerfile, with a specific `RUN` that bootstraps Nimbix default desktop. We then install gimp.

```dockerfile
FROM ubuntu:latest

# Install jarvice-desktop tools and desktop from Nimbix repository
RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl --no-install-recommends && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/jarvice-desktop/master/install-nimbix.sh \
        | bash

RUN apt-get -y install gimp;

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

RUN mkdir -p /etc/NAE && touch /etc/NAE/AppDef.json
```

### 8.2. Create AppDef

Create now AppDef file, with `/usr/bin/gimp` as target path:

```json
{
    "name": "myapp",
    "description": "",
    "author": "",
    "licensed": true,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "GUI": {
            "path": "/usr/bin/gimp",
            "desktop": true,
            "interactive": true,
            "name": "Gimp GUI",
            "description": "Run a GIMP in a GUI desktop, and connect interactively directly from your web browser (requires Nimbix Desktop in image).",
            "parameters": {}
        }
    },
    "image": {
        "data": "",
        "type": "image/png"
    }
}
```

### 8.3. Launch application

Once application has been built and uploaded to Jarvice PushToCompute, submit a new job.

Once job is started, simply click on job's "Click here to connect":

![app_gimp_step_0](img/apps_tutorial/app_gimp_step_0.png)

This will open a new tab in your browser, in which after few seconds you will 
be connected to a full GUI desktop, with Gimp opened.

BEWARE! If you close gimp window (so end execution of `/usr/bin/gimp`), job will terminate.

![app_gimp_step_1](img/apps_tutorial/app_gimp_step_1.png)

## 9. MPI application

Jarvice embed an OpenMPI version of MPI, that can be used to build and run MPI applications. It is also possible for users to use their own MPI libraries and runtime, but this is out of the scope of this tutorial. However, some advices are given bellow.

### 9.1. Basic benchmark application

In this example, we are going to download and build the Intel MPI Benchmark tool, and run it in parallel on the cluster.

Create folder app-mpi and NAE subfolder:

```
mkdir app-mpi/NAE/ -p
```

Then create the Dockerfile.
We are going to extract Jarvice OpenMPI from jarvice_mpi image, and use it to build our application.
There is no need to keep Jarvice OpenMPI in final image, as it is automatically side-loaded (available) during
execution on cluster.

```dockerfile
# Load jarvice_mpi image as JARVICE_MPI
FROM us-docker.pkg.dev/jarvice/images/jarvice_mpi:4.1 as JARVICE_MPI

# Multistage to optimise, as image does not need to contain jarvice_mpi 
# components, these are side loaded during job containers init.
FROM ubuntu:latest as buffer

# Grab jarvice_mpi from JARVICE_MPI
COPY --from=JARVICE_MPI /opt/JARVICE /opt/JARVICE

# Install needed dependencies to download and build Intel MPI Benchmark
RUN apt-get update; apt-get install -y wget curl gcc g++ git make bash; apt-get clean;

# Build IMB-MPI1 which is enough for basic testing
# Note that we are sourcing Jarcice OpenMPI environment using the provided /opt/JARVICE/jarvice_mpi.sh
RUN bash -c 'git clone https://github.com/intel/mpi-benchmarks.git; cd mpi-benchmarks; \
    source /opt/JARVICE/jarvice_mpi.sh; sed -i 's/mpiicc/mpicc/' src_cpp/Makefile; \
    sed -i 's/mpiicpc/mpicxx/' src_cpp/Makefile; make IMB-MPI1;'

# Create final image from Ubuntu
FROM ubuntu:latest

# Grab MPI benchmarks binaries built before using jarvice-mpi
COPY --from=buffer /mpi-benchmarks/IMB-MPI1 /IMB-MPI1

# Integrate AppDef file
COPY NAE/AppDef.json /etc/NAE/AppDef.json
```

And create the AppDef.json file with the following content:

```json
{
    "name": "mpiapp",
    "description": "An mpi application",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "imb": {
            "path": "/IMB-MPI1",
            "mpirun": true,
            "verboseinit": true,
            "interactive": false,
            "name": "Intel Mpi Benchmark",
            "description": "Run the Intel MPI Benchmark MPI1 over multiple nodes.",
            "parameters": {}
        }
    },
    "image": {
        "data": "",
        "type": "image/png"
    }
}
```

Then simply build the image, push it, and load it into Jarvice Push to Compute.

Note that we set `mpirun` to **true**, to allow native Jarvice MPI parallel execution.

Note also that we set `verboseinit` to **true**. This is optional and allows us to see exactly what is executed at start.

At job submission, use Machine type select box, and Cores range selector to choose more than 1 machine. Then submit the job.

![app_mpi_step_1](img/apps_tutorial/app_mpi_step_1.png)

If all goes well, you should see the MPI benchmark running on the cluster. It should not take more than few minutes. If it hangs, you may have network issues to investigate with your cluster administrator.

![app_mpi_step_2](img/apps_tutorial/app_mpi_step_2.png)

Note that at execution start, verboseinit allowed to see few interesting steps:

We can see the executed command:

```
INIT[1]: VERBOSE - argv[3] : PATH=/opt/JARVICE/openmpi/bin/:/opt/JARVICE/bin/:$PATH LD_LIBRARY_PATH=/opt/JARVICE/openmpi/lib/:/opt/JARVICE/lib/:$LD_LIBRARY_PATH /opt/JARVICE/openmpi/bin/mpirun -x PATH -x LD_LIBRARY_PATH -N 4  --hostfile /etc/JARVICE/nodes /IMB-MPI1
```

And also the ssh connectivity test between nodes, to ensure smooth MPI execution:

```
INIT[1]: Starting SSHD server...
INIT[1]: Checking all nodes can be reached through ssh...
INIT[1]: VERBOSE - Attempting ssh connection to jarvice-job-101593-fw84g.
INIT[1]: VERBOSE - Success connecting to jarvice-job-101593-fw84g.
INIT[1]: VERBOSE - Attempting ssh connection to jarvice-job-101593-vwzk7.
INIT[1]: VERBOSE - Success connecting to jarvice-job-101593-vwzk7.
INIT[1]: SSH test success!
```

### 9.2. Using another MPI implementation

If you wish to use your own MPI implementation (Intel MPI, HPCX, etc), you need to 
uses your own script as path to start your application.

You can rely on the following example, as a starting point, and also refer to the "MPI Application Configuration Guide" of this documentation.

Note that in the current script, as an example,
we also added a CASE_FOLDER variable, to be passed by user, to be able to set a working
directory. This can be useful with some applications.

```bash
#!/usr/bin/env bash
# Source the JARVICE job environment variables
echo "Sourcing JARVICE environment..."
[[ -r /etc/JARVICE/jobenv.sh ]] && source /etc/JARVICE/jobenv.sh
[[ -r /etc/JARVICE/jobinfo.sh ]] && source /etc/JARVICE/jobinfo.sh

# Gather job environment and process input
echo "Processing computational environment..."
CASE_FOLDER=
MPIHOSTS=
CORES=

while [[ -n "$1" ]]; do
  case "$1" in
  case_folder)
    shift
    CASE_FOLDER="$1"
    ;;
  *)
    echo "Invalid argument: $1" >&2
    exit 1
    ;;
  esac
  shift
done

CASE_FOLDER=$(dirname "$CASE_FOLDER")
echo " - Using Case directory: $CASE_FOLDER"

CORES=$(cat /etc/JARVICE/cores | wc -l )
NBNODES=$(cat /etc/JARVICE/nodes | wc -l)
if [[ "$NBNODES" -gt 1 ]]; then
  MPIHOSTS="/etc/JARVICE/cores"
  NBPROCPERNODE=$((CORES/NBNODES))
  echo "MPI environment: "
  echo "  - mpi_hosts list file: $MPIHOSTS"
  echo "  - number of process per nodes: $NBPROCPERNODE"
  echo "  - cores: $CORES"
else
  echo "MPI environment: "
  echo "  - cores: $CORES"
fi

# Load mpi environment
echo "Loading Jarvice OpenMPI environment..."
source /opt/JARVICE/jarvice_mpi.sh;

# Enter case directory
echo "Entering case folder $CASE_FOLDER ..."
cd "$CASE_FOLDER"

# Execute command, add verbosity to see exact command executed
# Also use full path for binaries, even mpirun, to avoid issues on slave nodes
echo "Executing application."
echo "First command explicitly shows who is running MPI (help understanding)."
echo "Second command is the real application."
date
set -x
/opt/JARVICE/openmpi/bin/mpirun -x PATH -x LD_LIBRARY_PATH -np $CORES --hostfile /etc/JARVICE/cores hostname
/opt/JARVICE/openmpi/bin/mpirun -x PATH -x LD_LIBRARY_PATH -np $CORES --hostfile /etc/JARVICE/cores /opt/my_parallel_application/bin/mpi_application
set +x
date
```

And the CASE_FOLDER associated would be a parameter in AppDef.json:

```json
        "case_folder": {
          "required": true,
          "type": "STR",
          "value": "",
          "name": "Case folder."
        }
```
## 10. Script based application

It is possible to directly inject script to be executed into the AppDef.json file, allowing advanced usage of application images.

Note that by default, you cannot execute any privilege escalation, and so sudo cannot be used to install packages for example in such scripts.
It is however possible, if allowed by cluster administrator, to enable privilege execution during apps execution. This feature is however out of the scope of this tutorial.

### 10.1. Plain text script

First possibility is to use plain text script.

In this example, we are not going to create an image. We will only rely on Ubuntu default image, and directly inject our AppDef.json into Push To Compute interface.

Create on your local system file `AppDef_script.json` with the following content:

```json
{
    "name": "Script test",
    "description": "Script test",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Script_raw": {
            "path": "/myscript.sh",
            "interactive": false,
            "name": "Script Raw",
            "description": "Run a raw script",
            "cmdscript": "#!/bin/sh\necho I love pizza\necho I am running on $(hostname)",
            "parameters": {}
        }
    },
    "image": {
        "data": "",
        "type": "image/png"
    }
}
```

Note that we added a key called `cmdscript` that contains our script content, and `path` will be the path were script content will be written before being executed.

Now, create a new App, and in first tab, GENERAL, set an App ID, and use docker.io/ubuntu:latest as app base image.

![app_script_raw_step_1](img/apps_tutorial/app_script_raw_step_1.png)

Then go to tab APPDEF, and upload `AppDef_script.json` file created before.

![app_script_raw_step_2](img/apps_tutorial/app_script_raw_step_2.png)

Then validate.
Our application is ready.

Submit a job, and you should see the script executing.

However, since json format do not support multiline strings, this is a one-line script, which can be a pain when dealing with large scripts.

When using complex scripts, you can base64 encode them (see below).

### 10.2. Base64 encoded script

When dealing with complex scripts, it might be simpler to base64 encode them, so that you can pass them as a single line string into a json file.

Jarvice will auto-detect that script provided is encoded, and will decode it on the fly.

Create a file called `myscript.sh` with the following content:

```bash
#!/bin/bash
for i in 1 2 3 4 5
do
   echo "Welcome $i times"
done
```

Then, encode it:

```
base64 -w 0 myscript.sh
```

You should obtain:

```
IyEvYmluL2Jhc2gKZm9yIGkgaW4gMSAyIDMgNCA1CmRvCiAgIGVjaG8gIldlbGNvbWUgJGkgdGltZXMiCmRvbmUKCg==
```

Note that to decode it, you can use:

```
echo "IyEvYmluL2Jhc2gKZm9yIGkgaW4gMSAyIDMgNCA1CmRvCiAgIGVjaG8gIldlbGNvbWUgJGkgdGltZXMiCmRvbmUKCg==" | base64 -d
```

Now, update file `AppDef_script.json` and replace previous text script by the base64 encoded string:

```json
{
    "name": "Script test",
    "description": "Script test",
    "author": "Me",
    "licensed": false,
    "appdefversion": 2,
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Script_raw": {
            "path": "/myscript.sh",
            "interactive": false,
            "name": "Script Raw",
            "description": "Run a raw script",
            "cmdscript": "IyEvYmluL2Jhc2gKZm9yIGkgaW4gMSAyIDMgNCA1CmRvCiAgIGVjaG8gIldlbGNvbWUgJGkgdGltZXMiCmRvbmUKCg==",
            "parameters": {}
        }
    },
    "image": {
        "data": "",
        "type": "image/png"
    }
}
```

Edit script_raw app, and upload this new file to replace previous AppDef, and save.

Then launch a new job. You should see the script execution.
