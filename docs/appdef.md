# Introducing the AppDef

The JARVICE Application Definition (AppDef) Reference describes the application interface for applications that are deployed on JARVICE with PushToCompute&trade;.

The JARVICE Application Definition (AppDef) is a simple JSON object which is used to define:

* The work flow (commands, data and parameters)
* The user interface (the Task Builder web form, and an API schema)
* Validation rules for the automatically generated API to run this application
* The command line entry point into the [Nimbix Application Environment (NAE)](nae.md).

By using a simple, declarative JSON object, the AppDef makes designing work flows and user experiences easy on JARVICE. No prior experience designing web interfaces or APIs is required to deploy a multi-node high performance computing application which leverages the built-in capabilities of JARVICE on the Nimbix Cloud.

# Examples

Nimbix provides various examples in the form of real-world applications - open source deployed on the Nimbix Cloud using JARVICE mechanisms.  By convention, the `AppDef.json` file typically lives in the `NAE` directory at the top of the source tree.  Most repositories in the [Nimbix GitHub account](https://github.com/nimbix) Include both an AppDef as well as directives in their respective `Dockerfile` to deploy it.  You can even start with the default AppDef generated when creating a new application and modify it for your specific workflow - see *Building and Deploying* in the [CI/CD Pipeline](cicd.md) section for more information on this.  The *Container metadata* section of the [Nimbix Application Environment](nae.md) section also describes how to store and validate `AppDef.json` files in your Docker image.  Please note that JARVICE ignores invalid AppDefs when deploying, and will also fail to build an application with an invalid AppDef.

# Reference

## Environment and Configuration

Key|Type|Required/Optional|Description
---|---|---|---
`commands`|command (object)|required|Defines an application command in the application drop-down
`variables`|variable (object)|optional|Defines user and application-defined environment variables which will be available in `/etc/JARVICE/jobenv.sh`. This can be overridden in a command that is defined in the `commands` section.  These variables are set at the account level by Support and not user managed.
`identity`|identity (object)|optional|Defines user identity to use within the JARVICE environment.

## Storage and Machine Options

Key|Type|Required/Optional|Description
---|---|---|---
`machines`|list of strings or shell-style wildcards|required|Machines can be any machine type available on Nimbix, or accepted lazy expansions. For example, `ng*` would make all x86 GPU machine types available for this application. This can be overridden in a command that is defined in the `commands` section.  See [Resource Selection](machines.md) for more information.
`scale_max`|integer|optional|Defines the maximum number of machines allowed for this application. This can be overridden in a command that is defined in the `commands` section.  Typical use is to limit applications to run on a single machine rather than allow the user to launch jobs with multiple nodes for applications that may not support it.
`vault-types`|list of strings|required|(If the application workflow does not support persistent storage, this should be `"vault-types”: [ “NONE” ]`); Defines what storage vaults are supported by the application. Must be one or more of of: `BLOCK`, `BLOCK_ARRAY`, `FILE`, or `NONE`.

## Service Catalog Information

Key|Type|Required/Optional|Description
---|---|---|---
`name`|string|required|Defines the human-readable name of the application.
`description`|string|required|Description of the application used in the application market place icon.
`author`|string|required|Name of the individual or company who authored the application.
`licensed`|boolean|required|Defines whether the application requires an additional license. false = Application needs a third party license in order to run. true = Application pricing includes on-demand license costs or has no additional license fees.
`classifications`|string|required|Defines the categories used for sorting and searching applications.
`image`|image (object)|required|Defines the application icon.

## User-interface Hinting

Key|Type|Required/Optional|Description
---|---|---|---
`hints`|list of strings|optional|Provides "hints" to the user interface, typically used by the Task Builder to influence labeling and default selections; note that hints are suggestions only and may not be supported on all platforms.  This can be overridden in a command that is defined in the `commands` section, to support per-command hints.

### Supported `hints`

#### VAULT:*vault-name*

Specifies that if available, the default vault for the user should be changed to *vault-name* for this command or app.  Example: `VAULT:projects`.  If the vault is not available, the user's default will be preselected instead.

#### SCALE_NODES

Specifies that the scaling slider should show nodes rather than cores as the unis, which may be more appropriate for some types of resources than cores.

#### SCALE_CORES

Specifies that the scaling slider should show cores rather than nodes as the units, which is the default if not specified as a hint.


## `image` Object Reference

Key|Type|Required/Optional|Description
---|---|---|---
`data`|string|required|Base64 image data. This can easily be generated with: `cat image.png | base64 -w0`; Alternatively, the image can be uploaded directly in the PushToCompute&trade; section of the portal.
`type`|string|required|This identifies the media type, e.g., `image/png`

## `commands` Object Reference

NOTE: Commands are named by the key of the JSON object defining the command.

Key|Type|Required/Optional|Description
---|---|---|---
`path`|string|required|Command entry point which is run in the Nimbix Application Environment when the application starts. For a graphical application, this could be `/usr/local/bin/nimbix_desktop` followed by a positional constant parameter with value `/usr/bin/xterm`; For a batch application, this could be the path to a batch script.  Be sure to use a full path here, not just an executable name that you assume to be in `${PATH}`.
`name`|string|required|Command’s name, which is used as the title of the command in the application’s catalog entry.
`description`|string|required|Description of the command’s functionality that is used in the application’s catalog entry.
`interactive`|boolean|optional|If true, indicates that the application should be accessible externally via HTTP(s), and requires `/etc/NAE/url.txt` to provide a URL or URL template.  This should be `true` for any application using Nimbix Desktop or providing a web service such as a Jupyter Notebook. It does not guarantee that the application will get a public IP address (this is cloud specific).  Note however that on the Nimbix cloud, `interactive: true` implies `publicip: true` as well (see below)
`publicip`|boolean|optional|If true, requests that the application receive a public IP address and is externally accessible via TCP (and if supported by the cloud, UDP) ports directly.  Note that on the Nimbix cloud, `interactive: true` implies `publicip: true` as well (see above).  Also note that on the Nimbix cloud, `publicip: false` is ignored if `interactive: true` (any interactive application will get a public IP as well).  The best practice, however, is to set `publicip: true` explicitly only if this behavior is desired.
`ports`|list of strings|optional|Instructions for what TCP, UDP, or SCTP ports to forward to an application's public IP address, if available.  This is cloud specific.  The format of each list entry is `<number>/<protocol>`, where `<number>` is the port number, and `<protocol>` is either `tcp`, `udp`, or `sctp` (lowercase).  If not set, JARVICE will forward a default set of ports that can be used for services such as SSH as well as Nimbix Desktop and VNC, all over TCP.  **Please note that protocols may not be currently mixed** (e.g. if one UDP port is used, all ports in the list must be UDP).
`noconnect`|boolean|optional|If true, does not return a web service connect URL even if the application image advertises one in `/etc/NAE/url.txt`; this can be used to hint to the web portal that the specific command should tail the output of stdout in the portal rather than provide a connection link, while still allowing remote access via public IP address as hinted by the `interactive` and `publicip` settings.  The best practice is to set `publicip: true` if using `noconnect: true` and the desire is to retain remote connectivity to the application.
`url`|string|optional|Provides an override for `/etc/NAE/url.txt` per workflow (see [Nimbix Application Environment](nae.md)). The URL connects the end user to whatever service the command provides when clicking on a running application. This is useful for applications that provide commands for jupyter notebook, webpages, VNC desktop, etc. `noconnect: true` will prevent users from interacting with the application via the dashboard.
`parameters`|parameter (object)|required|Parameters are used to construct the arguments passed to the command identified by the `path` key of the command argument.  If the command takes no parameters, this key should still be included and set to `{}`
`machines`|list of strings|optional|Machines can be any machine type available on Nimbix, or accepted lazy expansions. For example, `ng*` would make all x86 GPU machine types available for this application. Including machines in this section overrides the machines defined in global scope and apply specifically to a given command, allowing differnet commands to offer different machine types to run on
`variables`|variable (object)|optional|Defines user and application-defined environment variables which will be available in `etc/JARVICE/jobenv.sh`.  These variables are set at the account level by Support and not user managed.

## `parameters` Object Reference

Parameters are used to construct the arguments passed to the command identified by the `path` key of the `command` object.

Key|Type|Required/Optional|Description
---|---|---|---
`name`|string|required|Name of the parameter (used in the Task Builder).
`description`|string|required|Description of the parameter (used in the Task Builder).
`type`|string|required|Identifies the type of the parameter. One of: `CONST`, `STR`, `INT`, `FLOAT`, `RANGE`, `BOOL`, `selection`, `FILE`, `UPLOAD`
`required`|boolean|required|true if parameter setting is required, false if optional
`variable`|boolean|optional|true if this parameter should be expressed as a variable in `/etc/JARVICE/jobenv.sh` rather than on the command line for the command referred to in the `path` key.  Default is false.
`positional`|boolean|optional|True indicates the value of the parameter should be passed as a positional argument, ordered by the order of JSON objects in the parameters section.
(parameter dependent fields)|–|varies by parameter type|See the parameter definition table below for keys and values required by parameter type.

## `variables` Object Reference

Variables are designed to be used as environment variables and are written to `/etc/JARVICE/jobenv.sh`; these are set in the account itself and managed by Support.  The key of the variable becomes the name of the variable when the job is launched.

Key|Type|Required/Optional|Description
---|---|---|---
`name`|string|required|Defines a human-readable name of the variable.
`description`|string|required|Description of the variable.
`userowned`|boolean|required|If true, then the user may override this value  . If false, it is an account variable which is currently managed and set by Nimbix Support.  Please note that this parameter is currently ignored and is treated as false.
`inherit`|boolean|required|If true, the value of an account variable can be inherited from a team’s payer account.
`required`|boolean|optional|If true, the application will not launch if the variable is not defined.

## `identity` Object Reference

Identity is used to configure a username, group, UID, and/or GID for the Nimbix Application Environment (NAE). These setting will replace the `nimbix` user created by [image-common](https://github.com/nimbix/image-common).

Key|Type|Required/Optional|Description
---|---|---|---
`username`|string|required|Username for JARVICE NAE. Spaces are not supported.
`group`|string|optional|Group for JARVICE NAE. Defaults to `nimbix` if not set.
`uid`|integer|optional|UID for JARVICE NAE. Defaults to `505` if not set.
`gid`|integer|optional|GID for JARVICE NAE. Defaults to `505` if not set.

NOTE:

* Setting the `identity` object for an App will replace the NAE `nimbix` user. The JARVICE API cannot override an `identity` set by an AppDef file.
* Setting `uid/gid` as root (0:0) is NOT supported.
* Using `uid/gid` values less than `1000` may collide with system users/services and should be avoided.

## Parameter Type Reference

### CONST

`CONST` defines a constant value and supports substitutions as well - the user may not modify these parameters.  When the type is `CONST`, the `value` key may be either an actual value or one of the following substitutions:

* `%APIURL%` – public API URL \*
* `%APIUSER%` – username of user who submitted the call \*
* `%APIKEY%` – API key for user who submitted the call \*
* `%CORES%` – number of CPU cores in machine
* `%GPUS%` – number of GPUs in master node
* `%SGPUS%` – number of GPUs in each slave node
* `%RAM%` – amount of RAM in master node, in GB
* `%SRAM%` – amount of RAM in each slave node, in GB
* `%NODES%` – number of nodes selected
* `%TCORES%` – total number of cores selected (`%CORES%` * `%NODES%`)
* `%TGPUS%` – total number of GPUs selected (`%GPUS%` + (`%SGPUS%` * (`%NODES%` – 1)))
* `%TRAM%` – total amount of RAM selected (`%RAM%` + (`%SRAM%` * (`%NODES%` – 1)))
* `%JOBLABEL%` – job label, if specified
* `%MACHINETYPE%` – machine type (e.g. n0, n3, etc.)
* `%VTYPE%` – vault type (e.g. NONE, FILE, OBJECT, BLOCK, BLOCK_ARRAY)
* `%VNAME%` - vault name the job was launched with

\* these substitutions are only available if the application is certified by Nimbix or the user calling the API owns the application; they are intended to facilitate job submission from inside jobs and should be used with care since this action can incur additional usage charges.

### STR

`STR` defines a string value and is the default `type` if not specified.  The `value` key is an arbitrary default value to populate, which the user can edit; this may also be blank.

### INT

`INT` defines an integer value and supports the following keys:

* `value` is the default value (which can be left blank to require an explicit value set)
* `min` is the minimum number
* `max` is the maximum number

### RANGE

`RANGE` defines an integer value using a slider:

* `value` is the default value on which slider will be set
* `min` is the minimum number on the slider
* `max` is the maximum number on the slider
* `step` set the steps on the slider (for example `2` to force even/odd numbers only)

The portal will express this as a slider widget.

### FLOAT

`FLOAT` defines a floating point value and supports the following keys:

* `value` is the default value (which can be left blank to require an explicit value set)
* `min` is the minimum number
* `max` is the maximum number
* `precision` is the maximum number of decimal digits allowed (values will be truncated to this)

### BOOL

`BOOL` defines a boolean value which includes the parameter if true, or omits it if false; this is useful for optional command line parameters.  It supports the following keys:

* `value` is the default, which must be set to true or false; once submitted, if true, the parameter will be listed on the command line, or not listed if false

Boolean parameters are represented as checkbox widgets in the user portal.

### selection

`selection` defines a single selection list and supports the following keys:

* `values` is a list of values; the default will be the first one listed; if empty string is submitted (and is a valid selection), the parameter will not be listed
* `mvalues` is a parallel list of values in machine format; if specified, the index of `values` will be used to fetch the actual value to pass into the application from the `values` list; it must have the same exact dimension as the `values` list; if not specified, only the `values` list will be used

Selection lists are represented as drop down widgets in the user portal.

### FILE

`FILE` defines a file name, and supports the following keys:

* `filter` is a list of wildcards to filter by (standard shell wildcard syntax); if there is more than one wildcard specified, use the \| (vertical bar) to separate them - e.g. to support C and Python files, use `*.c|*.py`

If the selected storage vault is listable (e.g. a `FILE` vault), the user portal will provide a file picker widget.

### UPLOAD

`UPLOAD` defines a file to upload from a local computer to a JARVICE job and supports the following keys:

* `target` specifies the sub path that will be used to mount a file under `/opt` in a JARVICE job
* `filter` is an extension of a MIME Type used to browse files on a local computer - e.g. to browse JSON files, use `.json`
* `size` specifies the maximum size allowed for an upload file in bytes - e.g. 1024 to enforce a limit of 1KB

The `target` key is required and only 1 `UPLOAD` parameter is supported for each command. The `variable` and `positional` parameter keys do not apply to `UPLOAD` parameters.

