#!/bin/sh

rg="rg-networking-scus-002"
storage="stdeployarm"
storageResourceGroup="rg-workloadmanagement-scus-001"
container="deploy"

key=$(az storage account keys list --account-name $storage --query [0].value -o tsv)
az storage blob upload --account-name $storage --account-key $key --container-name $container -f forwarderSetup.sh -n forwarderSetup.sh


end=`date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ'`
sasQueryString=$(az storage blob generate-sas --account-name $storage --account-key $key --container-name $container -n forwarderSetup.sh --permissions r --expiry $end --https-only -o tsv)

blobSasURL="https://$storage.blob.core.windows.net/$container/forwarderSetup.sh?$sasQueryString"

az deployment group create -g $rg -n deploydnsforwarder -f azuredeploy.json  -p @azuredeploy.parameters.json -p vmName=dnsproxy1 scriptURL=$blobSasURL
az deployment group create -g $rg -n deploydnsforwarder -f azuredeploy.json  -p @azuredeploy.parameters.json -p vmName=dnsproxy2 scriptURL=$blobSasURL
