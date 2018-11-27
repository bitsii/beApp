#!/bin/bash

# bkup args action password gskey gssecret fullbkuptimeD gspathwbucket removebkuptimeD srcpath
# res  args action password gskey gssecret respath gspathwbucket pathtores

export PASSPHRASE="$2"
export GS_ACCESS_KEY_ID="$3"
export GS_SECRET_ACCESS_KEY="$4"

if [ "$1" == "echo" ]; then

  echo " act $1 bpass $2 gskey $3 gssecret $4 fullbkd $5 gspathwbuc $6 rmbkupd $7 srcpath $8 "

fi

if [ "$1" == "backup" ]; then

  duplicity --full-if-older-than $5 $8 gs://$6
  duplicity remove-older-than $7 --force gs://$6

fi

if [ "$1" == "restore" ]; then

  duplicity --file-to-restore $7 gs://$6 $5

fi
