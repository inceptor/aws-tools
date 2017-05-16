#!/bin/bash

#Check if package are install
if ! hash jq 2>/dev/null; then
  echo "jq is not install."
  return 1
fi

if ! hash aws 2>/dev/null; then
  echo "aws cli is not install."
  return 1
fi

if ! hash pcregrep 2>/dev/null; then
  echo "pcre (pcregrep) is not install."
  return 1
fi

#Retrive some file location
credentialFileLocation=${AWS_SHARED_CREDENTIALS_FILE};
if [ -z "$credentialFileLocation" ]; then
    credentialFileLocation=~/.aws/credentials
fi

configFileLocation=${AWS_CONFIG_FILE};
if [ -z "$configFileLocation" ]; then
    configFileLocation=~/.aws/config
fi

#Find expired session
matching=$(grep "\[.*\]" "$credentialFileLocation")
if ! [ -z "$matching" ]; then
  echo "Searching expired profiles :"
  matchingExpired=()
  while read line; do
    pname=$(echo $line | sed "s/[]]//g" | sed "s/[[]//g")
    if ! aws sts get-caller-identity --profile $pname 2>/dev/null 1>/dev/null; then
      echo "EXPIRATED : $pname";
      matchingExpired+=("$pname")
    fi
  done <<< "$matching";

  if [ ${#matchingExpired[@]} -ne 0 ]; then
    #delete expired session
    read -p "Do you want to delete ALL the above profile ?! (Yes)?" clean
    if [ "$clean" == "Yes" ]; then
      for (( i=0; i < ${#matchingExpired[@]}; i++ )); do
        echo "$(pcregrep -Mv "\[profile ${matchingExpired[i]}\]\n(region|output).*(\n)?" $configFileLocation)" > $configFileLocation
        echo "$(pcregrep -Mv "\[${matchingExpired[i]}\]\n((aws_access_key_id|aws_secret_access_key|aws_session_token).*\n)*(aws_access_key_id|aws_secret_access_key|aws_session_token).*" "$credentialFileLocation")" > "$credentialFileLocation"
      done
      echo "ALL profiles are deleted."
    else
      echo "No profile deleted."
    fi
  else
    echo "Profile expirated no found."
  fi
else
  echo "You have no configurate a profile. Run : aws configure"
fi
