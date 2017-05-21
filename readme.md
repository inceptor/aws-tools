# Tools for aws utility

## aws-getTokenMFA.sh
Retreive a token MFA and put it on your credentials file
./aws-getTokenMFA.sh MFAtoken [profileName] [ProfileFetchCredentials] 
- [X] CAN : Be use with arg (no interactive mode)
- [X] CAN : Check if a session profile is expired
- [X] CAN : If the you want, you can delete 1 or multiple session profiles if expired
- [X] List profiles if AWS_PROFILE is not specify
- [X] Select AWS_DEFAULT_PROFILE if the user want to use default profile
- [X] Retreive the token session with the profile selected if the MFA token is valid
- [X] Update your credentials and config with a new profile and the token session

## aws-listProfiles.sh
List all profiles
- [X] List all profiles

## aws-cleanProfiles.sh
Clean all profile token (With token session or not)
- [X] List all profiles expirated
- [ ] Check if the profiles has a inactive key
- [ ] Check if there is a timeout with the request
- [X] CAN : Delete all profiles expirated
