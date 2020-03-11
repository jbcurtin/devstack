#!/bin/bash

HEALTH_CHECK_URL=http://localhost:44567/heartbeat
HEALTH_CHECK_SLEEP_TIME=0.1

MONGO_DOCKER_CONTAINER=edx.devstack.mongo
MONGO_REPLICA_SET_URL="mongodb://edx.devstack.mongo:27001,edx.devstack.mongo:27002,edx.devstack.mongo:27003/?replicaSet=rs0"
MONGO_SECONDARY_PORT=27003
MONGO_TEMPORARY_FAILOVER_TIME=11


function check_forum_health {
    NUM_HEALTH_CHECKS=$1
    for i in $(seq 1 $NUM_HEALTH_CHECKS); do
        echo -en "CHECK [$i/$NUM_HEALTH_CHECKS]\t"
        echo -en "`date --iso-8601=ns`\t"
        echo -en "`docker exec $MONGO_DOCKER_CONTAINER mongo --port $MONGO_SECONDARY_PORT --quiet --eval \"rs.status().members.map(function(m) {return m.name + ' ' + m.stateStr;}).join('\t')\"`\t"
        curl $HEALTH_CHECK_URL
        echo

        sleep $HEALTH_CHECK_SLEEP_TIME
    done
}

function mongo_temporary_failover {
    docker exec $MONGO_DOCKER_CONTAINER mongo $MONGO_REPLICA_SET_URL --quiet --eval "rs.stepDown($MONGO_TEMPORARY_FAILOVER_TIME)"
}

function mongo_primary_shutdown {
    MONGO_PRIMARY_PORT=`docker exec $MONGO_DOCKER_CONTAINER mongo --port $MONGO_SECONDARY_PORT --quiet --eval "rs.isMaster().primary.split(':')[1]"`
    docker exec $MONGO_DOCKER_CONTAINER mongo --port $MONGO_PRIMARY_PORT --quiet --eval "db.adminCommand({shutdown : 1, force : true})"
}


echo "Normal mongo replica set state:"
check_forum_health 15
echo

echo "During a temporary mongo replica set failover:"
mongo_temporary_failover
check_forum_health 60
echo

echo "After a forced mongo primary shutdown:"
mongo_primary_shutdown
check_forum_health 30
