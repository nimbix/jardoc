# Overview

The JARVICE API allows full control on running jobs as well as managing applications via PushToCompute&trade;.  The API server delivers the endpoints below - for the Nimbix Public Cloud the API server is [https://api.jarvice.com/](https://api.jarvice.com).

Unless otherwise noted, all endpoints support both GET and POST request methods.  Also, unless otherwise noted, responses deliver both an HTTP status code and a JSON payload.

In all cases referring to an API key, this is available from the JARVICE portal in the *Account* section.  This is not the same as the password used to log into the portal.

# Job Control

These API endpoints allow you to submit jobs and control their execution.  Jobs run on one or more compute nodes and launch the image of an application from the service catalog.


---
## /jarvice/action

Executes an application-defined command inside a running job.  The command runs asynchronously and its standard output/standard error is accessible with [/jarvice/tail](#jarvicetail) while the job is running.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

* ```action``` - the name of the action to run (must be a valid action from [/jarvice/info](#jarviceinfo))

##### Response

On success: ```{"status": "action requested"}```

##### Additional Notes

1. One of ``name`` or ``number`` must be specified

2. Action is requested asynchronously - if the action produces output in a batch job, it can be checked with [/jarvice/tail](#jarvicetail)


---
## /jarvice/shutdown

Requests a graceful termination of a job, executing the operating system ```poweroff``` mechanism if applicable.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

##### Response

On success: ```{"status": "shutdown requested"}

##### Additional Notes

1. One of ``name`` or ``number`` must be specified

2. Shutdown is requested asynchronously - job status can be monitored with [/jarvice/status](#jarvicestatus)


---
## /jarvice/submit

Submits a job for processing. The body is in JSON format and can be generated from the JARVICE web portal by clicking the *PREVIEW SUBMISSION* tab in the task builder and copying its contents to the clipboard - e.g.:

![Preview Submission](taskbuilder.png)

Click the copy icon above the *SUBMIT* button to copy the contents of the API call to the clipboard.

##### Parameters

**POST only**: JSON payload to run the compute job, generated as specified above.  If copying from the web portal, paste the text into a file or script to use as the JSON payload to submit.  Please note that authentication is performed from the ```username``` and ```apikey``` values in the JSON itself.

##### Response

On success, a JSON payload indicating the job name and job number (with ```name``` and ```number``` keys).

##### Additional Notes

1. All boolean values default to ```false``` if not specified

2. The ```nodes``` parameter in the machine section defaults to ```1``` if not specified

3. Even if a ```vault``` section is specified, ```password``` is optional and should only be supplied for encrypted block vaults

4. Even if ```vault``` section is specified, vault ```objects``` is optional and applies only to object storage vaults; it indicates which objects should be moved into the environments's backing store for processing. If ```readonly``` is set to ```false```, JARVICE automatically copies any new or changed objects from the backing store back to the object storage on normal job completion (but not immediate termination with [/jarvice/terminate](#jarviceterminate)).

5. ```ipaddr``` will be validated by the underlying platform for authorization for the user; it may also fail if the address is already assigned (but this won't be known until the job starts running).


---
## /jarvice/terminate

Immediately terminates a running job.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

##### Response

On success: ```{"status": "terminated"}```

##### Additional Notes

1. One of ``name`` or ``number`` must be specified

# Status and Information

These API endpoints allow you to query status or request information from running or completed jobs.


---
## /jarvice/appdef

Returns the Application Definition (AppDef) for a given application.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` - name of application to return information for; please note this is the application ID, not necessarily the same as the ```name``` value in the AppDef

##### Response

On success, a JSON payload with the AppDef requested.


---
## /jarvice/apps

Returns information about available application(s).

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - name of application to return information for (default, if not specified: all)

##### Response

On success, a JSON payload with application information for each available application, or for the specific application name if available. The application name is used as the dictionary key, and the data subkey contains the raw definition in JSON format. The ```price``` value is the application price itself, not including underlying machine price (which is available by querying the machine type using [/jarvice/machines](#jarvicemachines)).

Note that application name is the application ID, not necessarily the same as the human readable ```name``` in the AppDef for the given application.


---
## /jarvice/connect

Requests the network address and user ```nimbix``` password (if set), for an interactive job.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

##### Response

On success, a JSON payload: ```{"address": <network-address>, "password": <nimbix-password>}```

##### Additional Notes

1. One of ```name``` or ```number``` must be specified

2. Job must be running an application endpoint that has ```interactive``` set to ```true``` in its AppDef in order for it to respond successfully

3. This method may take a few seconds to respond successfully after starting a job, as its connection parameters are not known until its application components start


---
## /jarvice/info

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

##### Response

On success, a JSON payload, e.g.:
```
{
    "url": <web-service-URL>
    "about": <about-HTML>
    "help": <help-HTML>
    "actions": {
        <action-1> {
            "alt": <action-description>
        },
        <action-n> {
            "alt": <action-description>
        }
    }
}
```
* *web-service-URL* is intended to be used to connect to an application-specific web service, if one exists, running inside the [application environment](nae.md); the address is accessible from the client; the value is taken from ```/etc/NAE/url.txt``` inside the environment

* All values may be ```null``` if not applicable

##### Additional Notes

1. One of ```name``` or ```number``` must be specified

2. This method may take a few seconds to respond successfully after starting a job, as its connection parameters are not known until its application components start


---
## /jarvice/jobs

Returns job information and status for all queued and running jobs.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```completed``` (optional) - set to ```true``` (case sensitive) to show only completed jobs (default, if not specified: ```false```)

##### Response

On success, a JSON payload with job status for each queued or running job (keyed by job number), formatted like the response of [/jarvice/status](#jarvicestatus)


---
## /jarvice/machines

Returns information about available machine type(s).

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - name of machine type to return information for (default, if not specified: all)

##### Response

On success, a JSON payload with machine information for each available machine type, or for the specific machine ```name``` if available. The machine name is used as the dictionary key.


---
## /jarvice/output

Returns a tail (or optionally all) of the output of a completed job.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

* ```lines``` (optional) - number of lines to tail from the end (default: 100) - use ```0``` to return all lines rather than just a tail

##### Response

On success, the requested output tail in ```text/plain format``` (with single ```\n``` for line breaks), up to and including the number of lines requested; if the total length of the output is less than lines requested, the entire output is returned.  If lines requested is ```0```, all lines in the output are returned rather than just a tail of it.

##### Additional Notes

1. One of ```name``` or ```number``` must be specified

2. Job must have completed; to get the output of a running job instead, use [/jarvice/tail](#jarvicetail)


---
## /jarvice/screenshot

Returns a screenshot for a running job (if it is graphical).

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

* ```width``` (optional) - pixel width to restrict screenshot to

* ```height``` (optional) - pixel height to restrict screenshot to

* ```emphatic``` (optional) - if specified, emphatically resize (disregarding aspect ratio) to specified ```width``` and/or ```height```

##### Response

On success, an ```image/png``` payload with the requested screenshot if available.

##### Additional Notes

1. One of ```name``` or ```number``` must be specified

2. If ```emphatic``` is not specified, but ```width``` and/or ```height``` is, the aspect ratio of the screenshot image is preserved when resizing.


---
## /jarvice/status

Queries status for a previously submitted job.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

##### Response

On success, a JSON payload with job status, formatted as follows:
```
{
    <job-number> {
        "job_name": <job-name>
        "job_status": <job-status>
        "job_submit_time": <job-submit-time>
        "job_start_time": <job-start-time>
        "job_end_time": <job-end-time>
        "job_application": <job-application>
        "job_command": <job-command>
        "job_walltime": <job-walltime>
    }
}
```

* All "time" values are represented in UNIX time (seconds since the Epoch); values may be 0 if the data is not yet available (e.g. a job that hasn't completed yet will have a 0 for ```job_end_time```); additional values may be returned in the future.

##### Additional Notes

1. One of ```name``` or ```number``` must be specified


---
## /jarvice/tail

Returns a tail (or optionally all) of the output of a running job.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

* ```lines``` (optional) - number of lines to tail from the end (default: 100) - use ```0``` to return all lines rather than just a tail

##### Response

On success, the requested output tail in ```text/plain format``` (with single ```\n``` for line breaks), up to and including the number of lines requested; if the total length of the output is less than lines requested, the entire output is returned.  If lines requested is ```0```, all lines in the output are returned rather than just a tail of it.

##### Additional Notes

1. One of ```name``` or ```number``` must be specified

2. Job must still be running; to get the output of a completed job instead, use [/jarvice/output](#jarviceoutput)


# PushToCompute&trade;

These API endpoints allow you to manage JARVICE application images via the PushToCompute&trade; subsystem.  For more information on these mechanisms, please see [CI/CD Pipeline](cicd.md).


---
## /jarvice/history


---
## /jarvice/pull


---
## /jarvice/build


---
## /jarvice/validate


