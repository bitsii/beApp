#!/bin/bash

echo "Create an initial administrative account"
echo "you can rerun ./apprun/App/IUHub/createAdminAccount.sh any time to create an additional admin account or change the password for your initial account if you forget it"
echo -n Username: 
read createUsername
echo
echo -n Password, will not be shown on screen: 
read -s createPassword
echo
echo "Initializing the app db, this can take some time."
./apprun/App/IUHub/iuhcmd.sh cmd createAccount $createUsername $createPassword admin
