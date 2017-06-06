# Tools utility for aws

## aws-getTokenMFA.sh
Retrieve a token MFA and put it on your credentials file
### Installation
Package :
- AWS cli
- jq
- PCRE (for deleting profile expired)

./aws-getTokenMFA.sh MFAtoken [profileName] [ProfileFetchCredentials] 
- [X] Check env var if profile exist (anti crash aws cli)
- [X] CAN : Be use with arg (no interactive mode)
- [X] CAN : Check if a session profile is expired
- [X] CAN : If the you want, you can delete 1 or multiple session profiles if expired
- [X] List profiles if AWS_PROFILE is not specify
- [X] Select AWS_DEFAULT_PROFILE if the user want to use default profile
- [X] Retrieve the token session with the profile selected if the MFA token is valid
- [X] Update your credentials and config with a new profile and the token session

## aws-listProfiles.sh
List all profiles

### Installation
Package :
- AWS cli

./aws-listProfiles.sh
- [X] List all profiles

## aws-cleanProfiles.sh
Clean all profiles token (With token session or not)
### Installation
Package :
- AWS cli
- jq
- PCRE 

./aws-cleanProfiles.sh <profileNameToDelete>
- [X] Check env var if profile exist (anti crash aws cli)
- [X] CAN : Be use with arg (no interactive mode)
- [X] List all profiles expirated
- [ ] Check if the profiles has a inactive key
- [ ] Check if there is a timeout with the request
- [X] CAN : Delete all profiles expirated
