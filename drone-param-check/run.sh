#!/bin/bash

errors=false
param_counter=0
regex_counter=0

for param in $(env | grep -oP "^PLUGIN[^=]+" | grep -v PLUGIN_EXPECTED); do
  if [ -z "${!param}" ]; then
    echo "Empty value in parameter: $param"
    errors=true
  fi
  param_counter=$((param_counter+1))
done

# Check if parameters' values match expected regexes
for param_oryg in $(env | grep -oP "^PLUGIN_EXPECTED[^=]+" ); do
  param=$(echo $param_oryg | sed "s/PLUGIN_EXPECTED/PLUGIN/g")
  res=$(echo ${!param} | grep -oP "${!param_oryg}")
  if [ -z "$res" ]; then
    echo "Parameter: $param doesn't match expected regex: ${!param_oryg}"
    errors=true
  fi
  regex_counter=$((regex_counter+1))
done

if [[ $errors == "true" ]]; then
    echo "There were errors!"
    exit 1
else
  echo "All checks successfull! Checked $param_counter parameters and $regex_counter regexes"
fi