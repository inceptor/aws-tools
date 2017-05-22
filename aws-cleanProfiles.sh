#!/bin/bash

#Check if package are install
function checkPackage() {
  if ! hash jq 2>/dev/null; then
    echo "jq is not install."
    exit 1
  fi

  if ! hash aws 2>/dev/null; then
    echo "aws cli is not install."
    exit 1
  fi

  if ! hash pcregrep 2>/dev/null; then
    echo "pcre (pcregrep) is not install."
    exit 1
  fi
}

#Return usage if arg value is incorect
function usage() {
  echo "Usage for deleting one profile (no user confirmation required):"
  echo "$0 profileName"
  echo "Usage for deleting all expired profile (interactive mode with no arg) :"
  echo "$0"
  exit 1
}

#Check profile exist
#Arg1 = profileName
function checkProfileExist() {
  exist=false
  while read line; do
    if [ $line == "[$1]" ]; then exist=true; fi;
  done <<< "$(grep "\[.*\]" "$credentialFileLocation")";
  if [ $exist == false ]; then echo "Error: Profile '$1' not in the list." && exit 1; fi
}


###############
# MAIN SCRIPT #
###############

if [ $# -gt 1 ]; then
  usage
elif [ $# -eq 1 ]; then
  profile="$1"
fi

checkPackage

#Retrive some file location
credentialFileLocation=${AWS_SHARED_CREDENTIALS_FILE};
if [ -z "$credentialFileLocation" ]; then
  credentialFileLocation=~/.aws/credentials
fi

configFileLocation=${AWS_CONFIG_FILE};
if [ -z "$configFileLocation" ]; then
  configFileLocation=~/.aws/config
fi

#Security check (check if var env profile can crash the script)
if ! [ -z "$AWS_PROFILE" ]; then
  checkProfileExist "$AWS_PROFILE"
fi

if ! [ -z "$AWS_DEFAULT_PROFILE" ]; then
  checkProfileExist "$AWS_DEFAULT_PROFILE"
fi

#If passing with arg (delete one profile)
if [ $# -eq 1 ]; then
  checkProfileExist "$1"
  if ! aws sts get-caller-identity --profile "$profile" 2>/dev/null 1>/dev/null; then
    echo "$(pcregrep -Mv "\[profile $profile\]\n(region|output).*(\n)?" $configFileLocation)" > $configFileLocation
    echo "$(pcregrep -Mv "\[$profile\]\n((aws_access_key_id|aws_secret_access_key|aws_session_token).*\n)*(aws_access_key_id|aws_secret_access_key|aws_session_token).*" "$credentialFileLocation")" > "$credentialFileLocation"
    echo "$profile deleted."
  else
    echo "$profile is NOT expired."
    echo "The profile was NOT deleted."
    exit 1
  fi
else
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
      exit 1
    fi
  else
    echo "You have no configurate a profile. Run : aws configure"
    exit 1
  fi
fi
