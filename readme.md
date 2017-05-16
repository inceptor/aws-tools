# Tools for aws utility

* aws-getTokenMFA.sh : Retreive a token MFA and put it on your credentials file 
- [X] CAN : Check if a session profile is expired
- [X] CAN : If the you want, you can delete 1 or multiple session profiles if expired
- [X] List profiles
- [X] Retreive the token session with the profile selected
- [X] Update your credentials and config with a new profile and the token session

* aws-listProfiles.sh : List all profiles
- [X] List all profiles

* aws-cleanProfiles
- [X] List all profiles expirated (with or not token)
- [] Check if the profiles has a inactive key
- [] Check if there is a timeout with the request
- [X] CAN : Delete all profiles expirated
