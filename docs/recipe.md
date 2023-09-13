# Overview

## Full script

The script below provides a good example of how to use the various JARVICE API
endpoints to control and interact with a job in the Nimbix Public Cloud.  The
example is a bit superfluous, but that is with the intent of showing how to
use as many of the JARVICE API endpoints as possible:

### [jarvice-job-exec](recipe/jarvice-job-exec)
```
#!/bin/bash

#set -x  # Trace script execution

jarvice_api_url="https://cloud.nimbix.net/api"
jarvice_api_url+="/jarvice"

# Updating these values will modify the default job submit JSON below
jarvice_app="jarvice-filemanager"
jarvice_application_command="filemanager"
jarvice_application_geometry="1423x812"
jarvice_machine_type="n0"
jarvice_machine_nodes="1"
jarvice_vault_name="drop.jarvice.com"
jarvice_user_username=
jarvice_user_apikey=

# Parse JSON text to get values based upon given key
function get_json_value {
    json=$1
    key=$2
    echo "$json" | \
        python -c "import json,sys;obj=json.load(sys.stdin);print obj$key;" \
        2>/dev/null
}

function jarvice_api_endpoint {
    endpoint=$1
    jarvice_endpoint_url="$jarvice_api_url/$endpoint"

    # If $2 starts with '{', it must be JSON for POSTing
    if echo "$2" | grep -q '^ *{'; then
        curl -s -d "$2" "$jarvice_endpoint_url"
    else
        shift
        while [ $# -gt 0 ]; do
            echo $1
            extra_args+=" --data-urlencode $1"
            shift
        done

        # The job's number could be used instead of the job's name
        # Example: --data-urlencode "number=$jarvice_job_number"
        curl -s --get "$jarvice_endpoint_url" \
            --data-urlencode "username=$jarvice_user_username" \
            --data-urlencode "apikey=$jarvice_user_apikey" \
            --data-urlencode "name=$jarvice_job_name" \
            $extra_args
    fi
}

# Interaction function can be overridden with script from command line args.
# This default fucntion works with jarvice-filemanager to upload/download
# files to/from JARVICE vaults.
function jarvice_job_plugin {
    cmd="$1"
    src="$2"
    dst="$3"

    webdav_url="https://$jarvice_job_address/owncloud/remote.php/webdav/"
    curl="curl -u nimbix:$jarvice_job_password -s -k"
    curl+=" --retry-delay 1 --retry 30 --retry-connrefused"
    if [ "$cmd" = "--upload" ]; then
        echo "Uploading $src to $dst..."
        $curl --upload-file "$src" "$webdav_url$dst"
    elif [ "$cmd" = "--download" ]; then
        echo "Downloading $src to $dst..."
        $curl --output "$dst" "$webdav_url$src"
    else
        echo "jarvice_job_plugin function failed!  Unknown command '$cmd'!"
    fi
}

function jarvice_job_exec_usage {
    echo "Usage: $0 [options] -- <jarvice_job_plugin_options>"
    echo "Available [options]:"
    echo -e " --username\tJARVICE user username"
    echo -e " --apikey\tJARVICE user apikey"
    echo -e " --job-json\tJSON defining the JARVICE job to run"
    echo -e " --job-action\tExecute defined action for this app"
    echo -e " --job-output\tView job output upon successful completion"
    echo -e " --job-plugin\tPlugin file to source jarvice_job_plugin" \
        "function from"
    echo -e " --job-plugin-skip\tSkip execution of jarvice_job_plugin"
}

while [ $# -gt 0 ]; do
    case $1 in
        --help)
            jarvice_job_exec_usage
            exit 0
            ;;
        --username)
            jarvice_user_username=$2
            shift; shift
            ;;
        --apikey)
            jarvice_user_apikey=$2
            shift; shift
            ;;
        --job-json)
            jarvice_job_submit_json="$(cat $2)"
            shift; shift
            ;;
        --job-action)
            jarvice_job_action=$2
            shift; shift
            ;;
        --job-output)
            jarvice_job_output=y
            shift
            ;;
        --job-plugin)  # to override jarvice_job_plugin
            . $2
            shift; shift
            ;;
        --job-plugin-skip)
            jarvice_job_plugin_skip=y
            shift
            ;;
        --)  # args after "--" will be passed to jarvice_job_plugin
            shift
            break
            ;;
        *)
            jarvice_job_exec_usage
            exit 1
            ;;
    esac
done

# The JSON can be found under the "Preview Submission" tab when kicking off a
# job from https://cloud.nimbix.net/
[ -z "$jarvice_job_submit_json" ] && jarvice_job_submit_json=$(cat <<EOF
{
  "app": "$jarvice_app",
  "staging": false,
  "checkedout": false,
  "application": {
    "command": "$jarvice_application_command",
    "geometry": "$jarvice_application_geometry"
  },
  "machine": {
    "type": "$jarvice_machine_type",
    "nodes": $jarvice_machine_nodes
  },
  "vault": {
    "name": "$jarvice_vault_name",
    "force": false,
    "readonly": false
  },
  "user": {
    "username": "$jarvice_user_username",
    "apikey": "$jarvice_user_apikey"
  }
}
EOF
)

# If $jarvice_user_username or $jarvice_user_apikey were not specified on the
# command line, grab them from the job JSON.  They are required for
# interacting with the JARVICE API.
[ -z "$jarvice_user_username" ] && \
    jarvice_user_username=$(get_json_value "$jarvice_job_submit_json" \
        "['user']['username']")
[ -z "$jarvice_user_username" ] && echo "JARVICE username is empty!" \
    && jarvice_job_exec_usage && exit 1
[ -z "$jarvice_user_apikey" ] && \
    jarvice_user_apikey=$(get_json_value "$jarvice_job_submit_json" \
        "['user']['apikey']")
[ -z "$jarvice_user_apikey" ] && echo "JARVICE apikey is empty!" \
    && jarvice_job_exec_usage && exit 1

echo "Submitting JARVICE job..."
json_result=$(jarvice_api_endpoint "submit" "$jarvice_job_submit_json")
jarvice_job_name=$(get_json_value "$json_result" "['name']")
jarvice_job_number=$(get_json_value "$json_result" "['number']")

sleep 2
# Once we're able to get job info, we know everything is up and running.
echo "Getting JARVICE job info..."
while : ; do 
    sleep 1
    json_result=$(jarvice_api_endpoint "info")
    error=$(get_json_value "$json_result" "['error']")
    [ "$error" = "" ] && break
done
jarvice_job_address=$(get_json_value "$json_result" "['address']")
jarvice_job_actions=$(get_json_value "$json_result" "['actions']")
echo "JARVICE job '$jarvice_job_name' is running on host " \
    "'$jarvice_job_address'..."
echo "JARVICE job actions available:"
echo "$jarvice_job_actions"

echo "Getting connect info for JARVICE job '$jarvice_job_name'..."
json_result=$(jarvice_api_endpoint "connect")
jarvice_job_address=$(get_json_value "$json_result" "['address']")
jarvice_job_password=$(get_json_value "$json_result" "['password']")

# Applications with "actions" defined in their AppDef.json will return those
# actions when requesting job info.  They can be executed with the action EP.
if [ -n "$jarvice_job_action" ]; then
    echo "Executing action '$jarvice_job_action' for JARVICE job" \
        " '$jarvice_job_name'..."
    json_result=$(jarvice_api_endpoint "action" "action=$jarvice_job_action")
    echo "$json_result"
fi

# Run shell function which interacts with the running JARVICE job.
[ -z "$jarvice_job_plugin_skip" ] && jarvice_job_plugin "$@"

echo "Shutting down JARVICE job '$jarvice_job_name'..."
json_result=$(jarvice_api_endpoint "shutdown")

echo "Getting status for JARVICE job '$jarvice_job_name'..."
sleep 3  # Give the job some time to shutdown
json_result=$(jarvice_api_endpoint "status")
jarvice_job_status=$(get_json_value "$json_result" \
    "['$jarvice_job_number']['job_status']")

if [ "$jarvice_job_status" = "COMPLETED" ]; then
    echo "Successfully shut down JARVICE job '$jarvice_job_name'..."
    # Get all the output from the completed job
    if [ -n "$jarvice_job_output" ]; then
        echo "JARVICE job output:"
        jarvice_api_endpoint "output"
    fi
else
    echo "JARVICE job '$jarvice_job_name' may not be properly shutting down..."
    echo "Most recent JARVICE job status: $jarvice_job_status"
    echo "Tail of JARVICE job output: $jarvice_job_status"
    jarvice_api_endpoint "tail" "lines=100"
fi

# Still processing?  Forcefully terminate the job..
if [ "$jarvice_job_status" = "PROCESSING STARTING" ]; then
    echo "Terminating JARVICE job '$jarvice_job_name'..."
    json_result=$(jarvice_api_endpoint "terminate")
fi
```

