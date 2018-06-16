# Quick Start:
Chaincode development should take place in your GOPATH

Setup ENV
```
vim ~/.bash_profile and export MHC_FABRIC_CCROOT=$GOPATH/src/\<path into your cc files>
```

Don't forget to source .bash_profile
### Setting MHC_FABRIC_CCROOT is required for script ./fabric.sh up to work

    ./fabric.sh up -- starts up basic network, on another terminal, check your network using 'docker ps -a' command

`Note, when fabric.sh up, channel foo gets created and peer joins the channel`

```
    ./fabric.sh down -- take network down
```

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
    
### Sample order to execute

`Terminal 1`

    ./fabric.sh up
    
`Terminal 2`

    ./fabric.sh startCC ccname v1

`Terminal 1`

    ./fabric runCC ccname v1

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
