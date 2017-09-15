# Overview

The script below provides a good example of how to use the various JARVICE API
endpoints to control and interact with job in the Nimbix Public Cloud.  The
example is a bit superfluous, but that is with the intent of showing how to
use as much of the JARVICE API endpoints as possible:

# jarvice-job-exec
```
#!/bin/bash

#set -x  # Trace script execution

jarvice_api_url="https://api.jarvice.com"
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
# job from https://platform.jarvice.com/
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

# jarvice-job.json
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

# jarvice-filemanager-plugin.sh
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

