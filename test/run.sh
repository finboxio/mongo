#!/bin/bash
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

dc="docker-compose -p mongo-conf-test -f $SCRIPTPATH/docker-compose.yml"

echo 'Testing preload'
$dc -f $SCRIPTPATH/docker-compose.preload.yml up --build -d &>/dev/null
$dc -f $SCRIPTPATH/docker-compose.preload.yml exec mongo /opt/mongo-conf/test/test-preload.sh; status=$?
if [[ "$status" != "0" ]]; then exit $status; fi

echo 'Testing no duplicate preload on subsequent startups'
$dc -f $SCRIPTPATH/docker-compose.preload.yml restart mongo
$dc -f $SCRIPTPATH/docker-compose.preload.yml exec mongo /opt/mongo-conf/test/test-preload.sh; status=$?
$dc -f $SCRIPTPATH/docker-compose.preload.yml down -v &>/dev/null
if [[ "$status" != "0" ]]; then exit $status; fi

echo 'Testing auth'
$dc -f $SCRIPTPATH/docker-compose.auth.yml up --build -d &>/dev/null
$dc -f $SCRIPTPATH/docker-compose.auth.yml exec mongo /opt/mongo-conf/test/test-auth.sh; status=$?
$dc -f $SCRIPTPATH/docker-compose.auth.yml down -v &>/dev/null
if [[ "$status" != "0" ]]; then exit $status; fi

echo 'Testing readonly'
$dc -f $SCRIPTPATH/docker-compose.readonly.yml up --build -d &>/dev/null
$dc -f $SCRIPTPATH/docker-compose.readonly.yml exec mongo /opt/mongo-conf/test/test-readonly.sh; status=$?
$dc -f $SCRIPTPATH/docker-compose.readonly.yml down -v &>/dev/null
if [[ "$status" != "0" ]]; then exit $status; fi

echo 'Testing replica set'
$dc -f $SCRIPTPATH/docker-compose.rs.yml up --build -d &>/dev/null
$dc -f $SCRIPTPATH/docker-compose.rs.yml exec mongo /opt/mongo-conf/test/test-replset.sh; status=$?
if [[ "$status" != "0" ]]; then exit $status; fi

echo 'Testing replicaset reinitialization on restart'
$dc -f $SCRIPTPATH/docker-compose.rs.yml restart
$dc -f $SCRIPTPATH/docker-compose.rs.yml exec mongo /opt/mongo-conf/test/test-replset.sh; status=$?
$dc -f $SCRIPTPATH/docker-compose.rs.yml down -v &>/dev/null
if [[ "$status" != "0" ]]; then exit $status; fi

echo 'Testing replica set auth'
$dc -f $SCRIPTPATH/docker-compose.rs-auth.yml up --build -d &>/dev/null
$dc -f $SCRIPTPATH/docker-compose.rs-auth.yml exec mongo /opt/mongo-conf/test/test-replset-auth.sh; status=$?
if [[ "$status" == "0" ]]; then
  echo 'Testing secondary'
  sleep 10 # wait a bit for user replication
  $dc -f $SCRIPTPATH/docker-compose.rs-auth.yml exec mongo_secondary /opt/mongo-conf/test/test-replset-auth.sh; status=$?
fi
$dc -f $SCRIPTPATH/docker-compose.rs-auth.yml down -v &>/dev/null
if [[ "$status" != "0" ]]; then exit $status; fi

echo 'Testing readonly replica set preload'
$dc -f $SCRIPTPATH/docker-compose.rs-preload.yml up --build -d &>/dev/null
$dc -f $SCRIPTPATH/docker-compose.rs-preload.yml exec mongo /opt/mongo-conf/test/test-replset-preload.sh; status=$?
$dc -f $SCRIPTPATH/docker-compose.rs-preload.yml down -v &>/dev/null
if [[ "$status" != "0" ]]; then exit $status; fi
