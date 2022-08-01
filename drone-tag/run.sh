#!/bin/bash

# Errors
#trap "exit $EXIT_CODE" TERM
trap "exit 1" TERM
export TOP_PID=$$

function killMe()
{
  EXIT_CODE=$1
  kill -s TERM $TOP_PID
  exit 1
}

# Open a new file descriptor that redirects to stdout:
exec 3>&1



_access_key=$PLUGIN_ACCESS_KEY
_secret_key=$PLUGIN_SECRET_KEY
_fetch_only=${PLUGIN_FETCH_ONLY:-false}
_tag_increment_level=${PLUGIN_TAG_INCREMENT_LEVEL:-0}
_tag_prefix=$PLUGIN_TAG_PREFIX
_tag_prefix_regex=$PLUGIN_TAG_PREFIX_REGEX
_log_mode=${PLUGIN_LOG_MODE:-1}
_tag_clear_sublevels=${PLUGIN_TAG_CLEAR_SUBLEVELS:-false}
_s3_use_prefix_as_filename=${PLUGIN_S3_USE_PREFIX_AS_FILENAME:-false}

_fetch_from=${PLUGIN_FETCH_FROM:-s3}
_fetch_path=$PLUGIN_FETCH_PATH
_save_paths_raw=${PLUGIN_SAVE_PATHS}

_log_prefix="[TAGGER]"


log ()
{
  log_mode_prefix=""
  case $1 in
    debug)
      log_mode_prefix="[DEBUG]"
      if [[ $_log_mode -lt 2 ]]; then return; fi
      shift
      ;;
    info)
      log_mode_prefix="[INFO]"
      if [[ $_log_mode -lt 1 ]]; then return; fi
      shift
      ;;
    warn)
      log_mode_prefix="[WARN]"
      shift
      ;;
    err*)
      log_mode_prefix="[ERROR]"
      shift
      ;;
    *)
      log_mode_prefix="[INFO]"
  esac
  echo "$(date +"[%Y-%m-%d %H:%M:%S]") $_log_prefix $log_mode_prefix $@" 1>&3
}

containsElement ()
{
  ### usage: containsElement $element $arrayToCheck
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function createTempFile()
{
  local _filename="/tmp/$(date +%s%N)_${RANDOM}"
  echo $_filename
}

function increaseVersion()
{
  # Usage: increaseVersion version level
  local iterator=0
  local _v=$1
  local _l=$2
  # modify correct level of version
  IFS='.' read -ra VER <<< "$_v"
  for i in "${VER[@]}"; do
    if [[ $iterator -eq $_l ]]; then
      i=$((i+1))
      VER[$iterator]=$i
    fi
    # clear sublevels if tag_clear_sublevels==true
    if [[ $iterator -gt $_l ]]; then
      if [[ $_tag_clear_sublevels == "true" ]]; then
        VER[$iterator]=0
      fi
    fi
    iterator=$((iterator+1))
  done
  # join array's elements by "."
  echo $(IFS=. ; echo "${VER[*]}")
}

function fetch_version()
{
  # Usage fetch_version (s3|local) path
  # Output: path_to_file_with_fetched_version|path_to_file_with_execution_logs
  local _from=$1
  local _source_path=$2
  # create temp file
  local _filename=$(createTempFile)
  local _log_file=$(createTempFile)
  log debug "Fetching from: ${_from}. Path: $_source_path"
  exec 4>$_log_file 5>&2
  case $_from in
    s3)
      local s3_bucket=$(echo $_source_path | cut -d":" -f1)
      local path=$(echo $_source_path | cut -d":" -f2)
      if [[ $_s3_use_prefix_as_filename == "true" ]]; then
        path="${path}/${_prefix}"
      fi
      # Check if bucket is fine
      ERROR=$( { aws s3 ls --bucket s3://${s3_bucket} 1>/dev/null ;} 2>&1 )
      if [ -n "$ERROR" ]; then
        log error "Failed to connect to bucket: s3://$s3_bucket; Message:" "$ERROR" 1>&2
        killMe 3
      fi

      # Check if given file exists
      local _found_objects=$(aws s3 ls s3://${s3_bucket}/${path} --recursive --summarize | grep "Total Objects: " | sed 's/[^0-9]*//g')

      # Check if there is given file. If so, download, else assume version 0.0.0
      if [[ $_found_objects -ge 1 ]]; then
        log debug "Found $_found_objects object(s) in s3://${s3_bucket}/${path}"
        ERROR=$( { aws s3api get-object --bucket $s3_bucket --key $path $_filename 1>&4 ;} 2>&1 )
        if [ -n "$ERROR" ]; then
          log error "Failed to download from s3://$s3_bucket:$path; Message:" "$ERROR" 1>&2
          killMe 3
        fi
        log debug "Downloaded S3 object: S3://$_source_path" 1>&4
        #_version=$(grep -oP "\d+\.\d+\.\d+$" $_local_path)
      else
        log debug "S3 object not found: S3://$_source_path; Assuming version 0.0.0" 1>&4
        echo "0.0.0" > $_filename
      fi
      ;;
    local)
      if [ ! -e $_source_path ]; then
        log debug "Local file not exist! path: $_source_path; Assuming version 0.0.0" 1>&4
        echo "0.0.0" > $_filename
      else
        cat $_source_path > $_filename
      fi
      ;;
    *)
      log error "Wrong _from in fetch_version()! Got: $_from ; Exiting" 1>&4
      killMe 2
      ;;
  esac
  exec 4>&- 5>&-
  echo "${_filename};${_log_file}"
}

function storeVersion()
{
  # usage: storeVersion tagged_version type1=path1 type2=path2 ...
  # Returns - path to log file (containing execution log)
  local _temp_file=$(createTempFile)
  local _temp_error=$(createTempFile)
  local _temp_log=$(createTempFile)
  local version=$1
  shift
  echo $version > $_temp_file
  exec 4>$_temp_error 5>&2 6>$_temp_log
  while [ -n "$1" ]; do
    # arg: type=path
    local arg=$1
    shift
    local type=$(echo $arg | cut -d"=" -f1)
    local path=$(echo $arg | cut -d"=" -f2)
    if ! $(containsElement $type s3 local); then
      log error "Wrong key in save_paths! use one of: s3, local; Argument: $arg" 1>&2
      killMe 2
    fi
    case $type in
      s3)
        local s3_bucket=$(echo $path | cut -d":" -f1)
        local s3_path=$(echo $path | cut -d":" -f2)
        if [[ $_s3_use_prefix_as_filename == "true" ]]; then
          s3_path="${s3_path}/${_prefix}"
        fi
        log debug "Saving new version in S3://$s3_bucket/$s3_path" 1>&6
        ERROR=$( { aws s3api put-object --bucket $s3_bucket --key $s3_path --body $_temp_file 1>&6 ;} 2>&1 )
        if [ -n "$ERROR" ]; then
          log error "Failed to download from s3://$s3_bucket:$s3_path; Message:" "$ERROR" 1>&2
          killMe 3
        fi
        #log debug "$(aws s3api put-object --bucket $s3_bucket --key $s3_path --body $_temp_file 2>&4)" 1>&6
        ;;
      local)
        cp $_temp_file $path
        log debug "Stored version in file: $path" 1>&6
        ;;
      *)
        log error "Wrong _type in storeVersion()! Got $type ; Exiting" 1>&2
        killMe 2
        ;;
    esac
  done
  exec 4>&- 5>&-
  if [ -e $_temp_error ] && [ -s $_temp_error ]; then
    log error $(cat $_temp_error) 1>&2
    killMe 1
  fi
  rm $_temp_file
  rm $_temp_error
  echo $_temp_log
}

