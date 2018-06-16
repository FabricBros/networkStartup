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


    if [[ -z "${MHC_FABRIC_CCROOT}" ]] ; then
        echo "Missing MHC_FABRIC_CCROOT ENV! Set the ENV to the chaincode files path"
        exit 1
    fi

    if [ "$ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION" == "1.0.0" ]; then
        docker-compose up --force-recreate ca0 ca1 peer1.org1.example.com peer1.org2.example.com ccenv
    else
#    docker-compose up --force-recreate
        docker-compose -f docker-compose.yaml -f docker-compose-couch.yaml up --force-recreate -d 2>&1
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


function installCC(){

    CC_NAME=$1
    CC_VER=$2

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi

    echo "Install cc using ${CC_NAME}:${CC_VER}"

    docker exec cli peer chaincode install -p chaincode -n ${CC_NAME} -v ${CC_VER}

}

function instantiateCC(){
    CC_NAME=$1
    CC_VER=$2

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi

    echo "Instantiating cc with args: ${CC_ARGS}"

    docker exec cli peer chaincode instantiate -n ${CC_NAME} -v ${CC_VER} -c '{"Args":["no","need","for","init"]}' -C foo
}

function startCC(){

    CC_NAME=$1
    CC_VER=$2
    if [[ -z "${MHC_FABRIC_CCROOT}" ]] ; then
        echo "Missing MHC_FABRIC_CCROOT ENV! Set the ENV to the chaincode files path"
    fi

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi


    echo "Using CC_NAME=${CC_NAME} and CC_VER=${CC_VER}"
    cd ${MHC_FABRIC_CCROOT} && go clean && go build -o ccgo && CORE_CHAINCODE_LOGLEVEL=debug CORE_PEER_ADDRESS=127.0.0.1:7052 CORE_CHAINCODE_ID_NAME=${CC_NAME}:${CC_VER} ./ccgo
    exit 0
}

function installAndInstantiate(){


    installCC $1 $2

    instantiateCC $1 $2

    exit 0
}


function testThis(){
    docker exec -it cli bash
}



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
        runCC)
            installAndInstantiate $2 $3
            ;;
        instantiateCC)
            instantiateCC $2 $3
            ;;
        startCC)
            startCC $2 $3
            ;;
        installCC)
            installCC $2 $3
            ;;
        test)
            testThis $2
            ;;
        restart)
            down
            clean
            up
            ;;

        *)
            echo $"Usage: $0 {up | down | start | stop | clean | restart | createChannel | joinChannel | startCC CC_NAME CC_VER (arg1 and arg2 optional) | installCC CC_NAME CC_VER (arg1 and arg2 optional)}"
            exit 1

esac
done
