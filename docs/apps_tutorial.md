# Jarvice Applications Push to Compute tutorial

This tutorial should allow end users to build their own applications (apps) for Jarvice clusters.

The following examples are covered:

1. Hello world image with detailed process
2. Important building guidelines
3. Basic shell interactive application
4. Review possible parameters


5. Basic non interactive application
6. Basic shell interactive application
7. Basic UI interactive application
8. Mixed Shell and UI application
9. Basic MPI application
10. User tunable application

## 1. Global view

![GlobalProcess](img/apps_tutorial/GlobalProcess.svg)

## 2. Hello world

### 2.1. Create Dockerfile

![GlobalProcess_step_1](img/apps_tutorial/GlobalProcess_step_1.svg)

Create folder hello_world:

```
mkdir hello_world
cd hello_world
```

Create a Dockerfile. A Dockerfile is a multi steps description of how image should be created, and from what. We are going to start from basic Ubuntu image, as this source image is a widely used starting point.

To get more details on how this Dockerfile can be extended and used, refer to https://docs.docker.com/engine/reference/builder/ .

Create file `Dockerfile` with the following content, that should be self explained:

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

Lets review key parts of this file (when not detailed, just keep it as it):

```json
{
    "name": "Hello World App",
    "description": "A very basic app thay says hello to world.",
    "author": "Me",
    "licensed": false,
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

Machines allows you to restrict usage of the application to a specific set of machines registered in Jarvice cluster. For example, if your application is GPU dedicated, it would make no sens to run it on non GPU nodes, and so only GPU able nodes should be added here.

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

Paramaters are required and optionals parameters passed to entry point as arguments or available in `/etc/JARVICE/jobenv.sh` during run (which can be imported by scripts or users).

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

The last section, image, refer to logo that will be displayed inside Jarvice interface, for our application. It has to be encoded to text.
Let's add an image to our application. Download a basic sample from wikimedia:

```
wget https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/HelloWorld.svg/128px-HelloWorld.svg.png
```

And encode it with base64:

```
base64 -w 0 128px-HelloWorld.svg.png
```

Get the output, and add it into AppDef.json inside `images.data` value:


```json
{
...
    "image": {
        "type": "image/png",
        "data": "iVBORw0KGgoAAAANSUhEUgAAAIAAAABACAMAAADlCI9NAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAACu1BMVEUAAAAAHQAAMwAAMAAAKQAAJAAAPgAASgAAIgAAEQAAIAAAPAAAPwAAkQAA/wAA7wAAzAAAtAAA2QAAdgAAOwAAbwAA0gAA2wAAZgAACgAAVgAADgAAjQAAhAAAGgAAOgAARAAANwAADQAAOQAAEwAAAgAAWwAA0AAA/AAAxAAAMQAAtQAA+gAAwAAACAAAqwAAjwAAAQAAXQAAiAAAmwAAtwAAVAAAKgAA1QAAFgAA3gAAngAAcgAARQAA/QAAYAAAQwAAkAAAHwAABAAAJgAApAAA9QAA4QAA5gAAUQAA2gAA8QAAEAAAswAAxwAAcQAAHgAA9wAABQAAdQAAsAAAmgAAsgAAogAA8AAAqgAA8wAALwAAoAAAmQAApgAAyAAA1gAAeQAAXAAA6QAA6AAA4AAAXwAAQgAA7gAA5AAAWAAA/gAAiQAAfwAASAAA8gAAgwAA1AAAGQAAGAAAywAArwAAlwAAewAAPQAAYQAA6wAAAwAA1wAAjgAAQQAAzwAANAAABgAAMgAAqQAAIwAA+AAABwAALAAADwAAtgAAwwAA7QAAowAA3QAArQAAzQAAoQAAIQAATgAAygAAHAAA+wAAhwAAmAAADAAANQAAXgAAjAAAnwAAlQAASwAALgAAQAAAFAAAFwAAYwAAkgAAagAAeAAAnQAAuwAATAAA2AAAzgAA4gAAugAA0wAAxgAASQAApQAAcAAAbgAAaQAACwAA7AAAZAAALQAAgQAA6gAAuQAAlgAAGwAAfgAAwgAAZQAAawAA9gAA5wAANgAAUwAA4wAATwAAhQAAJQAAUAAAnAAA3AAAUgAAcwAAggAAgAAAJwAAqAAA+QAArgAA3wAAhgAApwAAlAAA9AAAdAAAvwAAZwAAYgAATQAARwAAFQAAdwAACQAAWQAAiwAAVwAAvAAAKwD///+roNTNAAAAAWJLR0ToJtR3AgAAAAd0SU1FB+EJAhY4BL6Mb10AAAXISURBVGje7Zj7XxRVFMAvj3bF6LLyUAiQ5SkCq2ywECgErIIgJlAJolBkJbVIluADcS1UXkGiomJmalrgAxOEUpMsK3uZqVn0Dkvr3+icOzuzO7i7nxmW+NTns+cH7jnn3nP3y9zHnDOEOMUp/1dxceXETfC4mzz3jGE2hVKpgGaSUqn0QHsyKPeyHk/QXKyF3Ec58RI8KpNnyhgAvCn1hsYHwn3R9gNlKuuZBpq/E8BaSICHh8f9IoBA8ARNHACKUgSAEvzvAkwPUYd6yAUIC1WHR4wHQGTUDFzh6JlKOQAxsXEYpPF0GGDWbMpLvFYywANxfFCCXYBEnS4RmiSdTpfMAzyYgpLKA8yhZpkrFSAt3Rz0kJw94UctBQEyUMnM0s+bD212hDQAfQ6YC6Lcc/OgXZjvEMAiaOdjl/Zh0BZLA0jC5Y8BpaDQHDQ2gKJsaENY3yOgPSoN4DGwljCtGDSdTICSpSilHMAyBFleBlL+OGhPSAPAu7GCaU+CtkImgOgUZIgeCX1KGsDTYD3DtJW4GJEOACjFAJXSAJ4F6zmmhYNm0DsAEII/W5XAyypuWDU4nxcFrhat9QvC1sPtWOLIEryIAGvuSiPQO8vSUwGOGsGqBWst09aBpnIEgLXCOUoxocxDgPWWgRvAURrIW3PBqgsDZWM9aJscAsB/rXADW0W3+FIjN2wjnpHNL71sDmxApC1bTdstZRse2TDSiOfR0OQQQHMqyz5ULa2vQGsCIG2jjgXRtvOeV/k9SUu3e2HTQRwCIG4rLE4BD7DDaxQA2RltCVDUIoTsCnQQgHRu4d8su1smC5lw7G4xAKnebgFAivZsY1b03i5ZCcp0hULRwLR9oPG73+W1/a+3HfB5Q/S/dB08pFarFRaeww3gUB80WW8eyWw7+laWs45xilMmQhKWcvK2lb5u8MdInknd09NjFKxjYCmkhNmrDevAz+qJJo1GgylCsUZTbHMmTF/8RG/YkHED8AXFh6tEjtucaZKojtgPVqcUgHWQMZ4YF4CiaMt313K4/CUnU8HjAkBOUtorGFMozSETDNBK6SlIAVxdXSGdeYfSmVx1evrokt6+fvNypPn7+4eT/DN9vR0D+TYAfA+01PYPygWAPONdQgZg7HvshVyOzrMnuD1WeI5Pr7FcDVKcZ973rQJEXmCdp4ZkAsA0hkayFsaWEVLJ7cgGLyG36LAAKDe5e60CfGCKuFgpD+BDGFWAz57OIHoDpR8REoD1Ja1ZhDPRI2YASFLiUo9nWwcYuoSjP67nKBhAoNFoxK9uoUbjJ7YB0mB4qHYhZjKDKfB3J7ce0Z/CxrgIyuUiAYBm9zfDufnsgjUAzIrp55HEeEkAkCZfwPAv4TYogaTbHXRIjrAi/IolYfBEaLUZIMmUjVoDwIzwCvZUyQRohAc78DWlmZReXQ+hESQAv3RksE4sz4MFgCtaO8cQjjM9xy5gmQBkAaXfXKOG65TeyIWnbCpBuMRuDv+lgAHcsHcPfMvXhvp0mQCw/xJv0mmknX4HG7IeclNzEfY9aLECQJkdAD0GrWTqeZkAwzBNOx0m5ZTGsyN2Fuc6zPp+AG22ALDJDoAWa4RjTP1RJsAeSr0N9CesD+AMdROyBgGWjao42UUkDlwFrp8Fq5K7yuDwyd0Dv5jqn1DWXgPPZWjPYNcgHA36qy2AxeDKE6xdYA3z1bksgNMYYGgmjayuwZ/bC20OXvhXsTTqtAXwG7XMHnC1CgvgRtbIBcDDj3uPnTmaBkoylmBTo34PihYOgTWAERxWWlZx61YuWIcwOi/qdC2VC/AH3jZtoGRi5HXLax0LwRSbAKRPVB23mow6uZuQYCncD+2fGD7ItvRtfuqTycQ2wEiNJcBW7lWZfqdOLkCbSqXaB20WtPyu9tTh58b21UJtWgWdd3191N/p/gv8qtvMyroJV2heLkGXr+OJd+OOphG5MV1/D2mdJYtT/tPyD1B/bYS3NVS6AAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDE3LTA5LTAyVDIyOjU2OjA0KzAwOjAwT3dQwQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAxNy0wOS0wMlQyMjo1NjowNCswMDowMD4q6H0AAAAASUVORK5CYII="
    }
}
```

Now that our AppDef file is ready, it is time to inject it into final image.

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

RUN apt-get update; apt-get install curl -y;

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
```

