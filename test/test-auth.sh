#!/bin/bash

NO_COLOR="\e[0m"
GREEN="\e[32m"
RED="\e[31m"
GRAY="\e[37m"

while ! mongo localhost:27017 --eval 'printjson({ "hi": "bye" })' &>/dev/null; do
  echo -e "$GRAY   Waiting for mongo to come online...$NO_COLOR"
  sleep 2
done

mongo localhost:27017/auth --eval 'db.getCollectionNames()' | grep "not authorized" &> /dev/null
status=$?
if [[ "$status" == "0" ]]; then
  echo -e "$GREEN ✓ unauthenticated operations blocked $NO_COLOR"
else
  echo -e "$RED ✘ unauthenticated operations were permitted $NO_COLOR"
  exit 1
fi

mongo localhost:27017/auth -u auth -p auth --eval 'db.getCollectionNames()' &> /dev/null
status=$?
if [[ "$status" == "0" ]]; then
  echo -e "$GREEN ✓ authenticated operations allowed $NO_COLOR"
else
  echo -e "$RED ✘ authenticated operations were not permitted $NO_COLOR"
  exit 1
fi
