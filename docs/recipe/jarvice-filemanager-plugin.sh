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