And build again:

```
:~$ docker build --tag="tutorial:hello_world" -f Dockerfile .
Sending build context to Docker daemon   16.9kB
Step 1/4 : FROM ubuntu:latest
 ---> 7e0aa2d69a15
Step 2/4 : RUN apt-get update; apt-get install curl -y;
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

If you do not own a registry, or do not own an account on a third party registry, you will need to obtain one.

In this tutorial, we are going to get a free account from https://hub.docker.com/ . There are other free registry available on the market, this is only an example. Note that by default, a free account on https://hub.docker.com/ allows unlimited public repositories, but only a single private repository. If you need to host multiple private images, you will need to consider another solution.

Create an account on https://hub.docker.com/.

Once account is created, sign in, and click on **Create Repository**.

![DockerHub_step_1](img/apps_tutorial/docker_hub_step_1.png)

Fill required information, as bellow:

![DockerHub_step_2](img/apps_tutorial/docker_hub_step_2.png)

And click **Create**.

Our application repository is now created and ready to host our image.
Pull command is displayed on repository page:

![DockerHub_step_3](img/apps_tutorial/docker_hub_step_3.png)

### 2.6. Push image

![GlobalProcess_step_5](img/apps_tutorial/GlobalProcess_step_5.svg)

Now that image is ready and registry repository is ready to host image, we need to login to registry and upload image into repository.

Check image is ready:

```
:~$ docker images | grep tutorial
tutorial                                                           hello_world                                       a32ee72e76f6   5 hours ago     124MB
:~$
```

Now login to docker hub registry, using your credentials (or login to your private registry if not using docker, command may varie):

```
:~$ docker login
...
Login Succeeded
:~$
```

Now tag and push image. We are going to tag is as `v1` version. Do not copy as it the bellow command, replace `oxedions` by your docker hub user name to match your repository.

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

Image is not pushed and can be pulled from Jarvice Push to Compute interface.

### 2.6. Pull image with Push to Compute

![GlobalProcess_step_6](img/apps_tutorial/GlobalProcess_step_6.svg)

We are ready to inject our image into our Jarvice cluster.

Login as usual user, and in the main interface, go to **PushToCompute** tab on the right:

![PushToCompute_step_1](img/apps_tutorial/PTC_step_1.png)

Then, click on **New** to create a new application.

![PushToCompute_step_2](img/apps_tutorial/PTC_step_2.png)

Fill only `App ID` and `Docker repository`. Everything else will be automatically grabed from the AppDef.json file created with the application. Then click **OK**.

![PushToCompute_step_3](img/apps_tutorial/PTC_step_3.png)

Now that application is registered into Jarvice, we need to request an image pull, so that Jarvice will retrieve AppDef.json embed into image and update all application data. To do so, click on the small burger on the top left of the application, then **Pull**, confirm pull by clicking **OK**, and close Pull Responce windows. Then wait few seconds for image to be pulled.

![PushToCompute_step_4](img/apps_tutorial/PTC_step_4.png)

Once image has been pulled, you can see that application logo has been updated by our base64 encoded png, etc.

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

If all goes well, you are automatically redirected to **Dashboard** tab. If not, click on it on the right. You can see here that your job has been submitted, and is now queued. After few secondes/minutes, job will start and application will run. Note the job number here: 11776. This will be the reference for job logs later.

![Run_Application_step_4](img/apps_tutorial/Run_Application_step_4.png)

Once application has finished to run, you will see it marked as **Completed**.

![Run_Application_step_5](img/apps_tutorial/Run_Application_step_5.png)

### 2.8. Gather logs

![GlobalProcess_step_8](img/apps_tutorial/GlobalProcess_step_8.svg)

Now that our application as run, lets gather few logs about it. Note that if the application failed to run, Jarvice local Admininstrator have access to advanced logs that might help to debug.

First, to grab job output, simply click on the small arrow on the right of the "completed" job card.

We can happily see than our "Hello World!" message is here!!

![Gather_Logs_step_1](img/apps_tutorial/Gather_Logs_step_1.png)

Now, click on **Jobs** tab on the left, and then **History**. You can see here all your jobs history.

![Gather_Logs_step_2](img/apps_tutorial/Gather_Logs_step_2.png)

Last part, it is possible to go into **Account** tab on the right, then **Team Log** on the left. In the central area, we can see all team's job.

![Gather_Logs_step_3](img/apps_tutorial/Gather_Logs_step_3.png)

This is the general process to create an application for Jarvice and inject it through PushToCompute. You may need to iterate time to time between image creation and application jobs, to fix application execution issues. This is an expected behavior.

Also, if too much issues, switch for a time to interactive application (see bellow) to debug application, and then switch back to non interactive.

We can now proceed to more productive applications. Next examples will not be as detailed as this one as process is always the same.

### 3. Important building guidelines

Before proceding to more examples, it is important to keep in mind few image building guidelines.

#### 3.1. Repush image

When you need to fix image and rebuild it, you need to delete local tag and create it again in order to be able to push again image.

Lets take an example: we need to fix our hello_world application image, since we made a mistake in it.

Build fixed image, it will update local copy:

```
docker build --tag="tutorial:hello_world" -f Dockerfile .
```

Note: sometime, you may want to force rebuilding all the steps, so forcing docker not using build cache. To do so, add `--no-cache` to `docker build` line.

Then delete local tag to remote repository:

```
docker rmi oxedions/app-hello_world:v1
```

And tag and push again local copy:

```
docker tag tutorial:hello_world oxedions/hello_world:v1
docker push oxedions/hello_world:v1
```

Don't forget to request a new pull in Jarvice interface to grab latest image.

#### 3.2. Multi stages

Application images can be really big. Images builder should care about images size, and so optimize build process in order to save disk and bandwith.

Docker containers images work with layers. Each step generates a layer that is stacked over others (like a git repository).
This means that if user import (ADD/COPY/RUN wget) huge archives or files or installer binaries during process, even if file is deleted in a next step, this file will be 
stored in image stack, and so will grow image size without usage.

In order to prevent that, it is common and recommanded to use multi-stages builds.

Idea is simple: instead of having a single stage in Dockerfile, we create multiple, and import all what we need in the final stage from previous ones.

Lets take an example:

We want to install Intel Parallel Studio Compilers. Archive is big (> 3GB).

In stage 0 (counter start at 0), we ADD archive to image, and install Intel product into `/opt/intel` folder. Final image layers contains both installer archive, extracted archive content, and final installed product.

Then, in second stage we simply say "now copy all that is in `/opt/intel` in stage 0 into current stage, so final image of this stage only contains final installed product in its layers, we don't have archive and extracted archive in final application image layer, which saves a LOT of disk and bandwith.

Lets create a standard image that would download and install ffmpeg:

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

401 MB, this is a lot for such a small program. Probleme here is: our image have in memory apt cache, few packages installed needed to download and extract archive, archive itself, and archive content that we do not need.

Lets update it to a multi-stage build now:

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

Note: we could also have `COPY --from=0`, stage number are accepted.

Lets build again our image now, and we will need this time to prevent cache usage to be sure image is clean.

```
docker build --no-cache --tag="tutorial:ffmpeg" -f Dockerfile .
```

And now lets check again image size:

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

We went from 401MB to 151MB. This is a huge size reduction. While with this small example image size does not really matter, with huges applications, this could have a significant impact.

For more details, please visit official documentation on multi stage builds: https://docs.docker.com/develop/develop-images/multistage-build/

#### 3.3. End with NAE

We have seen that container images are multi layer images.

When pulling an image into Jarvice, Jarvice system needs to grab NAE content (AppDef.json file) from layers. To do so, it will search in each layer, starting from last one, for files. This process can take a long time. To speedup pull process, it is recommanded to always perform NAE copy at last stage of a build, or to simply add a "touch" line that will simply contains copy of files:

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

RUN apt-get update; apt-get install curl -y;

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

RUN mkdir -p /etc/NAE && touch /etc/NAE/AppDef.json
```

