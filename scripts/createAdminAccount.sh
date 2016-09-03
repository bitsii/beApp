#!/bin/bash

echo "Create an initial administrative account"
echo -n Username: 
read -s createUsername
echo
echo -n Password: 
read -s createPassword
echo
./apprun/App/IUHub/iuhcmd.sh cmd createAccount $createUsername $createPassword admin
