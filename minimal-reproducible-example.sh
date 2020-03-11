#!/bin/bash

MONGO_READ_PREFERENCE_MODES=(
    primary
    primary_preferred
    secondary
    secondary_preferred
    nearest
)


for MONGOID_READ_MODE in ${MONGO_READ_PREFERENCE_MODES[*]}; do
    echo "MONGOID_READ_MODE=$MONGOID_READ_MODE" > .env
    echo "Now testing mongo replica set operation scenarios, with forum service `cat .env`"
    echo

    echo "Destroying the pre-existing devstack"
    echo y | make destroy
    echo

    echo "Bringing up just the forum service and its dependencies:"
    make dev.up.forum no_cache=1
    echo

    echo "Mongo replica set warmup period..."
    sleep 30
    ./test-mongo-failover.sh 2> /dev/null | tee "test-mongo-failover@${MONGOID_READ_MODE}.log"
    echo

    echo
    echo
    echo
    echo
done


echo "Final cleanup:"
echo y | make destroy
rm .env
echo

echo "Logs have been saved to: `ls test-mongo-failover@*.log | xargs`"
echo

echo "DONE!"
