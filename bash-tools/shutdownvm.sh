#!/bin/bash
if (( "$#" != "1" ))
then
  echo -n "Missing argument : ./shutdownvm.sh name"
  exit -1
fi
# Exit
curl "http://127.0.0.1:8099/remove?name=$1"
