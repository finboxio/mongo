#!/bin/bash

NO_COLOR="\e[0m"
GREEN="\e[32m"
RED="\e[31m"
GRAY="\e[37m"

while ! mongo localhost:27017 --eval 'printjson({ "hi": "bye" })' &>/dev/null; do
  echo -e "$GRAY   Waiting for mongo to come online...$NO_COLOR"
  sleep 2
done

expected="mongo:27017 2 false mongo_arbiter:27017 1 true mongo_secondary:27017 1 false"

cmd='rs.config().members.forEach(function (m) { print(m.host + " " + m.priority + " " + m.arbiterOnly) })'
members=$(mongo localhost:27017/rs --quiet --eval "$cmd" | sort | xargs)
while [[ "$members" != "$expected" ]]; do
  sleep 2
  members=$(mongo localhost:27017/rs --quiet --eval "$cmd" | sort | xargs)
  echo -e "$GRAY   Waiting for members to join (currently $members)...$NO_COLOR"
done

echo -e "$GREEN ✓ replicaset initialized properly $NO_COLOR"
