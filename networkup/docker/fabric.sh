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

source .env
ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION=${ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION:-}
CHANNEL=${CHANNEL}

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

function up1(){

    if [[ -z "${MHC_FABRIC_CCROOT}" ]] ; then
        echo "Missing MHC_FABRIC_CCROOT ENV! Set the ENV to the chaincode files path"
        exit 1
    fi

    if [ "$ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION" == "1.0.0" ]; then
        docker-compose up --force-recreate ca0 ca1 peer1.org1.example.com peer1.org2.example.com ccenv
    else
#    docker-compose up --force-recreate
        docker-compose -f docker-compose-single.yaml -f docker-compose-single-couch.yaml up --force-recreate -d 2>&1
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

    docker exec cli peer chaincode instantiate -n ${CC_NAME} -v ${CC_VER} -c '{"Args":["key","value"]}' -C ${CHANNEL}
}

function invoke(){
    CC_ARGS=$1
    CC_NAME=$2
    CC_VER=$3

    if [[ -z "${CC_ARGS}" ]] ; then
        echo "Missing argument for CC_ARGS setting default to" '{"Args":["no","need","for","init"]}'
        CC_ARGS='{"Args":["no","need","for","init"]}'
    fi

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi


    echo "Invoke cc with args: ${CC_ARGS}"

    docker exec cli peer chaincode invoke -n ${CC_NAME} -v ${CC_VER} -c ${CC_ARGS} -C ${CHANNEL}
    # peer chaincode invoke -n mycc -c '{"Args":["invoke","a","b","10"]}' -o 127.0.0.1:7050 -C ch1
}


function generate(){

cd crypto/v1.1/
#https://github.com/jcs47/hyperledger-bftsmart/issues/8
#Wait a second, are you using the same channel ID to create both the
# genesisblock and also the channel creation ID? You can't do that.
# When creating the genesis block, you supply the ID for the system
# channel, while when creating the channel transaction, you are
# creating a new channel for a another network.

configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./orderer.block -channelID mysyschannel
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel.tx -channelID foo
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID foo -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org2MSPanchors.tx -channelID foo -asOrg Org2MSP

}

function generate1(){
#
#    cd crypto/${FAB_CONFIG_GEN_VERS}/
#    rm -r ./crypto-config channel.tx orderer.block Org1MSPanchors.tx
#
#    #https://github.com/jcs47/hyperledger-bftsmart/issues/8
#    #Wait a second, are you using the same channel ID to create both the
#    # genesisblock and also the channel creation ID? You can't do that.
#    # When creating the genesis block, you supply the ID for the system
#    # channel, while when creating the channel transaction, you are
#    # creating a new channel for a another network.
#    cryptogen generate --config=./crypto-config.yaml
#    configtxgen -profile OrgOrdererGenesis -outputBlock ./orderer.block -channelID mysyschannel
#    configtxgen -profile OrgChannel -outputCreateChannelTx ./channel.tx -channelID ${CHANNEL}
#    configtxgen -profile OrgChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID ${CHANNEL} -asOrg Org1MSP
#    cd ../../
    sleep 1
}


function query(){
    CC_ARGS=$1
    CC_NAME=$2
    CC_VER=$3

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi
    if [[ -z "${CC_ARGS}" ]] ; then
        echo "Missing argument for CC_ARGS setting default to" '{"Args":["no","need","for","init"]}'
        CC_ARGS='{"Args":["no","need","for","init"]}'
    fi

    echo "Init cc with args: ${CC_ARGS}"

    docker exec cli peer chaincode query -n ${CC_NAME} -v ${CC_VER} -c ${CC_ARGS} -C ${CHANNEL}
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
    cd ${MHC_FABRIC_CCROOT} && go clean && go build -o ccgo && CORE_CHAINCODE_LOGGING_SHIM=debug CORE_PEER_ADDRESS=127.0.0.1:7052 CORE_CHAINCODE_ID_NAME=${CC_NAME}:${CC_VER} ./ccgo
#    exit 0
}



function installAndInstantiate(){


    installCC $1 $2

    instantiateCC $1 $2

#    exit 0
}


function testThis(){
    docker exec -it cli bash
}


function e2e(){
    export MHC_FABRIC_CCROOT=`pwd`/chaincode/sacc
    #generate1
    startCC
#    up1
#    sleep 60 ## Wait for fabric network to startup
#    sleep 20 ## Wait for chaincode to build and run
#    installAndInstantiate
#    sleep 20
#    invoke  '{"Args":["set","key","value"]}'
#    query  '{"Args":["get","key"]}'
}


echo "CMD: $1"

case "$1" in
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
        invoke)
            invoke $2 $3 $4
            ;;
        query)
            query $2 $3 $4
            ;;
        generate)
            generate
            ;;
        generate1)
            generate1
            ;;
        up1)
            up1
            ;;
        e2e)
            e2e
            ;;
        *)
            echo $"Usage: $0 {up | down | start | stop | clean | restart | createChannel | joinChannel | startCC CC_NAME CC_VER (arg1 and arg2 optional) | installCC CC_NAME CC_VER (arg1 and arg2 optional) | invoke CC_ARGS CC_NAME CC_VER | query CC_ARGS CC_NAME CC_VER }"
            exit 1
            ;;
esac
