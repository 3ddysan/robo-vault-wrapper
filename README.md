# RoboVaultWrapper
Retrieves db passwords from vault for Robo-3t config.

## How to
1. Start Robo3T and configure your connections:
    - Connection Name must be secret vault path (e.g. secrets/mongo/credentials becomes secrets.mongo.credentials)
    - Authentication must be enabled for this connection
    - Keep username and password empty
    - exit Robo3T after
   
2. Open wrapper script and configure:
    - locations of zenity/jq/vault/robomongo
    - config folder of robo3t/robomongo (e.g. ~/.3T/robo-3t or ~/.3T/robomongo)
    - config filename (e.g. robo3t.json or robomongo.json)
3. Execute the wrapper script with your vault url as the first argument. (e.g. ./robomongo-vault.sh "http://127.0.0.1:8200")

## Requirements
OS:
- linux

dependencies:
- Robo3T (Robomongo) (https://robomongo.org/)
- jq (https://stedolan.github.io/jq/download/) 
- vault (https://www.vaultproject.io/downloads.html)

optional ui:
- zenity (win: https://github.com/kvaps/zenity-windows/releases)