For such a small image, it do not worth it, but for very large images, this small tip can have interesting benefit.

### 3. Basic interactive job

Before reviweing available application parameters, next step is to be able to launch interactive jobs.

Interactive jobs are very useful to debug when creating an application, as you can test launch application end point yourself, and debug into the Jarvice cluster context.

### 3.1. Standard way

Create a new application folder aside app-hello_world folder, called app-interactive_shell:

```
mkdir app-interactive_shell
cd app-interactive_shell
mkdir NAE
```

Now, create here a Dockerfile with the following content:

```dockerfile
FROM ubuntu:latest

RUN apt-get update; apt-get install curl -y;

RUN echo "Sarah Connor ?" > /knock_knock ;

COPY NAE/AppDef.json /etc/NAE/AppDef.json

RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate
```

Then create AppDef.json in NAE folder with the following content:

```json
{
    "name": "Interactive application",
    "description": "Run a command in a gotty shell on image",
    "author": "Me",
    "licensed": false,
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
            "path": "/bin/gotty",
            "interactive": true,
            "name": "Gotty shell",
            "description": "Start a command in a gotty shell",
            "parameters": {
                "command": {
                    "name": "Command",
                    "description": "Command to run inside image.",
                    "type": "STR",
                    "value": "/bin/bash",
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

We are going to use the /bin/gotty entry point, that is live embed into applications when running images on Jarvice clusters.

Now build application:

```
:~$ docker build --tag="tutorial:interactive_shell" -f Dockerfile .
Sending build context to Docker daemon  4.096kB
Step 1/5 : FROM ubuntu:latest
 ---> 7e0aa2d69a15
