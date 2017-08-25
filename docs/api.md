# Overview

The JARVICE API allows full control on running jobs as well as managing applications via PushToCompute&trade;.  The API server delivers the endpoints below - for the Nimbix Public Cloud the API server is [https://api.jarvice.com/](https://api.jarvice.com).

Unless otherwise noted, all endpoints support both GET and POST request methods.  Also, unless otherwise noted, responses deliver both an HTTP status code and a JSON payload.

In all cases referring to an API key, this is available from the JARVICE portal in the *Account* section.  This is not the same as the password used to log into the portal.

# Job Control

These API endpoints allow you to submit jobs and control their execution.  Jobs run on one or more compute nodes and launch the image of an application from the service catalog.

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

##### Notes

1. One of ``name`` or ``number`` must be specified

2. Action is requested asynchronously - if the action produces output in a batch job, it can be checked with [/jarvice/tail](#jarvicetail)


## /jarvice/shutdown

Requests a graceful termination of a job, executing the operating system ```poweroff``` mechanism if applicable.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

##### Response

On success: ```{"status": "shutdown requested"}

##### Notes

1. One of ``name`` or ``number`` must be specified

2. Shutdown is requested asynchronously - job status can be monitored with [/jarvice/status](#jarvicestatus)


## /jarvice/submit

Submits a job for processing. The body is in JSON format and can be generated from the JARVICE web portal by clicking the *PREVIEW SUBMISSION* tab in the task builder and copying its contents to the clipboard - e.g.:

![Preview Submission](taskbuilder.png)

Click the copy icon above the *SUBMIT* button to copy the contents of the API call to the clipboard.

##### Parameters

**POST only**: JSON payload to run the compute job, generated as specified above.  If copying from the web portal, paste the text into a file or script to use as the JSON payload to submit.  Please note that authentication is performed from the ```username``` and ```apikey``` values in the JSON itself.

##### Response

On success, a JSON payload indicating the job name and job number (with ```name``` and ```number``` keys).

##### Notes

1. All boolean values default to ```false``` if not specified

2. The ```nodes``` parameter in the machine section defaults to ```1``` if not specified

3. Even if a ```vault``` section is specified, ```password``` is optional and should only be supplied for encrypted block vaults

4. Even if ```vault``` section is specified, vault ```objects``` is optional and applies only to object storage vaults; it indicates which objects should be moved into the environments's backing store for processing. If ```readonly``` is set to ```false```, JARVICE automatically copies any new or changed objects from the backing store back to the object storage on normal job completion (but not immediate termination with [/jarvice/terminate](#jarviceterminate)).

5. ```ipaddr``` will be validated by the underlying platform for authorization for the user; it may also fail if the address is already assigned (but this won't be known until the job starts running).

## /jarvice/terminate

Immediately terminates a running job.

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - job name (name key returned from [/jarvice/submit](#jarvicesubmit))

* ```number``` (optional) - job number (number key returned from [/jarvice/submit](#jarvicesubmit))

##### Response

On success: ```{"status": "terminated"}```

##### Notes

1. One of ``name`` or ``number`` must be specified

# STATUS AND INFORMATION

## /jarvice/appdef

## /jarvice/apps

Returns information about available application(s).

##### Parameters

* ```username``` - name of user to authenticate

* ```apikey``` - API key for user to authenticate

* ```name``` (optional) - name of application to return information for (default, if not specified: all)

##### Response

On success, a JSON payload with application information for each available application, or for the specific application name if available. The application name is used as the dictionary key, and the data subkey contains the raw definition in JSON format. The price value is the application price itself, not including underlying machine price (which is available by querying the machine type using [/jarvice/machines](#jarvicemachines)).

Note that application name is the application ID, not necessarily the same as the human readable ```name``` in the AppDef for the given application.


## /jarvice/connect

## /jarvice/info

## /jarvice/jobs

## /jarvice/machines

## /jarvice/output

## /jarvice/screenshot

## /jarvice/status

## /jarvice/tail

# PushToCompute&trade;

## /jarvice/history

## /jarvice/pull

## /jarvice/build

## /jarvice/validate


