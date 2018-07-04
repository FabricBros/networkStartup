#!/usr/bin/env bash

cd crypto/${FAB_CONFIG_GEN_VERS}/
rm -r ./crypto-config channel.tx orderer.block Org1MSPanchors.tx

#https://github.com/jcs47/hyperledger-bftsmart/issues/8
#Wait a second, are you using the same channel ID to create both the
# genesisblock and also the channel creation ID? You can't do that.
# When creating the genesis block, you supply the ID for the system
# channel, while when creating the channel transaction, you are
# creating a new channel for a another network.
cryptogen generate --config=./crypto-config.yaml
configtxgen -profile OrgOrdererGenesis -outputBlock ./orderer.block -channelID mysyschannel
configtxgen -profile OrgChannel -outputCreateChannelTx ./channel.tx -channelID ${CHANNEL}
configtxgen -profile OrgChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID ${CHANNEL} -asOrg Org1MSP
