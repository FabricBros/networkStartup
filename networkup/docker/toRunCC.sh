#!/usr/bin/env bash

#inside cc directory
# go build && CORE_CHAINCODE_LOGLEVEL=debug CORE_PEER_ADDRESS=127.0.0.1:7052 CORE_CHAINCODE_ID_NAME=name:version ./pathToCCBinary

CORE_PEER_LOCALMSPID=Org1MSP CORE_PEER_MSPCONFIGPATH=/Users/huytran/MyCoolProjects/blockchain/coolnetwork/networkup/docker/crypto/v1.1/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/ peer channel create -o 127.0.0.1:7050 -c foo -f /Users/huytran/MyCoolProjects/blockchain/coolnetwork/networkup/docker/crypto/v1.1/foo.tx

CORE_PEER_LOCALMSPID=Org1MSP CORE_PEER_MSPCONFIGPATH=/Users/huytran/MyCoolProjects/blockchain/coolnetwork/networkup/docker/crypto/v1.1/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/ peer channel join -b foo.block

CORE_PEER_LOCALMSPID=Org1MSP CORE_PEER_MSPCONFIGPATH=/Users/huytran/MyCoolProjects/blockchain/coolnetwork/networkup/docker/crypto/v1.1/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/ peer chaincode install -l golang -n nameOfCC v 1.0 -p /absolute/path/of/cc

CORE_PEER_LOCALMSPID=Org1MSP CORE_PEER_MSPCONFIGPATH=/Users/huytran/MyCoolProjects/blockchain/coolnetwork/networkup/docker/crypto/v1.1/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/ peer chaincode instantiate -l golang -n nameOfCC -v 1.0 -C foo -c '{"args":["",""]}' -o localhost:7050