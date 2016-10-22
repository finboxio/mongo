#!/bin/bash

NO_COLOR="\e[0m"
GREEN="\e[32m"
RED="\e[31m"
GRAY="\e[37m"

while ! mongo localhost:27017 --eval 'printjson({ "hi": "bye" })' &>/dev/null; do
  echo -e "$GRAY   Waiting for mongo to come online...$NO_COLOR"
  sleep 2
done

expected=$(echo "Kelley
Kevin
Casey
JP
Maggie
Dominic" | sort)

names=$(mongo \
  localhost:27017/preload \
  --eval 'db.siblings.find({}).toArray().forEach(function(doc) { print(doc.name) })' \
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
  localhost:27017/preload \
  --eval 'db["siblings-gz"].find({}).toArray().forEach(function(doc) { print(doc.name) })' \
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
