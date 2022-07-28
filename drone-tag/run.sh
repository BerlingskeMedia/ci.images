#!/bin/bash


# Open a new file descriptor that redirects to stdout:
exec 3>&1



_access_key=$PLUGIN_ACCESS_KEY
_secret_key=$PLUGIN_SECRET_KEY
_fetch_version=${PLUGIN_FETCH_VERSION:-false}
_local_path=${PLUGIN_LOCAL_PATH:-".tag"}
_s3_bucket=$PLUGIN_S3_BUCKET
_s3_path=$PLUGIN_S3_PATH
_tag_increment_level=${PLUGIN_TAG_INCREMENT_LEVEL:-0}
_tag_prefix=$PLUGIN_TAG_PREFIX
_tag_prefix_regex=$PLUGIN_TAG_PREFIX_REGEX
_log_mode=${PLUGIN_LOG_MODE:-1}
_s3_use_prefix_as_filename=${PLUGIN_S3_USE_PREFIX_AS_FILENAME:-false}

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


# Initial checks
## Check if access and secret key provided   ###### Actualy should use iam role instead
#if [ -z "$_access_key" ] || [ -z "$_secret_key" ]; then


# Check if s3 bucket and path provided
if [ -z "$_s3_bucket" ] || [ -z "$_s3_path" ]; then
  log error "No S3 bucket or path provided! Exiting!"
  exit 1
fi

# Check if prefix set when _s3_use_prefix_as_filename set on true
if [[ $_s3_use_prefix_as_filename == "true" ]]; then
  if [ -z "$_tag_prefix" ] && [ -z "$_tag_prefix_regex" ]; then
    log error "While using s3_use_prefix_as_filename=true, you have to set at least one of: tag_prefix_regex or tag_prefix"
    exit 3
  fi
fi

# Set your IAM Identity:
if [ -n "$_access_key" ] && [ -n "$_secret_key" ]; then
  log debug "configuring credentials"
  aws configure set aws_access_key_id "$_access_key"
  aws configure set aws_secret_access_key "$_secret_key"
fi

# Check STS identity
ERROR=$(if ! test "$(aws sts get-caller-identity)"; then
  aws sts get-caller-identity
fi 2>&1 > /dev/null)


# Check if able to connect to s3
ERROR=$(if ! test "$(aws s3api list-objects --bucket $_s3_bucket)"; then
  aws s3api list-objects --bucket $_s3_bucket
fi 2>&1 > /dev/null)

# Print last error
if [ -n "$ERROR" ]; then
  log error "$ERROR"
  exit 2
fi

#_found_bucket=$(aws s3api list-buckets | jq ".Buckets[] | select(.Name == \"$_s3_bucket\")")

#if [ -z "$_found_bucket" ]; then
#  ERROR="Given bucket ($_s3_bucket) not found!"
#fi

# Print last error
if [ -n "$ERROR" ]; then
  log error "$ERROR"
  exit 2
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

# If _s3_use_prefix_as_filename=true but failed to evaluate prefix - fail script
# Modify s3_path to use prefix as filename
if [[ $_s3_use_prefix_as_filename == "true" ]]; then
  if [ -z "$_prefix" ]; then
    log error "Failed to evaluate prefix while using s3_use_prefix_as_filename. Please consider setting default prefix"
    exit 3
  fi
  _s3_path="${_s3_path}/${_prefix}"
fi

# Try to download file
rm -f $_local_path
log debug "Fetching object:"
temp_file="/tmp/$(date +%s)_temp_log"
exec 4>$temp_file 5>&2
ERROR=$( { aws s3api get-object --bucket $_s3_bucket --key $_s3_path $_local_path 2>&5 1>&4; } )
if [ -n "$ERROR" ]; then
  log error "$ERROR"
  exit 2
fi
log debug "$(cat $temp_file)"
rm $temp_file
exec 4>&- 5>&-

# Check if there is given file. If not, assume version 0.0.0
if [ -e $_local_path ]; then
  log debug "Downloaded S3 object: S3://$_s3_bucket/$_s3_path"
  _s3_obj_found=true
  _version=$(grep -oP "\d+\.\d+\.\d+$" $_local_path)
else
  log debug "S3 object not found: S3://$_s3_bucket/$_s3_path"
  _s3_obj_found=false
fi

if ! $_s3_obj_found || [ -z "$_version" ]; then
  _version="0.0.0"
fi

log debug "Last version: $_version"



#log debug "PWD:"
#pwd
#log debug "ls: "
#ls -la
#log debug "local path: $_local_path"

# If fetch version set on true, only store outcome in local file and exit
if [[ $_fetch_version == "true" ]]; then
  _output="$(echo $_prefix | sed -r 's/(.+)/\1-/')$_version"
  log info "Current tag: $_output"
  echo $_output > $_local_path
  exit 0
fi

# Increment version only if fetching version disabled
if [[ ! $_fetch_version == "true" ]]; then

  iterator=0
  # modify correct level of version
  IFS='.' read -ra VER <<< "$_version"
  for i in "${VER[@]}"; do
    if [[ $iterator -eq $_tag_increment_level ]]; then
      i=$((i+1))
      VER[$iterator]=$i
    fi
    iterator=$((iterator+1))
  done
  # join array's elements by "."
  _version=$(IFS=. ; echo "${VER[*]}")
fi
_output="$(echo $_prefix | sed -r 's/(.+)/\1-/')$_version"
log info "Current tag: $_output"
echo $_output > $_local_path

# If fetch version set on true, nothing more to do
if [[ $_fetch_version == "true" ]]; then
  exit 0
fi

# save new version in s3 bucket
log debug "Saving new version in S3://$_s3_bucket/$_s3_path"
log debug "$(aws s3api put-object --bucket $_s3_bucket --key $_s3_path --body $_local_path)"

log info exiting


