Step 2/5 : RUN apt-get update; apt-get install curl -y;
 ---> Using cache
 ---> 88667cf55ce3
Step 3/5 : RUN echo "Sarah Connor ?" > /knock_knock ;
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

Once image is pushed, add application into Jarvice as before. Note that this time, we didn't base64 encoded a pgn image, so default image is used.

When clicking on application card, you should now have:

![app_interactive_shell_step_1](img/apps_tutorial/app_interactive_shell_step_1.png)

Click on **Gotty Shell**, and in the next window, observe that you can tune the command to be launched if desired (here default value is `/bin/bash` as requested in AppDef.json file).

![app_interactive_shell_step_2](img/apps_tutorial/app_interactive_shell_step_2.png)

Click on **Submit** to launch the job.

Once job is started, it is possible to click on its card to open a new tab in web browser.

![app_interactive_shell_step_3](img/apps_tutorial/app_interactive_shell_step_3.png)

In the new tab, you now have an interactive bash shell. It is possible from here to check file created via Dockerfile (`/knock_knock`):

![app_interactive_shell_step_4](img/apps_tutorial/app_interactive_shell_step_4.png)

### 3.2. On an existing application image

Sometime, in order to debug an app image, and launch entry point manually to check what is failing, it is useful to temporary switch it to an interactive shell.

