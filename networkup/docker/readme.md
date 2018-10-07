# Quick Start:
Chaincode development should take place in your GOPATH

Setup ENV
HLBC = path to fabric binaries, make sure its correct version 1.1
PORT = port for java rest app for public exposure
BC_EXPLORER_PORT = port for bc explorer

vim ~/.bash_profile and export MHC_FABRIC_CCROOT=$GOPATH/src/\<path into your cc files>


Don't forget to source .bash_profile
### Setting MHC_FABRIC_CCROOT is required for script ./fabric.sh up to work

    ./fabric.sh up -- starts up basic network, on another terminal, check your network using 'docker ps -a' command

`Note, when fabric.sh up, channel foo gets created and peer joins the channel`


    ./fabric.sh down -- take network down


### To run chaincode in devmode

```
./fabric.sh startCC arg1 arg2
    
    arg1 = CC_NAME
    
    arg2 = CC_VER
```

arguments are optional

### To Install and instantiate chaincode:

(after ./fabric.sh up)

    ./fabric.sh runCC CC_NAME CC_VER
    (optional but args must match what was used for startCC)
    
### Sample order to execute for dev mode(ensure base/peer-base.yaml command has dev mode enabled)

`Terminal 1`

    ./fabric.sh up
    
`Terminal 2`

    ./fabric.sh startCC ccname v1

`Terminal 1`

    ./fabric.sh runCC ccname v1
    
### Sample order to execute for non-dev mode(ensure base/peer-base.yaml command does not have dev mode enabled)

`Terminal 1`

    ./fabric.sh up

`Terminal 1`

    ./fabric.sh runCC ccname v1

#To Modify and add peers and orgs to network:
Currently, tha yaml is setup for 2 orgs (Org1MSP and Org2MSP), and 2 peers and a fabric-ca each with 1 solo orderer.

Modify docker-compose.yaml and docker-compose-couch.yaml by commenting the services you want running or not.


For example:

Inside of docker-compose.yaml

    ##################################################################
    ##################################################################
      peer0.org1.example.com:
        container_name: peer0.org1.example.com
        extends:
          file:  base/docker-compose-base.yaml
          service: peer0.org1.example.com
        networks:
          - fabricbros
        depends_on:
              - orderer.example.com
    ##################################################################
    ##################################################################
    
and inside docker-compose-couch.yaml

      couchdb0:
        container_name: couchdb0
        image: hyperledger/fabric-couchdb
        # Populate the COUCHDB_USER and COUCHDB_PASSWORD to set an admin user and password
        # for CouchDB.  This will prevent CouchDB from operating in an "Admin Party" mode.
        environment:
          - COUCHDB_USER=
          - COUCHDB_PASSWORD=
        # Comment/Uncomment the port mapping if you want to hide/expose the CouchDB service,
        # for example map it to utilize Fauxton User Interface in dev environments.
        ports:
          - "5984:5984"
        networks:
          - fabricbros
    
      peer0.org1.example.com:
        environment:
          - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
          - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0:5984
          # The CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME and CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD
          # provide the credentials for ledger to connect to CouchDB.  The username and password must
          # match the username and password set for the associated CouchDB.
          - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=
          - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=
        depends_on:
          - couchdb0
          
To turn off peer0.org1.example.com, comment out these 2 block of code



## Invoke

```
$ ./fabric.sh invoke mycc4 v1  '{"Args":["initMarble","marble1","red","100","username"]}'

Init cc with args: {"Args":["initMarble","marble2","red","username","100"]}
2018-06-16 14:51:40.684 UTC [chaincodeCmd] InitCmdFactory -> INFO 001 Get chain(foo) orderer endpoint: orderer.example.com:7050
2018-06-16 14:51:40.686 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default escc
2018-06-16 14:51:40.686 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default vscc
2018-06-16 14:51:40.710 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 004 Chaincode invoke successful. result: status:200
2018-06-16 14:51:40.710 UTC [main] main -> INFO 005 Exiting.....

$ ./fabric.sh invoke ccname2 v1  '{"Args":["queryMarblesByOwner","username"]}'
Init cc with args: {"Args":["queryMarblesByOwner","username"]}
2018-06-16 14:53:35.052 UTC [chaincodeCmd] InitCmdFactory -> INFO 001 Get chain(foo) orderer endpoint: orderer.example.com:7050
2018-06-16 14:53:35.054 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default escc
2018-06-16 14:53:35.054 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default vscc
2018-06-16 14:53:35.203 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 004 Chaincode invoke successful. result: status:200 payload:"[{\"Key\":\"marble3\", \"Record\":{\"color\":\"red\",\"docType\":\"marble\",\"name\":\"marble3\",\"owner\":\"username\",\"size\":100}}]"
2018-06-16 14:53:35.204 UTC [main] main -> INFO 005 Exiting.....

```