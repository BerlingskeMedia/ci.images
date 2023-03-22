#!/bin/bash

# Errors
#trap "exit $EXIT_CODE" TERM
trap "exit 1" TERM
export TOP_PID=$$

function killMe()
{
  EXIT_CODE=$1
  rm $_temp_logfile
  kill -s TERM $TOP_PID
  exit 1
}

# Open a new file descriptor that redirects to stdout:
exec 3>&1

export AWS_DEFAULT_REGION=${PLUGIN_AWS_DEFAULT_REGION:-eu-west-1}

_access_key=$PLUGIN_ACCESS_KEY
_secret_key=$PLUGIN_SECRET_KEY
_repo=$PLUGIN_REPOSITORY
_tag_origin=$PLUGIN_TAG_ORIGIN
_tag_dest=$PLUGIN_TAG_DESTINATION

_log_mode=${PLUGIN_LOG_MODE:-1}
_log_prefix="[TAGGER]"


log ()
{
  log_mode_prefix=""
  case $1 in
    trace)
      log_mode_prefix="[TRACE]"
      if [[ $_log_mode -lt 3 ]]; then return; fi
      shift
      ;;
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

function createTempFile()
{
  local _filename="/tmp/$(date +%s%N)_${RANDOM}"
  echo $_filename
}


_temp_logfile=$(createTempFile)

# Check if parameters given
if [ -z "$_repo" ]; then
  log error "Got empty argument: repository"
  killMe 2
fi
if [ -z "$_tag_origin" ]; then
  log error "Got empty argument: tag-origin"
  killMe 2
fi
if [ -z "$_tag_dest" ]; then
  log error "Got empty argument: tag-destination"
  killMe 2
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

# Check STS identity
ERROR=$( { aws sts get-caller-identity  1>$_temp_logfile ;} 2>&1 )
log trace "$(cat $_temp_logfile)"

# Print last error
if [ -n "$ERROR" ]; then
  log error "$ERROR"
  killMe 3
fi


# Check if origin tag exists
if error=$(aws ecr batch-get-image --repository-name $_repo --image-ids imageTag=$_tag_origin --output json | jq -re '.failures[0]?'); then
    log trace "$error"
	log error Given origin tag: $_tag_origin does not exist in repository: $_repo
	log warn  exit with failure!
	exit 1
fi

# Check if destination tag exists
if digest_destination=$(aws ecr batch-get-image --repository-name $_repo --image-ids imageTag=$_tag_dest --output json | jq -re '.images[0].imageId.imageDigest'); then
  # Compare origin and destination digest, if equal exit with no changes
  digest_origin=$(aws ecr batch-get-image --repository-name $_repo --image-ids imageTag=$_tag_origin --output json | jq -re '.images[0].imageId.imageDigest')
  if [[ "$digest_destination" == "$digest_origin" ]]; then
    log info "Origin image (tag: $_tag_origin) already has tag: $_tag_dest (the same digest)."
	log info Quit with no changes
	exit 0
  fi
fi

MANIFEST=$(aws ecr batch-get-image --repository-name $_repo --image-ids imageTag=$_tag_origin --output json | jq --raw-output --join-output '.images[0].imageManifest')
log debug "$(aws ecr put-image --repository-name $_repo --image-tag $_tag_dest --image-manifest "$MANIFEST")"

# Once again check if destination and origin digest are the same, if not, exit with error
# Check if destination tag exists
if digest_destination=$(aws ecr batch-get-image --repository-name $_repo --image-ids imageTag=$_tag_dest --output json | jq -re '.images[0].imageId.imageDigest'); then
  # Compare origin and destination digest, if equal exit with no changes
  digest_origin=$(aws ecr batch-get-image --repository-name $_repo --image-ids imageTag=$_tag_origin --output json | jq -re '.images[0].imageId.imageDigest')
  if [[ "$digest_destination" == "$digest_origin" ]]; then
    log info Successfull tagged image with tag: $_tag_dest
  else
    log error error Failed to tag image $_tag_origin with new tag: $_tag_dest
    killMe 1
  fi
else
  log error error Failed to tag image $_tag_origin with new tag: $_tag_dest
  killMe 1
fi

log info Exiting
rm $_temp_logfile