There is no need to rebuild the image for that, we can live hack the AppDef inside Jarvice interface.

Lets take our hello world application. Click on its burger, and select **Edit**.

![app_interactive_shell_step_5](img/apps_tutorial/app_interactive_shell_step_5.png)

Now, go into tab **APPDEFF** and copy all curent AppDef content from the text area. Edit this json into a text editor, and "hack" it this way:

```json
{
    "name": "Hello World App",
    "description": "A very basic app thay says hello to world.",
    "author": "Me",
    "licensed": false,
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
            "path": "/bin/gotty",
            "interactive": true,
            "name": "Gotty shell",
            "description": "Enter an interactive shell",
            "parameters": {
                "command": {
                    "name": "Command",
                    "description": "Command to run inside image.",
                    "type": "STR",
                    "value": "/bin/bash",
                    "positional": true,
                    "required": true
                }
            }
        }
    },
    "image": {
        "type": "image/png",
        "data": "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"
    }
}
```

Basically, only changes made are the additional command entry added:

```json
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
        },                        <<<<<< We added a comma here
        "Gotty": {                <<<<<< We added a second command entry
            "path": "/bin/gotty",
            "interactive": true,
            "name": "Gotty shell",
            "description": "Enter an interactive shell",
            "parameters": {
                "command": {
                    "name": "Command",
                    "description": "Command to run inside image.",
                    "type": "STR",
                    "value": "/bin/bash",
                    "positional": true,
                    "required": true
                }
            }
        }
    },
...
```

