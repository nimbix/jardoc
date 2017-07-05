

![Building and deploying Workflows](img/BuildinganddeployingWorkflows.png)

PushToCompute™ makes it easy for you to design, build and deploy work flows. Work flows are defined using a simple, declarative repository structure centered around a Dockerfile. <!--I think parts of this section do not belong with this topic, but need to rely on you to figure out which ones and where else to put them! Perhaps on an additional page? -->

------

## Getting started

As prerequisites for using the PushToCompute feature of Nimbix' JARVICE platform,

- [ ] you’ll need a Nimbix Cloud account with a payment method on file.
- [ ] you'll need a public or private Docker repository on a registry (e.g. Docker Hub), which derives from a Nimbix base image.   
- [ ] optionally, you might need a source repository from which to build, such as GitHub.

## PushToCompute™ Work Flow Definition

The PushToCompute™ Work Flow Definition is a **Git** repository consisting of the following structure. The only file required is the Dockerfile. However, it is highly recommended that all supporting metadata be stored in the same Git repository.

```dockerfile
Dockerfile        #Used to build the base image

README.md         #Application notes for maintainer or users (if open source)

NAE/

   help.html      # Provides HTML-based help popup

   nvidia.cfg     # Configures Nvidia OpenGL

   AppDef.png/jpg #Automatically imported as app icon

   AppDef.json    # Defines Task Builder and API on portal

   url.txt        # Defines a "Connect" URL

scripts/

   start.sh       # Application entry point script

tests/ (required for certified 3rd party apps)

   tests.sh       # Tests, which can be run in the Dockerfile during build
```

## Work flow types

Most PushToCompute work flows on JARVICE can be divided into the following categories. Each category has slightly different goals and typically requires different types of set up.

**Interactive Desktop Work Flows**: These are ideal for use with the Nimbix Desktop to leverage the interactive capabilities of JARVICE directly in the browser. To launch a desktop environment inside of a Nimbix base image, prefix your application with **/usr/local/bin/nimbix_desktop**.  Interactive Desktop work flows include:

- pre-/post-processing  
- purely graphical work flows
- hybrid work flows

**Single-tenant WebApp:**  This is a web application which runs in an isolated environment. These are well-suited for a url.txt which connects directly to the web application on the NAE’s public IP address.

**Batch Job:** This work flow corresponds to running a single command to process inputs and to produce outputs. These are well-suited for computationally intensive work flows which need to constrain inputs and outputs. They are ideal for turn-key solutions of solvers (which used to require submitting complex batch scripts to a supercomputing queue).

**Service Jobs:** Some types of work flows are long-running service jobs, such as an accelerated database. If your application cannot be run as a “server-less,” on-demand work flow, it can be run indefinitely as a service. The lifetime of the service can be controlled by API or through the dashboard of the JARVICE portal.

## JARVICE Application Definition (AppDef) Reference

The application interface is a JARVICE Application Definition (AppDef) Reference object in the JSON (JavaScript Object Notation) data format. 

The AppDef defines:

- the work flow (commands, data and parameters)
- the user interface. The App Def.json defines the Task Builder web form.  JARVICE also uses the contents of App Def.json to automatically generate a JSON-based API schema for your application
- validation rules for the automatically generated API to run this application
- the command line entry point into the JARVICE Nimbix Application Environment (NAE)

You can find the complete JARVICE Application Definition format by visiting the [JARVICE Application Definition Guide](https://www.nimbix.net/jarvice-application-deployment-guide/). This should be stored in NAE/AppDef.json of your Git repository.

## Building the application image

Application images are defined in the Dockerfile, and its corresponding metadata for the web portal’s catalog entry can be stored in **/etc/NAE/** of the application’s image. 

Nimbix maintains a set of official base images. These images are found in the Docker Hub registry and can be found by searching:

​	**docker search nimbix |grep ^nimbix/**

Contributed base images can be found in the JARVICE namespace on the Docker Hub registry at:

​	**docker search jarvice | grep^jarvice/**

More images, and their PushToCompute™ Work Flow Definition repositories, can be found in the [Nimbix area on GitHub](https://github.com/nimbix). 

![note](img/note.png)Using non-Nimbix base images in the **FROM** directive of your Dockerfile may work, but this use is not explicitly supported.  If your application does not work with a third party base image, please reconstruct it using a Nimbix base image before contacting Nimbix Technical Support. 

## Building parallel applications

For a complete reference on the JARVICE runtime and how to build parallel applications, refer to the [JARVICE Quick Start Guide](https://www.nimbix.net/jarvice-quick-start-guide/).

## Building custom applications and adding to the catalog 

You can create and manage your own private applications by using the **Create** button on the PushToCompute tab as shown here:  

![PUSHtoComputeCreate](img/PUSHtoComputeCreate.png)

Your custom apps can be added to Nimbix' Compute catalog. Once you have created a complete work flow that you'd like to make accessible to other users, please contact [Nimbix Technical Support](https://nimbix.zendesk.com/) and one of our application engineers will help you complete this process.

If you prefer, you can make business arrangements with Nimbix to charge license fees for your application workflows on a per hour basis.

## Deploying PushToCompute work flows

No prior experience designing web interfaces or APIs is required for you to deploy a multi-node high performance computing application that leverages the built-in capabilities of JARVICE on the Nimbix Cloud.

A PushToCompute™ work flow can be deployed directly to **GitHub** or **Bitbucket** for free, continuous integration onto the JARVICE platform at https://platform.jarvice.com.  

Work flows can be launched either from the portal, or via a simple web API call. This provides great flexibility in integrating existing web application components with a server-less  high-density compute back-end powered by JARVICE.

When the JARVICE platform's automatic deployment pipeline is properly configured, every **Git push** to your **PushToCompute™ Work Flow Definition** repository will trigger your application image to be built on Docker Hub.

Once the build is complete, a Docker Hub webhook will trigger the application to be automatically deployed on JARVICE.  (Instructions for hooking up these webhooks can be found in the  [PushToCompute™ Tutorial.](ptc_tutorial.md))

![note](img/note.png) If  you'd prefer to build your container images locally and push them to the Docker Hub or another Docker registry, you may skip the step of git-pushing to the repository.

## Example of building and deploying a work flow

For an example that puts it all together, see the [PushToCompute™ Tutorial.](ptc_tutorial.md)

![blue line](img/blueline.png)

![techsupport](img/techsupport.png)