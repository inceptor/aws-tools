#!/bin/bash

#############
# FUNCTIONS #
#############

#Check if package are install
function checkPackage() {
  if ! hash jq 2>/dev/null; then
    echo "jq is not installed."
    exit 1
  fi
  
  if ! hash aws 2>/dev/null; then
    echo "aws cli is not installed."
    exit 1
  fi
  
  if ! hash pcregrep 2>/dev/null; then
    echo "pcre (pcregrep) is not installed."
    exit 1
  fi
}

#Return usage if arg value is incorect
function usage() {
  echo "Usage :"
  echo "$0 MFAtoken [profileNameToCreate] [profileFetchCredentials]" >&2
  echo "TIPS: You can launch the script with interactive mode (no arg)." >&2
  exit 1
}

#Check if profile exist
#Arg1 = profileName
function checkProfileExist() {
  exist=false
  while read line; do
        if [ $line == "[$1]" ]; then exist=true; fi;
  done <<< "$(grep "\[.*\]" "$credentialFileLocation")";
  if [ $exist == false ]; then echo "Error: Profile '$1' not in the list." && exit 1; fi
}

function cleanSessionProfile() {
  #Security check (check if var env profile can crash the script)
  if ! [ -z "$AWS_PROFILE" ]; then
    checkProfileExist "$AWS_PROFILE"
  fi
  
  if ! [ -z "$AWS_DEFAULT_PROFILE" ]; then
    checkProfileExist "$AWS_DEFAULT_PROFILE"
  fi  

  #Find expired session using token only
  matching=$(pcregrep -M "\[.*\]\n((aws_access_key_id|aws_secret_access_key).*\n)*aws_session_token.*" "$credentialFileLocation" | grep "\[.*\]" | sed "s/[]]//g" | sed "s/[[]//g")
  if ! [ -z "$matching" ]; then
    echo "Searching expired mfa profile :"
    matchingExpired=()
    while read line; do
        if ! aws sts get-caller-identity --profile $line 2>/dev/null 1>/dev/null; then
          echo "EXPIRATED : $line";
          matchingExpired+=("$line")
        fi
    done <<< "$matching";

    if [ ${#matchingExpired[@]} -ne 0 ]; then
      #delete expired session
      read -p "Do you want to delete ALL the above profile ?! (Yes)?" clean
      if [ "$clean" == "Yes" ]; then
        for (( i=0; i < ${#matchingExpired[@]}; i++ )); do
          echo "$(pcregrep -Mv "\[profile ${matchingExpired[i]}\]\n(region|output).*(\n)?" "$configFileLocation")" > "$configFileLocation"
          echo "$(pcregrep -Mv "\[${matchingExpired[i]}\]\n((aws_access_key_id|aws_secret_access_key).*\n)*aws_session_token.*" "$credentialFileLocation")" > "$credentialFileLocation"
        done
        echo "All profiles are deleted."
      else
        echo "No profile deleted."
      fi
    else
      echo "MFA Profile session expirated not found."
    fi
  else
    echo "You have no MFA profile session."
  fi
}

function putConfigFile() {
  #To the credential file
  echo "[$pname]" >> $credentialFileLocation
  echo "aws_access_key_id = $ak" >> $credentialFileLocation
  echo "aws_secret_access_key = $sak" >> $credentialFileLocation
  echo "aws_session_token = $sessionToken" >> $credentialFileLocation
  
  #To the config file
  echo "[profile $pname]" >> $configFileLocation
  echo "region = $(aws configure get region --profile $profile)" >> $configFileLocation
  echo "output = json" >> $configFileLocation
  
  #Print info for user
  echo "The session profile is setup :"
  echo "Profile name : $pname"
  echo "Expiration : $(echo $credentials |jq '.Credentials.Expiration')"
  echo "For switching profile execute this commands :" 
  echo "export AWS_DEFAULT_PROFILE=$pname"
  echo "export AWS_PROFILE=$pname"
}

###############
# MAIN SCRIPT #
###############

checkPackage

#Check if the script is use with arg
if [ $# -gt 3 ]; then
  usage
elif [ $# -gt 0 ]; then
  tokenMFA="$1"

  if ! [ -z $2 ]; then
    pname="$2"
  fi

  if ! [ -z $3 ]; then
    profile="$3"
  fi
  interactiveMode=false
else
  interactiveMode=true
fi

#Retrieve some file location
credentialFileLocation=${AWS_SHARED_CREDENTIALS_FILE};
if [ -z "$credentialFileLocation" ]; then
    credentialFileLocation=~/.aws/credentials
fi
  
configFileLocation=${AWS_CONFIG_FILE};
if [ -z "$configFileLocation" ]; then
    configFileLocation=~/.aws/config
fi


if [ $interactiveMode == "true" ]; then  
  #Cleanning conf file
  read -p "Do you want to list expired MFA profile  (y/N)?" clean
  
  #Find expired session using token only
  if [ "$clean" == "Y" ] || [ "$clean" == "y" ]; then
    cleanSessionProfile
  fi
fi

if [ $interactiveMode == true ]; then
  #Get some info by the user
  read -p "New MFA profile name (type enter to generate automatically): " pname
fi

#Check if AWS_PROFILE is configured
if [ -z $AWS_PROFILE ]; then 
  if [ $interactiveMode == true ]; then
    echo "List of profiles configurated : "
    while read line; do
      echo "$line"
    done <<< "$(grep "\[.*\]" "$credentialFileLocation" | sed "s/[]]//g" | sed "s/[[]//g")";

    read -p "Existing source profile name (type enter to use default profile): " profile
  fi
else
  echo "DETECTED : Profile with AWS_PROFILE and it will be use : $AWS_PROFILE"
  profile="$AWS_PROFILE"
fi

if [ -z $pname ]; then pname="mfa-$RANDOM"; fi
if [ -z $profile ]; then 
  #Check if AWS_DEFAULT_PROFILE is set
  if ! [ -z $AWS_DEFAULT_PROFILE ]; then
    echo "DETECTED : Profile with AWS_DEFAULT_PROFILE and it will be use : $AWS_DEFAULT_PROFILE"
    profile="$AWS_DEFAULT_PROFILE"
  else
    profile="default"
  fi
fi

checkProfileExist "$profile"

#Get the username and the arn mfa user
username=$(aws iam get-user --profile $profile | jq ".User.UserName" | sed 's/"//g')
if [ -z $username ]; then
  read -p "ERROR: Can not retrieve username (Probably: iam:GetUser refused). Enter it manually : " username;
fi

arnmfa=$(aws iam list-virtual-mfa-devices --profile $profile | jq ".VirtualMFADevices[].SerialNumber" | grep mfa/$username | sed 's/"//g')
if [ -z $arnmfa ]; then echo "No MFA found. You need to create one." && exit 1; fi

if [ $interactiveMode == "true" ]; then
  read -p "Enter your MFA token : " tokenMFA
fi

#Get Token
credentials=$(aws sts get-session-token --serial-number $arnmfa --token-code $tokenMFA --profile $profile)
if [ $? -ne 0 ]; then
  echo "Invalid Token."
  exit 1
fi

sak=$(echo $credentials | jq '.Credentials.SecretAccessKey' | sed 's/"//g')
ak=$(echo $credentials | jq '.Credentials.AccessKeyId' | sed 's/"//g')
sessionToken=$(echo $credentials | jq '.Credentials.SessionToken' | sed 's/"//g')

putConfigFile

#Unset var for security
unset sak ak sessionToken credentials

exit 0

