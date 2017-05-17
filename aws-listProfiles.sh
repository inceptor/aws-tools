#!/bin/bash

credentialFileLocation=${AWS_SHARED_CREDENTIALS_FILE};
if [ -z $credentialFileLocation ]; then
  credentialFileLocation=~/.aws/credentials
fi

while read line; do
  echo "$line"
done <<< "$(grep "\[.*\]" "$credentialFileLocation" | sed "s/[]]//g" | sed "s/[[]//g")";
