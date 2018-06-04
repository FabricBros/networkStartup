#!/usr/bin/env bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# simple batch script making it easier to cleanup and start a relatively fresh fabric env.

current_dir=$(pwd)
#echo $current_dir/test

if [ ! -e "docker-compose.yaml" ];then
  echo "docker-compose.yaml not found."
  exit 8
fi

ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION=${ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION:-}

function clean(){

  rm -rf /var/hyperledger/*

  if [ -e "/tmp/HFCSampletest.properties" ];then
    rm -f "/tmp/HFCSampletest.properties"
  fi

  lines=`docker ps -a | grep 'dev-peer' | wc -l`

  if [ "$lines" -gt 0 ]; then
    docker ps -a | grep 'dev-peer' | awk '{print $1}' | xargs docker rm -f
  fi

  lines=`docker images | grep 'dev-peer' | grep 'dev-peer' | wc -l`
  if [ "$lines" -gt 0 ]; then
    docker images | grep 'dev-peer' | awk '{print $1}' | xargs docker rmi -f
  fi

}

function up(){

  if [ "$ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION" == "1.0.0" ]; then
    docker-compose up --force-recreate ca0 ca1 peer1.org1.example.com peer1.org2.example.com ccenv
  else
#    docker-compose up --force-recreate
    docker-compose -f docker-compose.yaml -f docker-compose-couch.yaml up -d 2>&1
fi

}

function down(){
  docker-compose down;
  docker-compose -f docker-compose.yaml -f docker-compose-couch.yaml down --volumes
}

function stop (){
  docker-compose stop;
}

function start (){
  docker-compose start;
}

#todo
function createChannel(){
    CORE_PEER_LOCALMSPID=Org1MSP CORE_PEER_MSPCONFIGPATH=$current_dir/crypto/v1.1/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/ peer channel create -o 127.0.0.1:7050 -c foo -f $current_dir/crypto/v1.1/foo.tx
}


function joinChannel(){
    CORE_PEER_LOCALMSPID=Org1MSP CORE_PEER_MSPCONFIGPATH=$current_dir/crypto/v1.1/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/ peer channel join -b foo.block
#    CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=$current_dir/crypto/v1.1/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/ peer channel join -b foo.block

}
##function installCC(){
# check that env FABRICBROS_CC_PATH is set
# }
##function instantiateCC(){}


for opt in "$@"
do

    case "$opt" in
        up)
            up
            ;;
        down)
            down
            ;;
        stop)
            stop
            ;;
        start)
            start
            ;;
        clean)
            clean
            ;;
        createChannel)
            createChannel
            ;;
        joinChannel)
            joinChannel
            ;;
        restart)
            down
            clean
            up
            ;;

        *)
            echo $"Usage: $0 {up|down|start|stop|clean|restart|createChannel|joinChannel}"
            exit 1

esac
done
