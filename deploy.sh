#!/bin/sh
rg="rg-networking-scus-001"
storage="stdeployarm"
container="deploy"

#Upload the configuration script to blob storage
key=$(az storage account keys list --account-name $storage --query [0].value -o tsv)
az storage blob upload --account-name $storage --account-key $key --container-name $container -f forwarderSetup.sh -n forwarderSetup.sh

#Generate SAS URL allowing read permission to the blob for 30 minutes
end=`date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ'`
sasQueryString=$(az storage blob generate-sas --account-name $storage --account-key $key --container-name $container -n forwarderSetup.sh --permissions r --expiry $end --https-only -o tsv)

#The SAS URL is used by the custom script extension to download the script from storage
blobSasURL="https://$storage.blob.core.windows.net/$container/forwarderSetup.sh?$sasQueryString"

#Deploy first VM in availability set
vmName="dnsproxy1"
az deployment group create -g $rg -n deploydnsforwarder -f azuredeploy.json  -p @azuredeploy.parameters.json -p vmName=$vmName scriptURL=$blobSasURL

#Deploy second VM in availability set
vmName="dnsproxy2"
az deployment group create -g $rg -n deploydnsforwarder -f azuredeploy.json  -p @azuredeploy.parameters.json -p vmName=$vmName scriptURL=$blobSasURL