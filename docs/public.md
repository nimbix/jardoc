JARVICE supports making applications public to end users outside your team.  Additionally on the [Nimbix Cloud](https://www.nimbix.net) it is possible to collect hourly usage charges on a per-application basis.

# Requirements for the Nimbix Cloud

To promote a private or team application for public consumption on the Nimbix Cloud, it must meet the following requirements:

- Be deployed from a properly constructed Docker image created and tested with the PushToCompute&trade; [CI/CD Pipeline](cicd.md) mechanism
- Contain its own AppDef, not just use the default, with the following minimum enhancements:
    - Proper application title value for the ```name``` key
    - Proper application description value for the ```description``` key
    - Proper author or company name value for the ```author``` key
    - Proper list of category or categories in the ```classifications``` key - please see the top level categories in the [Material Compute](https://mc.jarvice.com) portal and ensure the application is categorized under one of those.  For example, a preprocessing application for simulation workflows would contain:
        ```
        "classifications": ["Simulation/Preprocessing"]
        ```
    - Proper ```command``` (with ```parameters``` definitions) - you should not use the defaults here.  If your application consists of running a single command, please create a command definition for that command
    - Proper icon, either loaded in the [Material Compute](https://mc.jarvice.com) portal and then downloaded in ```AppDef.json```, or encoded into the ```AppDef.json``` locally

## Additional Notes about embedding AppDefs in Docker images

Please note that the best practice when embedding an AppDef is to both copy the json file into the image as well as call the Nimbix API's public validation endpoint.  This will cause the Docker build to fail if the AppDef is invalid.  For example, if ```AppDef.json``` is adjacent to ```Dockerfile``` in your build tree, you would add the following 2 lines to the ```Dockerfile```:

```Dockerfile
COPY AppDef.json /etc/NAE/AppDef.json
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://api.jarvice.com/jarvice/validate
```

## Additional Requirements if Charging for Usage

If the application has usage fees associated with it, its author must also provide technical support.  Part of your request for promotion must include the following:

- A support contact via email
- A high level explanation of how the application works including typical use cases and special terminology that first line support personnel may encounter
- (optional but highly recommended): sample data that can be used to test the application's typical use cases

If you do not intend to charge for usage, your application will be deployed in the *Community* top-level category and will not be considered a certified application.  Users requesting support for application-specific issues will be directed to contact the author.

## Dedicated Licensing versus Usage Licensing

Some applications are licensed with keys or license servers rather than allowing users to pay for usage.  If your application works like this, please contact [Nimbix Support](https://nimbix.zendesk.com) to arrange terms.  You should expect that the license server address or the license key will live in a variable sourced from ```/etc/JARVICE/jobenv.sh```.  Please be prepared to tell Nimbix Support what this variable is and how it should be set (e.g. the address of a license server, etc.).

# Best Practices and Examples

Please visit the [Nimbix GitHub space](https://github.com/nimbix) for examples on constructing various public catalog applications.  Here are some useful links (please check the entire space for the latest however):

- Remote visualization application: [ParaView](https://github.com/nimbix/app-paraview)
- Batch and interactive processing: [Canu Pipeline](https://github.com/nimbix/app-canupipeline)
- Ephemeral developer environment: [PowerAI](https://github.com/nimbix/powerai)
- Web service application: [DIGITS](https://github.com/nimbix/app-digits)

