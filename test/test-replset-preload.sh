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
members=$(mongo localhost:27017/admin -u auth -p auth --quiet --eval "$cmd" | sort | xargs)
while [[ "$members" != "$expected" ]]; do
  sleep 2
  members=$(mongo localhost:27017/admin -u auth -p auth --quiet --eval "$cmd" | sort | xargs)
  echo -e "$GRAY   Waiting for members to join (currently $members)...$NO_COLOR"
done

echo -e "$GREEN ✓ replicaset initialized properly $NO_COLOR"

expected=$(echo "Kelley
Kevin
Casey
JP
Maggie
Dominic" | sort)

names=$(mongo \
  localhost:27017/preload -u auth -p auth \
  --eval 'rs.slaveOk(); db.siblings.find({}).toArray().forEach(function(doc) { print(doc.name) })' \
  | tail -n +3 \
  | sort)

if [[ "$names" == "$expected" ]]; then
  echo -e "$GREEN ✓ preload .json files are seeded once $NO_COLOR"
else
  echo -e "$RED ✘ preload .json files failed to seed $NO_COLOR"
  echo "  expected: $expected"
  echo "  got: $names"
  exit 1
fi

names=$(mongo \
  localhost:27017/preload -u auth -p auth \
  --eval 'rs.slaveOk(); db["siblings-gz"].find({}).toArray().forEach(function(doc) { print(doc.name) })' \
  | tail -n +3 \
  | sort)

if [[ "$names" == "$expected" ]]; then
  echo -e "$GREEN ✓ preload .json.gz files are seeded once $NO_COLOR"
else
  echo -e "$RED ✘ preload .json.gz files failed to seed $NO_COLOR"
  echo "  expected: $expected"
  echo "  got: $names"
  exit 1
fi

mongo localhost:27017/preload -u auth -p auth --quiet --eval 'db.siblings.insert({ name: "Brian" })' | grep "not authorized" &>/dev/null
status=$?

if [[ "$status" == "0" ]]; then
  echo -e "$GREEN ✓ user cannot modify the database $NO_COLOR"
else
  echo -e "$RED ✘ user can still modify the database $NO_COLOR"
  exit 1
fi

