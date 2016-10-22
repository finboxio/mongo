#! /bin/bash

# Bootstraps the mongo server. Sets up volumes
# and configures mongod options

set -e

export PATH="$PATH:/opt/mongo-conf/bin"

MONGO_PORT=${MONGO_PORT:-27017}
MONGO_DIR=${MONGO_DIR:-/mongo}
MONGO_STORAGE_ENGINE=${MONGO_STORAGE_ENGINE:-wiredTiger}

MONGO_USER=${MONGO_USER}
MONGO_PASSWORD=${MONGO_PASSWORD}

MONGO_REPLSET=${MONGO_REPLSET}
MONGO_ROLE=${MONGO_ROLE}
MONGO_KEYFILE=${MONGO_KEYFILE}

if [[ "${DEBUG}" == "" ]]; then
  QUIET="--quiet"
fi

if [[ "$EBS_VOLUME_NAME" != "" ]]; then
  ebs-volume-setup
fi

if [[ ! -e ${MONGO_DIR}/data ]]; then
  mkdir -p ${MONGO_DIR}/data &> /dev/null

  chown -R mongodb:mongodb ${MONGO_DIR}

  # Setup shared keyfile
  while [[ "${MONGO_REPLSET}" != "" && "${MONGO_KEYFILE}" != "" && ! -e /etc/mongo-conf/mongo.key ]]; do
    cat /etc/mongo-conf/mongo.key || true
    cp ${MONGO_KEYFILE} /etc/mongo-conf/mongo.key || true

    if [[ "$MONGO_ROLE" == "primary" && ! -e /etc/mongo-conf/mongo.key ]]; then
      openssl rand -base64 741 > /etc/mongo-conf/mongo.key
      cp /etc/mongo-conf/mongo.key ${MONGO_KEYFILE}
    fi

    chown -R mongodb:mongodb /etc/mongo-conf/mongo.key || true
    chmod 600 /etc/mongo-conf/mongo.key || true
  done

  # Start init process to setup default accounts
  mongo-init
  mongo-init-cleanup &
fi

if [[ "${MONGO_USER}" != "" && "${MONGO_PASSWORD}" != "" ]]; then
  if [[ "${MONGO_REPLSET}" != "" ]]; then
    AUTH="--auth --keyFile /etc/mongo-conf/mongo.key"
  else
    AUTH="--auth"
  fi
fi

if [[ "$MONGO_REPLSET" != "" ]]; then
  ARBITER_OPTS=
  if [[ "$MONGO_ROLE" == "arbiter" ]]; then
    ARBITER_OPTS="--nojournal --smallfiles"
  fi
  exec gosu mongodb mongod \
    --storageEngine ${MONGO_STORAGE_ENGINE} \
    --dbpath ${MONGO_DIR}/data \
    --port ${MONGO_PORT} \
    --replSet ${MONGO_REPLSET} \
    ${AUTH} \
    ${QUIET} \
    ${ARBITER_OPTS}
else
  exec gosu mongodb mongod \
    --storageEngine ${MONGO_STORAGE_ENGINE} \
    --dbpath ${MONGO_DIR}/data \
    --port ${MONGO_PORT} \
    ${AUTH} \
    ${QUIET}
fi