Then click on **LOAD FROM FILE** and select the hacked json file. This will update application AppDef inside the Jarvice cluster.

![app_interactive_shell_step_6](img/apps_tutorial/app_interactive_shell_step_6.png)

Now, when clicking on application to launch it, you can observe we have a second possible entry point into image:

![app_interactive_shell_step_7](img/apps_tutorial/app_interactive_shell_step_7.png)

Using this entry point starts an interactive shell, and allows to debug inside the image.

Once issues are solved, AppDef will be restaured when pulling fixed image into Jarvice.

## 3. Review application parameters

Lets review now available parameters in AppDef for commands entry. We will not cover all of them in this guide, only the most used ones. Please refer to https://jarvice.readthedocs.io/en/latest/appdef/#commands-object-reference and https://jarvice.readthedocs.io/en/latest/appdef/#parameters-object-reference for more details.


## 3.1. Commands

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

Note: an * means entry is mandatory.

* <u>**path***</u>: Command entry point which is run when application start.
* <u>**name***</u>: Command’s name, which is used as the title of the command in the Jarvice interface.
* <u>**description***</u>: Description of the command’s functionality that is used in the Jarvice interface.
* <u>**parameters***</u>: Parameters are used to construct the arguments passed to the command. If not commands, set it to `{}`
* <u>**interactive**</u>: (default to `false`) defines if application execution should return to user an URL to interact with execution (should be true for gotty or desktop application).