# Check if prefix set when _s3_use_prefix_as_filename set on true
if [[ $_s3_use_prefix_as_filename == "true" ]]; then
  if [ -z "$_tag_prefix" ] && [ -z "$_tag_prefix_regex" ]; then
    log error "While using s3_use_prefix_as_filename=true, you have to set at least one of: tag_prefix_regex or tag_prefix"
    killMe 2
  fi
fi

# Set your IAM Identity:
if [ -n "$_access_key" ] && [ -n "$_secret_key" ]; then
  log debug "configuring credentials"
  ERROR=$( { aws configure set aws_access_key_id "$_access_key" ;} 2>&1 )
  ERROR=$( { aws configure set aws_secret_access_key "$_secret_key" ;} 2>&1 )
  if [ -n "$ERROR" ]; then
    log error "Error with aws credentials! Message: $ERROR"
    killMe 3
  fi
fi
# Check if proper value of `fetch_from`
if ! $(containsElement $_fetch_from s3 local); then
  log error "Wrong value of fetch_from! use one of: s3, local; got: $_fetch_from"
  killMe 2
fi

# Check STS identity
ERROR=$( { aws sts get-caller-identity  1>/dev/null ;} 2>&1 )

# Print last error
if [ -n "$ERROR" ]; then
  log error "$ERROR"
  killMe 3
fi

# If tag_prefix_regex set, try to get it from branch name or tag name. If succeeded, overwrite tag_prefix
if [ -n "$_tag_prefix_regex" ]; then
  if [ -n "$DRONE_SOURCE_BRANCH" ]; then
    _prefix=$(echo $DRONE_SOURCE_BRANCH | grep -oP "$_tag_prefix_regex")
    log debug "Found matching prefix pattern in branch name: $_prefix"
  fi
  if [ -n "$DRONE_TAG" ]; then
    _prefix=$(echo $DRONE_TAG | grep -oP "$_tag_prefix_regex")
    log debug "Found matching prefix pattern in tag name: $_prefix"
  fi
fi

if [[ $_s3_use_prefix_as_filename == "true" ]]; then
  if [ -z "$_prefix" ]; then
    log error "Failed to evaluate prefix while using s3_use_prefix_as_filename. Please consider setting default prefix"
    killMe 2
  fi
fi

# Fetch file
_out_files=$(fetch_version $_fetch_from $_fetch_path)

_temp_file=$(echo $_out_files | cut -d";" -f1)
_temp_log_file=$(echo $_out_files | cut -d";" -f2)
cat $_temp_log_file
rm $_temp_log_file
unset _temp_log_file

_version=$(grep -oP "\d+\.\d+\.\d+" $_temp_file)
rm $_temp_file

if [ -z "$_version" ]; then
  _version="0.0.0"
fi

log debug "Last version: $_version"

# Increase version:
if [[ ! $_fetch_only == "true" ]]; then
  _version=$(increaseVersion $_version $_tag_increment_level)
  log debug "Current version: $_version"
fi

_output="$(echo $_prefix | sed -r 's/(.+)/\1-/')$_version"
log debug "Output version: $_output"


# Split save paths
IFS=',' read -ra _PATHS <<< "$_save_paths_raw"
log debug "Paths: ${_PATHS[@]}"
# Execute storeVersions and read stored logs
cat $(storeVersion $_output ${_PATHS[@]})

log info Exiting


























