#! /bin/bash

export PREFIX="geba"
export SUFFIX="dev"
export RG_NAME=$PREFIX-$SUFFIX
export RG_LOCATION="westeurope"
export BICEP_FILE="main.bicep"
export PARAMS="@parameters.json"
export SSH_KEY="$(cat ~/.ssh/id_rsa.pub)" \
# Must search for the 'ACRPull' role to get GUID - Bicep/ARM Templates does not have the ability to dynamically lookup permission role names and UUIDs
export ACR_ROLE=$(az role definition list --name 'AcrPull' | jq -r .[].id)

# Login to your Azure account
# az login

# Create the Resource Group to deploy the Webinar Environment
az group create --name $RG_NAME --location $RG_LOCATION

# Deploy
az deployment group create \
  --name deployaks \
  --resource-group $RG_NAME \
  --template-file $BICEP_FILE \
  --parameters $PARAMS \
  --parameters prefix=$PREFIX \
  --parameters suffix=$SUFFIX \
  --parameters adminPublicKey="$SSH_KEY" \
  --parameters acrRole=$ACR_ROLE \
  --mode Incremental