## 3.2. Commands parameters

Commands parameters allows to:

* Force specific read only values to be passed to application's entry point as arguments (CONST)
* Allows users to tune settings to be passed to application's entry point or scripts

Remember the Command parameter to be set for interactive gotty shell example:

```json
...
    "commands": {
        "Gotty": {
            "path": "/bin/gotty",
            "interactive": true,
            "name": "Gotty shell",
            "description": "Enter an interactive shell",
            "parameters": {
                "command": {   <<<<<<<<<<<<<< This
                    "name": "Command",
                    "description": "Command to run inside image.",
                    "type": "STR",
                    "value": "/bin/bash",
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

Here is a detailed list. You do not need to understand all values for now. This list is here as a resource for next steps.

### 3.2.1. CONST

`CONST` defines a string value that cannot be modified by user.

`CONST` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| positional | boolean | | If element should be passed ordered as in AppDef file | true |
| required | boolean | * | If element is required (not used for CONST type, should be true) | |
| value | string | * | Value of element | |

### 3.2.2. STR

`STR` defines a string value and is the default type if not specified

![type_STR](img/apps_tutorial/type_STR.png)

`STR` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| positional | boolean | | If element should be passed ordered as in AppDef file | true |
| required | boolean | * | If element is required | |
| variable | boolean | | If element should be provided by /etc/JARVICE/jobenv.sh instead of passed as argument | false |
| value | string | * | Default value of element | |

### 3.2.3. INT

`INT` defines an integer value.

![type_INT](img/apps_tutorial/type_INT.png)

`INT` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| positional | boolean | | If element should be passed ordered as in AppDef file | true |
| required | boolean | * | If element is required (not used for CONST type) | |
| variable | boolean | | If element should be provided by /etc/JARVICE/jobenv.sh instead of passed as argument | false |
| value | integer | * | Default value of element | |
| min | integer | * | Minimal value of element | |
| max | integer | * | Maximal value of element | |

### 3.2.4. FLOAT

`FLOAT` defines a floating point value.

![type_FLOAT](img/apps_tutorial/type_FLOAT.png)

`FLOAT` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| positional | boolean | | If element should be passed ordered as in AppDef file | true |
| required | boolean | * | If element is required (not used for CONST type) | |
| variable | boolean | | If element should be provided by /etc/JARVICE/jobenv.sh instead of passed as argument | false |
| value | float | * | Default value of element | |
| min | float | * | Minimal value of element | |
| max | float | * | Maximal value of element | |
| precision | integer | | Maximum number of decimal digits allowed | |

### 3.2.5. RANGE

`RANGE` defines a range of possible integer values, as a slider.

![type_RANGE](img/apps_tutorial/type_RANGE.png)

`RANGE` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| positional | boolean | | If element should be passed ordered as in AppDef file | true |
| required | boolean | * | If element is required (not used for CONST type) | |
| variable | boolean | | If element should be provided by /etc/JARVICE/jobenv.sh instead of passed as argument | false |
| value | integer | * | Default value of element | |
| min | integer | * | Minimal value of element | |
| max | integer | * | Maximal value of element | |
| step | integer | * | Step to be used between values in the slider | |

### 3.2.6. BOOL

`BOOL` defines a boolean value which includes the parameter if true, or omits it if false.

![type_BOOL](img/apps_tutorial/type_BOOL.png)

`BOOL` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| positional | boolean | | If element should be passed ordered as in AppDef file | true |
| required | boolean | * | If element is required (not used for CONST type) | |
| variable | boolean | | If element should be provided by /etc/JARVICE/jobenv.sh instead of passed as argument | false |
| value | boolean | * | Default value of element | |

### 3.2.7. Selection

`selection` defines a single selection list.

![type_selection](img/apps_tutorial/type_selection.png)

`selection` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| positional | boolean | | If element should be passed ordered as in AppDef file | true |
| required | boolean | * | If element is required (not used for CONST type) | |
| variable | boolean | | If element should be provided by /etc/JARVICE/jobenv.sh instead of passed as argument | false |
| values | list | * | Possible values as a list. First value is default. | |
| mvalues | list | | Parallel list of values in machine format. Index must match values. | [ ] |

### 3.2.8. FILE

`FILE` defines a file name stored on the cluster in user's /data folder.

![type_FILE](img/apps_tutorial/type_FILE.png)

`FILE` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| positional | boolean | | If element should be passed ordered as in AppDef file | true |
| required | boolean | * | If element is required (not used for CONST type) | |
| variable | boolean | | If element should be provided by /etc/JARVICE/jobenv.sh instead of passed as argument | false |
| filter | string | | Files extentions allowed. Ex: `"*.txt"`. If multiple, use `\|` separator: `"*.txt,*.md"`  | |

### 3.2.9. UPLOAD

`UPLOAD` defines a file to upload from a local computer to a Jarvice job.

![type_UPLOAD](img/apps_tutorial/type_UPLOAD.png)

`UPLOAD` type accepts the following settings:

| Setting   |      Type      |  Mandatory | Description | Default |
|-----------|----------------|:----------:|-------------|---------|
| name | string | * | Element name | |
| description | string | * | Element description | |
| required | boolean | * | If element is required (not used for CONST type) | |
| variable | boolean | | If element should be provided by /etc/JARVICE/jobenv.sh instead of passed as argument | false |
| filter | string | | Files extentions allowed. Ex: `"*.txt"`. If multiple, use `\|` separator: `"*.txt,*.md"`  | |
| target | string | | Sub path that will be used to mount a file under `/opt` in job | |
| size | integer | | Maximum size allowed for file, in bytes (1024 = 1KB) | |

### 3.2.10 Using parameters

In order to understand all possible combinaison, lets create a specific application. This application makes no sens, this is for testing and understanding purposes.

Note: if you want to play with parameters, remember that you can directly edit AppDef Json in Jarvice UI by editing application. For testing purposed, do not bother building and pushing/pulling an image, edit directly in Jarvice UI.

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
echo Checking job informations
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

Create the following `AppDef.json` file with all possible types present, sometime combined with different settings.

```json
{
    "name": "Reverse engineer application",
    "description": "A environment test application",
    "author": "Me",
    "licensed": false,
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

Observe also in **OPTIONAL** tab the non required `STR` value set in AppDef.

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
###############################################################################

Launch script is starting

Checking arguments passed directly to entry point
Arguments passed: const_2 const_2_value const_1_value str_1_value str_3_value 2 1.2 0 bool_1 selection_1_val1 /data/jellyfish-3-mbps-hd-h264.mkv

Checking job environment
:
const_3=\c\o\n\s\t\_\3\_\v\a\l\u\e
str_2=\s\t\r\_\2\_\v\a\l\u\e

Checking job informations
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

* `const_2` value was passed first in arguments, because `positional` is `false`, and was a combinaison of the main entry key and its value. This is useful to define parameters like `-c blue`:
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
* `const_3` and `str_2` were not passed as arguments, but instead are available in file `/etc/JARVICE/jobenv.sh`, which can be sourced from scripts.
* Other values were passed in the same order than defined in the AppDef file as arguments.
* Uploaded file was correctly uploaded as `/opt/file.txt`.

We have seen all possible and existing parameters. You can now use the ones needed to create tunable applications for Jarvice.