The *jarvice-job-exec* script interacts with the *jarvice-filemanager* by
default in order to upload and download files to and from JARVICE vaults.
After downloading *jarvice-job-exec* with the title link, it can be executed
like so:
```bash
./jarvice-job-exec --username <username> --apikey <apikey> -- --upload ./filename /data/filename
```
```bash
./jarvice-job-exec --username <username> --apikey <apikey> -- --download /data/filename ./filename
```

Executing *jarvice-job-exec* with the *--help* flag will print out it's usage:
```
Usage: ./jarvice-job-exec [options] -- <jarvice_job_plugin_options>
Available [options]:
 --username	JARVICE user username
 --apikey	JARVICE user apikey
 --job-json	JSON defining the JARVICE job to run
 --job-action	Execute defined action for this app
 --job-output	View job output upon successful completion
 --job-plugin	Plugin file to source jarvice_job_plugin function from
 --job-plugin-skip	Skip execution of jarvice_job_plugin
```

## Custom job execution with *jarvice-job-exec*

As seen above, with the *--job-json* argument, it is possible to submit a
JARVICE job with custom JSON using a local file.  The
[JARVICE portal](https://cloud.nimbix.net/) can be used to grab JSON
which can be used as a starting point.  When launching a job from the
[portal](https://cloud.nimbix.net/), click on the "Preview Submission"
tab to copy and paste the job's JSON text.

Here is a JSON file one might use with *--job-json* to override the default
*jarvice-filemanager* job started by *jarvice-job-exec*:

## [jarvice-job.json](recipe/jarvice-job.json)
```
{
  "app": "jarvice-filemanager",
  "staging": false,
  "checkedout": false,
  "application": {
    "command": "filemanager",
    "geometry": "1423x812"
  },
  "machine": {
    "type": "n0",
    "nodes": 1
  },
  "vault": {
    "name": "drop.jarvice.com",
    "force": false,
    "readonly": false
  },
  "user": {
    "username": "<username>",
    "apikey": "<apikey>"
  }
}
```

When specifying custom JSON with a *username* and *apikey* in it, it is no
longer necessary to use the *--username* and *--apikey* arguments when
executing *jarvice-job-exec*.

### [jarvice-filemanager-plugin.sh](recipe/jarvice-filemanager-plugin.sh)

When executing *jarvice-job-exec* with the *--job-plugin* flag, it is possible
to provide customized code for interacting with the job.  The following example
overrides the *jarvice_job_plugin* function.  Unlike the default
*jarvice-filemanager* code in *jarvice-job-exec*, this custom plugin allows
uploading and downloading of files in a single job run:

```
function jarvice_job_plugin_usage {
    echo "Available <jarvice_job_plugin_options>:"
    echo -e " --up <src> <dst>\tUpload local <src> file to remote <dst>"
    echo -e " --down <src> <dst>\tDownload remote <src> file to local <dst>"
}

function jarvice_job_plugin {
    while [ $# -gt 0 ]; do
        case $1 in
            --up)
                upload_src="$2"
                upload_dst="$3"
                shift; shift; shift
                ;;
            --down)
                download_src="$2"
                download_dst="$3"
                shift; shift; shift
                ;;
            *)
                jarvice_job_plugin_usage
                return
                ;;
        esac
    done

    webdav_url="https://$jarvice_job_address/owncloud/remote.php/webdav/"
    curl="curl -u nimbix:$jarvice_job_password -s -k"
    curl+=" --retry-delay 1 --retry 30 --retry-connrefused"
    if [ -n "$upload_src" -a -n "$upload_dst" ]; then
        echo "Uploading $upload_src to $upload_dst..."
        $curl --upload-file "$upload_src" "$webdav_url$upload_dst"
    fi
    if [ -n "$download_src" -a -n "$download_dst" ]; then
        echo "Downloading $download_src to $download_dst..."
        $curl --output "$download_dst" "$webdav_url$download_src"
    fi
}
```

With the above JSON and plugin code examples, *jarvice-job-exec* can be
executed like so to customize JARVICE job execution and interaction:
```bash
./jarvice-job-exec --job-json ./jarvice-job.json --job-plugin ./jarvice-filemanager-plugin.sh -- --up ./filename /data/filename --down /data/filename ./filename
```

## Step by step batch job example

In this section, we are going to submit an example job, interact with it, and close it. All endpoints details are given in the API page of this documentation.
Note also that you need to adapt the api HTTP URL to your cluster.

First step is to submit a job. We are going to submit a very simple job, that will download a movie sample in H264, and convert it in H265 using FFMPEG. We will use a public docker hub ffmpeg image for that.

First, lets create our json file for the job (file will be written as `ffmpeg_job.json` file):

```json
{
  "machine": {
    "type": "n1",
    "nodes": 1
  },
  "vault": {
    "name": "ephemeral",
    "readonly": false,
    "force": false
  },
  "user": {
    "username": "me",
    "apikey": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  },
  "container": {
        "image": "jrottenberg/ffmpeg:latest",
        "jobscript": "/usr/local/bin/ffmpeg -stats -i https://test-videos.co.uk/vids/jellyfish/mp4/h264/1080/Jellyfish_1080_10s_2MB.mp4 -c:v libx265 -f mp4 $HOME/test.mp4"
  }
}
```

Remember to adapt machine, vault, and user dicts to your needs.

Then lets submit a batch job:

```
me@localhost:~$ curl -H 'Content-Type: application/json' -X POST -d @ffmpeg_job.json https://jarvice-api.cloud.nimbix.net/jarvice/batch
{
    "name": "20230906104200-995TB-jarvice-batch-me_s1",
    "number": 123065
me@localhost:~$
```

You can see we got as response a job name. We will use it in next steps.

Now lets request the status of our job:

```
me@localhost:~$ curl -X GET 'https://jarvice-api.cloud.nimbix.net/jarvice/status?username=me&apikey=XXXXXXXXXXXXXXXXXXXXXX&name=20230906104200-995TB-jarvice-batch-me_s1'
{
    "123065": {
        "job_name": "20230906104200-995TB-jarvice-batch-me_s1",
        "job_status": "PROCESSING STARTING",
        "job_substatus": 0,
        "job_start_time": 1693996925,
        "job_end_time": 0,
        "job_submit_time": 1693996920,
        "job_application": "jarvice-batch",
        "job_command": "Batch",
        "job_walltime": null,
        "job_project": null
    }
}me@localhost:~$ 
```

We can see that the job still havent started yet. If we wait some time and come back with the same command:

```
me@localhost:~$ curl -X GET 'https://jarvice-api.cloud.nimbix.net/jarvice/status?username=me&apikey=XXXXXXXXXXXXXXXXXXXXXX&name=20230906104200-995TB-jarvice-batch-me_s1'
{
    "123065": {
        "job_name": "20230906104200-995TB-jarvice-batch-me_s1",
        "job_status": "COMPLETED",
        "job_substatus": 0,
        "job_start_time": 1693996925,
        "job_end_time": 1693996942,
        "job_submit_time": 1693996920,
        "job_application": "jarvice-batch",
        "job_command": "Batch",
        "job_walltime": "00:00:17",
        "job_project": null
    }
me@localhost:~$
```

We can now see it is completed.

Lest request the logs output for this job now:

```
me@localhost:~$ curl -X GET 'https://jarvice-api.cloud.nimbix.net/jarvice/output?username=me&apikey=XXXXXXXXXXXXXXXXXXXXXX&name=20230906104200-995TB-jarvice-batch-me_s1'

INIT[1]: Configuring user: nimbix nimbix 505...
INIT[1]: Initializing networking...
INIT[1]: WARNING: Cross Memory Attach not available for MPI applications
INIT[1]: Platform fabric and MPI libraries successfully deployed
INIT[1]: Detected preferred MPI fabric provider: tcp
INIT[1]: Reading keys...
INIT[1]: Finalizing setup in application environment...
INIT[1]: Waiting for job configuration before executing application...
INIT[1]: hostname: jarvice-job-123065-x9m4v
INIT[1]: Injecting static ssh client.
INIT[1]: Starting SSHD server...
INIT[1]: Checking all nodes can be reached through ssh...
INIT[1]: SSH test success!
###############################################################################

ffmpeg version 4.1 Copyright (c) 2000-2018 the FFmpeg developers
  built with gcc 5.4.0 (Ubuntu 5.4.0-6ubuntu1~16.04.11) 20160609
  configuration: --disable-debug --disable-doc --disable-ffplay --enable-shared --enable-avresample --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-gpl --enable-libass --enable-libfreetype --enable-libvidstab --enable-libmp3lame --enable-libopenjpeg --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx265 --enable-libxvid --enable-libx264 --enable-nonfree --enable-openssl --enable-libfdk_aac --enable-libkvazaar --enable-libaom --extra-libs=-lpthread --enable-postproc --enable-small --enable-version3 --extra-cflags=-I/opt/ffmpeg/include --extra-ldflags=-L/opt/ffmpeg/lib --extra-libs=-ldl --prefix=/opt/ffmpeg
  libavutil      56. 22.100 / 56. 22.100
  libavcodec     58. 35.100 / 58. 35.100
  libavformat    58. 20.100 / 58. 20.100
  libavdevice    58.  5.100 / 58.  5.100
  libavfilter     7. 40.101 /  7. 40.101
  libavresample   4.  0.  0 /  4.  0.  0
  libswscale      5.  3.100 /  5.  3.100
  libswresample   3.  3.100 /  3.  3.100
  libpostproc    55.  3.100 / 55.  3.100
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'https://test-videos.co.uk/vids/jellyfish/mp4/h264/1080/Jellyfish_1080_10s_2MB.mp4':
  Metadata:
    major_brand     : isom
    minor_version   : 512
    compatible_brands: isomiso2avc1mp41
  Duration: 00:00:10.01, start: 0.000000, bitrate: 1676 kb/s
    Stream #0:0(und): Video: h264 (avc1 / 0x31637661), yuv420p, 1920x1080 [SAR 1:1 DAR 16:9], 1672 kb/s, 29.97 fps, 29.97 tbr, 11988 tbn, 59.94 tbc (default)
    Metadata:
      handler_name    : VideoHandler
Stream mapping:
  Stream #0:0 -> #0:0 (h264 (native) -> hevc (libx265))
Press [q] to stop, [?] for help
x265 [info]: HEVC encoder version 2.3
x265 [info]: build info [Linux][GCC 5.4.0][64 bit] 8bit+10bit+12bit
x265 [info]: using cpu capabilities: MMX2 SSE2Fast SSSE3 SSE4.2 AVX AVX2 FMA3 LZCNT BMI2
x265 [info]: Main profile, Level-4 (Main tier)
x265 [info]: Thread pool created using 16 threads
x265 [info]: Slices                              : 1
x265 [info]: frame threads / pool features       : 5 / wpp(17 rows)
x265 [info]: Coding QT: max CU size, min CU size : 64 / 8
x265 [info]: Residual QT: max TU size, max depth : 32 / 1 inter / 1 intra
x265 [info]: ME / range / subpel / merge         : hex / 57 / 2 / 2
x265 [info]: Keyframe min / max / scenecut / bias: 25 / 250 / 40 / 5.00
x265 [info]: Lookahead / bframes / badapt        : 20 / 4 / 2
x265 [info]: b-pyramid / weightp / weightb       : 1 / 1 / 0
x265 [info]: References / ref-limit  cu / depth  : 3 / on / on
x265 [info]: AQ: mode / str / qg-size / cu-tree  : 1 / 1.0 / 32 / 1
x265 [info]: Rate Control / qCompress            : CRF-28.0 / 0.60
x265 [info]: tools: rd=3 psy-rd=2.00 rskip signhide tmvp strong-intra-smoothing
x265 [info]: tools: lslices=6 deblock sao
Output #0, mp4, to '/home/nimbix/test.mp4':
  Metadata:
    major_brand     : isom
    minor_version   : 512
    compatible_brands: isomiso2avc1mp41
    encoder         : Lavf58.20.100
    Stream #0:0(und): Video: hevc (libx265) (hev1 / 0x31766568), yuv420p, 1920x1080 [SAR 1:1 DAR 16:9], q=2-31, 29.97 fps, 11988 tbn, 29.97 tbc (default)
    Metadata:
      handler_name    : VideoHandler
      encoder         : Lavc58.35.100 libx265
frame=  300 fps= 28 q=-0.0 Lsize=    2360kB time=00:00:09.90 bitrate=1950.6kbits/s speed=0.919x
video:2353kB audio:0kB subtitle:0kB other streams:0kB global headers:2kB muxing overhead: 0.270860%
x265 [info]: frame I:      2, Avg QP:24.36  kb/s: 7139.57
x265 [info]: frame P:     75, Avg QP:26.90  kb/s: 4460.35
x265 [info]: frame B:    223, Avg QP:34.48  kb/s: 1025.40
x265 [info]: Weighted P-Frames: Y:0.0% UV:0.0%
x265 [info]: consecutive B-frames: 2.6% 1.3% 1.3% 93.5% 1.3%

encoded 300 frames in 10.70s (28.05 fps), 1924.90 kb/s, Avg QP:32.52
me@localhost:~$
```

We can see our video was encoded in 10.70s. Since we used in this example an ephemeral vault, our output file is now lost. But you can use a persistent vault (check available ones in the portal) and store output file into /data, which is associated to requested vault during job execution.
